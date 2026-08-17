import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inquiry_model.dart';
import '../models/room_model.dart';

class InquiryService {
  InquiryService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _inquiries =>
      _firestore.collection('inquiries');

  Future<String> createInquiry({
    required RoomModel room,
    required String type,
    required String message,
  }) async {
    final customerId = _requireAuthenticatedUid();
    if (room.id.trim().isEmpty || room.ownerId.trim().isEmpty) {
      throw ArgumentError('This room is missing required listing details.');
    }
    if (!InquiryModel.validTypes.contains(type)) {
      throw ArgumentError('Choose a valid inquiry type.');
    }
    validateInquiryMessage(message);

    final roomDocument =
        await _firestore.collection('rooms').doc(room.id).get();
    if (!roomDocument.exists) throw StateError('This room no longer exists.');
    final currentRoom = RoomModel.fromFirestore(roomDocument);
    if (!currentRoom.isAvailable) {
      throw StateError('This room is no longer available.');
    }
    if (currentRoom.ownerId.isEmpty) {
      throw StateError('This room is missing its owner.');
    }

    final profile = await _firestore.collection('users').doc(customerId).get();
    final displayName = (profile.data()?['fullName'] as String?)?.trim();
    if (displayName == null || displayName.isEmpty) {
      throw StateError('Your customer profile is missing its display name.');
    }
    final document = _inquiries.doc();
    await document.set({
      'roomId': currentRoom.id,
      'customerId': customerId,
      'ownerId': currentRoom.ownerId,
      'type': type,
      'message': message.trim(),
      'status': InquiryModel.pendingStatus,
      'scheduledVisitAt': null,
      'hiddenByCustomer': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'roomTitle': currentRoom.title,
      'roomLocation': currentRoom.location,
      'customerDisplayName': displayName,
    });
    return document.id;
  }

  Stream<List<InquiryModel>> watchCustomerInquiries() {
    final customerId = _requireAuthenticatedUid();
    return _inquiries
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => _sorted(snapshot.docs)
            .where((inquiry) => !inquiry.hiddenByCustomer)
            .toList(growable: false));
  }

  Stream<List<InquiryModel>> watchOwnerInquiries() {
    final ownerId = _requireAuthenticatedUid();
    return _inquiries
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => _sorted(snapshot.docs));
  }

  Future<InquiryModel?> getInquiryById(String inquiryId) async {
    _validateDocumentId(inquiryId);
    final document = await _inquiries.doc(inquiryId).get();
    return document.exists ? InquiryModel.fromFirestore(document) : null;
  }

  Future<void> updateStatus({
    required String inquiryId,
    required String status,
  }) async {
    final ownerId = _requireAuthenticatedUid();
    _validateDocumentId(inquiryId);
    if (!InquiryModel.validStatuses.contains(status)) {
      throw ArgumentError('Choose a valid inquiry status.');
    }

    await _firestore.runTransaction((transaction) async {
      final reference = _inquiries.doc(inquiryId);
      final document = await transaction.get(reference);
      if (!document.exists) throw StateError('This inquiry no longer exists.');
      final inquiry = InquiryModel.fromFirestore(document);
      if (inquiry.ownerId != ownerId) {
        throw StateError('You can only update your own inquiries.');
      }
      if (!_isValidOwnerTransition(inquiry.status, status)) {
        throw StateError('That status change is not allowed.');
      }
      transaction.update(reference, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> scheduleVisit({
    required String inquiryId,
    required DateTime scheduledVisitAt,
  }) async {
    final ownerId = _requireAuthenticatedUid();
    _validateDocumentId(inquiryId);
    validateScheduledVisitAt(scheduledVisitAt);
    await _firestore.runTransaction((transaction) async {
      final reference = _inquiries.doc(inquiryId);
      final document = await transaction.get(reference);
      if (!document.exists) throw StateError('This inquiry no longer exists.');
      final inquiry = InquiryModel.fromFirestore(document);
      if (inquiry.ownerId != ownerId) {
        throw StateError('You can only schedule your own visit requests.');
      }
      if (inquiry.type != InquiryModel.visitRequestType ||
          inquiry.status != InquiryModel.acceptedStatus) {
        throw StateError('Only accepted visit requests can be scheduled.');
      }
      transaction.update(reference, {
        'scheduledVisitAt': Timestamp.fromDate(scheduledVisitAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> hideForCustomer(String inquiryId) async {
    final customerId = _requireAuthenticatedUid();
    _validateDocumentId(inquiryId);
    final reference = _inquiries.doc(inquiryId);
    final document = await reference.get();
    if (!document.exists) throw StateError('This inquiry no longer exists.');
    if (InquiryModel.fromFirestore(document).customerId != customerId) {
      throw StateError('You can only hide your own inquiries.');
    }
    await reference.update({
      'hiddenByCustomer': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  bool _isValidOwnerTransition(String from, String to) {
    return (from == InquiryModel.pendingStatus &&
            (to == InquiryModel.acceptedStatus ||
                to == InquiryModel.declinedStatus)) ||
        (from == InquiryModel.acceptedStatus &&
            to == InquiryModel.completedStatus);
  }

  List<InquiryModel> _sorted(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final inquiries = documents.map(InquiryModel.fromFirestore).toList();
    inquiries.sort((a, b) {
      final oldest = DateTime.fromMillisecondsSinceEpoch(0);
      return (b.createdAt ?? oldest).compareTo(a.createdAt ?? oldest);
    });
    return inquiries;
  }

  String _requireAuthenticatedUid() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in.');
    return uid;
  }

  void _validateDocumentId(String inquiryId) {
    if (inquiryId.trim().isEmpty ||
        inquiryId.length > 128 ||
        inquiryId.contains('/')) {
      throw ArgumentError('A valid inquiry ID is required.');
    }
  }
}

String friendlyInquiryError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'You do not have permission to perform this inquiry action.',
      'unavailable' =>
        'The inquiry service is temporarily unavailable. Please try again.',
      'not-found' => 'This inquiry or room no longer exists.',
      'aborted' =>
        'This inquiry changed while it was being updated. Please try again.',
      'failed-precondition' =>
        'This inquiry is no longer in a state that can be changed.',
      _ => 'The inquiry could not be updated. Please try again.',
    };
  }
  if (error is ArgumentError || error is StateError) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Invalid argument|Bad state): '), '');
  }
  return 'The inquiry could not be updated. Please try again.';
}

void validateInquiryMessage(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty || trimmed.length > 2000) {
    throw ArgumentError(
      'The inquiry message must be between 1 and 2000 characters.',
    );
  }
}

void validateScheduledVisitAt(DateTime scheduledVisitAt, {DateTime? now}) {
  if (!scheduledVisitAt.isAfter(now ?? DateTime.now())) {
    throw ArgumentError('Choose a visit time in the future.');
  }
}
