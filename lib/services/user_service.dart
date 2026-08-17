import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> createUserProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    validateUserProfileFields(
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
    final authenticatedUser = _firebaseAuth.currentUser;
    if (authenticatedUser == null || authenticatedUser.email == null) {
      throw StateError('An authenticated email account is required.');
    }

    await _users.doc(authenticatedUser.uid).set({
      'uid': authenticatedUser.uid,
      'email': authenticatedUser.email,
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'role': AppUserModel.customerRole,
      'verificationStatus': AppUserModel.notRequestedVerification,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUserModel?> getUserProfile(String uid) async {
    _requireOwnUid(uid);
    final document = await _users.doc(uid).get();
    return document.exists ? AppUserModel.fromFirestore(document) : null;
  }

  Stream<AppUserModel?> watchUserProfile(String uid) {
    _requireOwnUid(uid);
    return _users.doc(uid).snapshots().map(
          (document) =>
              document.exists ? AppUserModel.fromFirestore(document) : null,
        );
  }

  Future<void> updateSafeProfileFields({
    String? fullName,
    String? phoneNumber,
  }) async {
    final authenticatedUser = _firebaseAuth.currentUser;
    if (authenticatedUser == null) {
      throw StateError('You must be signed in to update your profile.');
    }

    final updates = <String, dynamic>{};
    if (fullName != null || phoneNumber != null) {
      validateUserProfileFields(
        fullName: fullName,
        phoneNumber: phoneNumber,
        allowOmittedFields: true,
      );
    }
    if (fullName != null) updates['fullName'] = fullName.trim();
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber.trim();
    if (updates.isEmpty) return;

    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(authenticatedUser.uid).update(updates);
  }

  void _requireOwnUid(String uid) {
    if (_firebaseAuth.currentUser?.uid != uid) {
      throw StateError('A user may only access their own profile.');
    }
  }
}

void validateUserProfileFields({
  String? fullName,
  String? phoneNumber,
  bool allowOmittedFields = false,
}) {
  if (!allowOmittedFields && fullName == null) {
    throw ArgumentError('A full name is required.');
  }
  final trimmedName = fullName?.trim();
  if (trimmedName != null &&
      (trimmedName.isEmpty || trimmedName.length > 120)) {
    throw ArgumentError('Full name must be between 1 and 120 characters.');
  }
  if (phoneNumber != null && phoneNumber.trim().length > 30) {
    throw ArgumentError('Phone number must be 30 characters or fewer.');
  }
}
