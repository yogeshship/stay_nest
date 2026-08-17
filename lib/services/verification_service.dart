import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_model.dart';
import '../models/verification_request_model.dart';

class VerificationService {
  VerificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('verificationRequests');

  Future<void> submitVerificationRequest() async {
    final authenticatedUser = _firebaseAuth.currentUser;
    if (authenticatedUser == null) {
      throw StateError('You must be signed in as an owner.');
    }

    final userReference =
        _firestore.collection('users').doc(authenticatedUser.uid);
    final requestReference = _requests.doc(authenticatedUser.uid);

    await _firestore.runTransaction((transaction) async {
      final userDocument = await transaction.get(userReference);
      if (!userDocument.exists) {
        throw StateError('Your StayNest owner profile could not be found.');
      }

      final profile = AppUserModel.fromFirestore(userDocument);
      if (profile.uid != authenticatedUser.uid ||
          profile.role != AppUserModel.ownerRole) {
        throw StateError(
            'Only an authenticated owner can request verification.');
      }
      if (!profile.isActive) {
        throw StateError('This owner account is inactive.');
      }
      if (profile.verificationStatus == AppUserModel.approvedVerification) {
        throw StateError('This owner account is already verified.');
      }
      if (profile.verificationStatus == AppUserModel.pendingVerification) {
        throw StateError('Your verification request is already pending.');
      }
      if (!profile.canRequestOwnerVerification) {
        throw StateError('This verification request cannot be submitted.');
      }

      transaction.set(requestReference, {
        'ownerId': authenticatedUser.uid,
        'status': VerificationRequestModel.pendingStatus,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
        'ownerDisplayName': profile.fullName.trim(),
        'ownerEmail': profile.email.trim(),
      });
      transaction.update(userReference, {
        'verificationStatus': AppUserModel.pendingVerification,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<VerificationRequestModel?> watchMyVerificationRequest() {
    final uid = _requireAuthenticatedUid();
    return _requests.doc(uid).snapshots().map(
          (document) => document.exists
              ? VerificationRequestModel.fromFirestore(document)
              : null,
        );
  }

  String _requireAuthenticatedUid() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in as an owner.');
    return uid;
  }
}

String friendlyVerificationError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'You do not have permission to submit this verification request.',
      'unavailable' =>
        'Verification is temporarily unavailable. Please try again.',
      _ => 'The verification request could not be submitted. Please try again.',
    };
  }
  if (error is ArgumentError || error is StateError) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Invalid argument|Bad state): '), '');
  }
  return 'The verification request could not be submitted. Please try again.';
}
