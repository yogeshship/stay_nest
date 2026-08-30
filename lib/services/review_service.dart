import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inquiry_model.dart';
import '../models/review_model.dart';

class ReviewEligibility {
  const ReviewEligibility({this.inquiry, required this.message});

  final InquiryModel? inquiry;
  final String message;
  bool get isEligible => inquiry != null;
}

class ReviewService {
  ReviewService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  static String reviewId(String customerId, String roomId) {
    validateReviewIdPart(customerId, 'customer ID');
    validateReviewIdPart(roomId, 'room ID');
    return '${customerId}_$roomId';
  }

  Stream<List<ReviewModel>> watchRoomReviews(String roomId) {
    validateReviewIdPart(roomId, 'room ID');
    return _reviews.where('roomId', isEqualTo: roomId).snapshots().map(
      (snapshot) {
        final reviews = snapshot.docs.map(ReviewModel.fromFirestore).toList();
        reviews.sort((a, b) {
          final epoch = DateTime.fromMillisecondsSinceEpoch(0);
          final byDate = (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });
        return reviews;
      },
    );
  }

  Stream<ReviewModel?> watchOwnReview(String roomId) {
    final uid = _requireUid();
    return _reviews.doc(reviewId(uid, roomId)).snapshots().map(
          (document) =>
              document.exists ? ReviewModel.fromFirestore(document) : null,
        );
  }

  Future<ReviewEligibility> getReviewEligibility(String roomId) async {
    final uid = _requireUid();
    validateReviewIdPart(roomId, 'room ID');
    final room = await _firestore.collection('rooms').doc(roomId).get();
    if (!room.exists) {
      return const ReviewEligibility(message: 'This room no longer exists.');
    }
    if (room.data()?['ownerId'] == uid) {
      return const ReviewEligibility(
          message: 'You cannot review your own room.');
    }
    final snapshot = await _firestore
        .collection('inquiries')
        .where('customerId', isEqualTo: uid)
        .get();
    final selected = selectReviewEligibility(
      snapshot.docs.map(InquiryModel.fromFirestore),
      customerId: uid,
      roomId: roomId,
    );
    return ReviewEligibility(
      inquiry: selected,
      message: selected == null
          ? 'Complete a room visit before reviewing this listing.'
          : 'You completed a visit and can review this room.',
    );
  }

  Future<void> createReview({
    required String roomId,
    required int rating,
    required String reviewText,
  }) async {
    final uid = _requireUid();
    final text = validateReviewInput(rating: rating, reviewText: reviewText);
    final eligibility = await getReviewEligibility(roomId);
    if (!eligibility.isEligible) throw StateError(eligibility.message);
    final profile = await _firestore.collection('users').doc(uid).get();
    final name = profile.data()?['fullName'] as String? ?? '';
    if (name.trim().isEmpty || name.length > 120) {
      throw StateError('Your profile needs a valid display name.');
    }
    final reference = _reviews.doc(reviewId(uid, roomId));
    try {
      await reference.set({
        'roomId': roomId,
        'customerId': uid,
        'eligibilityInquiryId': eligibility.inquiry!.id,
        'rating': rating,
        'reviewText': text,
        'reviewerDisplayName': name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        try {
          if ((await reference.get()).exists) {
            throw StateError('You already reviewed this room.');
          }
        } on StateError {
          rethrow;
        } on FirebaseException {
          // Preserve the original write error when the follow-up read is denied.
        }
      }
      rethrow;
    }
  }

  Future<void> updateReview({
    required String roomId,
    required int rating,
    required String reviewText,
  }) async {
    final uid = _requireUid();
    final text = validateReviewInput(rating: rating, reviewText: reviewText);
    await _reviews.doc(reviewId(uid, roomId)).update({
      'rating': rating,
      'reviewText': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview(String roomId) {
    final uid = _requireUid();
    return _reviews.doc(reviewId(uid, roomId)).delete();
  }

  String _requireUid() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in.');
    return uid;
  }
}

InquiryModel? selectReviewEligibility(
  Iterable<InquiryModel> inquiries, {
  required String customerId,
  required String roomId,
}) {
  final eligible = inquiries
      .where((item) =>
          item.customerId == customerId &&
          item.roomId == roomId &&
          item.type == InquiryModel.visitRequestType &&
          item.status == InquiryModel.completedStatus)
      .toList();
  eligible.sort((a, b) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final updated = (b.updatedAt ?? epoch).compareTo(a.updatedAt ?? epoch);
    if (updated != 0) return updated;
    final created = (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch);
    return created != 0 ? created : a.id.compareTo(b.id);
  });
  return eligible.isEmpty ? null : eligible.first;
}

String validateReviewInput({required int rating, required String reviewText}) {
  if (rating < 1 || rating > 5) {
    throw ArgumentError('Choose a rating from 1 to 5 stars.');
  }
  final text = reviewText.trim();
  if (text.isEmpty || text.length > 1000) {
    throw ArgumentError('Review text must be between 1 and 1000 characters.');
  }
  return text;
}

void validateReviewIdPart(String value, String label) {
  if (value.trim().isEmpty || value.length > 128 || value.contains('/')) {
    throw ArgumentError('A valid $label is required.');
  }
}

String friendlyReviewError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'You do not have permission to change this review.',
      'already-exists' => 'You already reviewed this room.',
      'not-found' => 'This review no longer exists.',
      'unavailable' => 'Reviews are temporarily unavailable. Please try again.',
      _ => 'Review action failed. Please try again.',
    };
  }
  if (error is ArgumentError || error is StateError) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Invalid argument|Bad state): '), '');
  }
  return 'Review action failed. Please try again.';
}
