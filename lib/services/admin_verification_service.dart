import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_model.dart';
import '../models/verification_request_model.dart';

class AdminVerificationService {
  AdminVerificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('verificationRequests');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<List<VerificationRequestModel>> watchPendingVerificationRequests() {
    return _requests
        .where(
          'status',
          isEqualTo: VerificationRequestModel.pendingStatus,
        )
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map(VerificationRequestModel.fromFirestore)
          .toList(growable: false);
      requests.sort(_compareBySubmittedAt);
      return requests;
    });
  }

  Future<void> approveVerificationRequest(String ownerUid) {
    return _decideVerificationRequest(
      ownerUid: ownerUid,
      newStatus: VerificationRequestModel.approvedStatus,
      rejectionReason: null,
    );
  }

  Future<void> rejectVerificationRequest(
    String ownerUid,
    String reason,
  ) {
    final trimmedReason = reason.trim();
    final validationError = validateRejectionReason(trimmedReason);
    if (validationError != null) throw ArgumentError(validationError);

    return _decideVerificationRequest(
      ownerUid: ownerUid,
      newStatus: VerificationRequestModel.rejectedStatus,
      rejectionReason: trimmedReason,
    );
  }

  Future<void> _decideVerificationRequest({
    required String ownerUid,
    required String newStatus,
    required String? rejectionReason,
  }) async {
    final adminUid = _firebaseAuth.currentUser?.uid;
    if (adminUid == null) {
      throw StateError('You must be signed in as an administrator.');
    }
    if (ownerUid.trim().isEmpty) {
      throw ArgumentError('The owner account is invalid.');
    }

    final adminReference = _users.doc(adminUid);
    final requestReference = _requests.doc(ownerUid);
    final ownerReference = _users.doc(ownerUid);
    final auditReference = _firestore.collection('adminActions').doc();

    await _firestore.runTransaction((transaction) async {
      // Firestore transactions require all reads to happen before any writes.
      final adminDocument = await transaction.get(adminReference);
      final requestDocument = await transaction.get(requestReference);
      final ownerDocument = await transaction.get(ownerReference);

      if (!adminDocument.exists) {
        throw StateError('Your administrator profile could not be found.');
      }
      final admin = AppUserModel.fromFirestore(adminDocument);
      if (admin.uid != adminUid || !admin.isActiveAdmin) {
        throw StateError('Only an active administrator can review requests.');
      }

      if (!requestDocument.exists) {
        throw StateError('This verification request no longer exists.');
      }
      final request = VerificationRequestModel.fromFirestore(requestDocument);
      if (request.ownerId != ownerUid ||
          request.status != VerificationRequestModel.pendingStatus) {
        throw StateError('This verification request is no longer pending.');
      }

      if (!ownerDocument.exists) {
        throw StateError('The owner profile could not be found.');
      }
      final owner = AppUserModel.fromFirestore(ownerDocument);
      if (owner.uid != ownerUid ||
          owner.role != AppUserModel.ownerRole ||
          !owner.isActive ||
          owner.verificationStatus != AppUserModel.pendingVerification) {
        throw StateError(
          'The owner profile is not eligible for this verification decision.',
        );
      }

      transaction.update(requestReference, {
        'status': newStatus,
        'rejectionReason': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(ownerReference, {
        'verificationStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(auditReference, {
        'adminId': adminUid,
        'actionType': newStatus == VerificationRequestModel.approvedStatus
            ? 'approve_owner_verification'
            : 'reject_owner_verification',
        'targetType': 'verification',
        'targetId': ownerUid,
        'reason': rejectionReason ?? 'Owner verification approved.',
        'createdAt': FieldValue.serverTimestamp(),
        'newValue': newStatus,
      });
    });
  }

  static int _compareBySubmittedAt(
    VerificationRequestModel first,
    VerificationRequestModel second,
  ) {
    final firstDate = first.submittedAt;
    final secondDate = second.submittedAt;
    if (firstDate == null && secondDate == null) {
      return first.id.compareTo(second.id);
    }
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;
    final comparison = firstDate.compareTo(secondDate);
    return comparison == 0 ? first.id.compareTo(second.id) : comparison;
  }
}

String? validateRejectionReason(String? value) {
  final reason = value?.trim() ?? '';
  if (reason.isEmpty) return 'Please enter a rejection reason.';
  if (reason.length > 500) {
    return 'The rejection reason must be 500 characters or fewer.';
  }
  return null;
}

String friendlyAdminVerificationError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'You no longer have permission to review verification requests.',
      'not-found' => 'This verification request no longer exists.',
      'aborted' =>
        'This request changed while it was being reviewed. Please try again.',
      'unavailable' =>
        'Verification management is temporarily unavailable. Please try again.',
      _ => 'The verification decision could not be saved. Please try again.',
    };
  }
  if (error is ArgumentError || error is StateError) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Invalid argument|Bad state): '), '');
  }
  return 'The verification decision could not be saved. Please try again.';
}
