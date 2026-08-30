import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inquiry_model.dart';
import '../models/owner_analytics.dart';
import '../models/review_model.dart';
import '../models/room_model.dart';
import 'inquiry_service.dart';
import 'room_service.dart';

typedef ReviewBatchLoader = Future<List<ReviewModel>> Function(
  List<String> roomIds,
);

class OwnerAnalyticsService {
  OwnerAnalyticsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    RoomService? roomService,
    InquiryService? inquiryService,
    ReviewBatchLoader? reviewBatchLoader,
    String? authenticatedUid,
    DateTime Function()? clock,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        _roomService = roomService,
        _inquiryService = inquiryService,
        _reviewBatchLoader = reviewBatchLoader,
        _authenticatedUid = authenticatedUid,
        _clock = clock ?? DateTime.now;

  static const int reviewRoomChunkSize = 10;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _firebaseAuth;
  final RoomService? _roomService;
  final InquiryService? _inquiryService;
  final ReviewBatchLoader? _reviewBatchLoader;
  final String? _authenticatedUid;
  final DateTime Function() _clock;

  Stream<List<RoomModel>> watchOwnerRooms() =>
      (_roomService ?? RoomService()).watchOwnerRooms();

  Stream<List<InquiryModel>> watchOwnerInquiries() =>
      (_inquiryService ?? InquiryService()).watchOwnerInquiries();

  Future<OwnerReviewSnapshot> loadReviewsForOwnedRooms(
    Iterable<RoomModel> rooms,
  ) async {
    final uid = _requireUid();
    final roomIds = <String>{};
    for (final room in rooms) {
      if (room.ownerId != uid) {
        throw StateError('Analytics can only load reviews for your listings.');
      }
      if (room.id.isNotEmpty) roomIds.add(room.id);
    }
    if (roomIds.isEmpty) {
      return OwnerReviewSnapshot(reviews: const [], loadedAt: _clock());
    }

    final sortedIds = roomIds.toList()..sort();
    final reviewsById = <String, ReviewModel>{};
    for (var start = 0;
        start < sortedIds.length;
        start += reviewRoomChunkSize) {
      final end = (start + reviewRoomChunkSize).clamp(0, sortedIds.length);
      final chunk = sortedIds.sublist(start, end);
      final reviews =
          await (_reviewBatchLoader?.call(chunk) ?? _loadReviewBatch(chunk));
      for (final review in reviews) {
        if (roomIds.contains(review.roomId)) {
          reviewsById.putIfAbsent(review.id, () => review);
        }
      }
    }
    return OwnerReviewSnapshot(
      reviews: List.unmodifiable(reviewsById.values),
      loadedAt: _clock(),
    );
  }

  OwnerAnalytics calculate({
    required Iterable<RoomModel> rooms,
    required Iterable<InquiryModel> inquiries,
    required Iterable<ReviewModel> reviews,
  }) =>
      calculateOwnerAnalytics(
        rooms: rooms,
        inquiries: inquiries,
        reviews: reviews,
      );

  Future<List<ReviewModel>> _loadReviewBatch(List<String> roomIds) async {
    final snapshot = await (_firestore ?? FirebaseFirestore.instance)
        .collection('reviews')
        .where('roomId', whereIn: roomIds)
        .get();
    return snapshot.docs.map(ReviewModel.fromFirestore).toList(growable: false);
  }

  String _requireUid() {
    final uid = _authenticatedUid ??
        _firebaseAuth?.currentUser?.uid ??
        FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('An owner must be signed in.');
    }
    return uid;
  }
}

String friendlyOwnerAnalyticsError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Rating data could not be loaded.',
      'unavailable' => 'Rating data is temporarily unavailable.',
      _ => 'Rating data could not be loaded.',
    };
  }
  if (error is StateError) {
    return error.toString().replaceFirst('Bad state: ', '');
  }
  return 'Rating data could not be loaded.';
}
