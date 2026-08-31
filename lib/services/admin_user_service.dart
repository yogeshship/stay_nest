import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user_model.dart';

class AdminUserPage {
  const AdminUserPage(
      {required this.users, required this.cursor, required this.hasMore});
  final List<AppUserModel> users;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class AdminUserService {
  AdminUserService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<AdminUserPage> loadUsers(
      {int limit = 25,
      String? role,
      bool? isActive,
      DocumentSnapshot<Map<String, dynamic>>? startAfter}) async {
    if (limit < 1 || limit > 100) throw ArgumentError('Invalid page size.');
    Query<Map<String, dynamic>> query = _firestore.collection('users');
    if (role != null) query = query.where('role', isEqualTo: role);
    if (isActive != null) query = query.where('isActive', isEqualTo: isActive);
    query = query.limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snapshot = await query.get();
    return AdminUserPage(
        users: snapshot.docs
            .map(AppUserModel.fromFirestore)
            .toList(growable: false),
        cursor: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
        hasMore: snapshot.docs.length == limit);
  }

  Future<void> setUserActive(
      {required String userId,
      required bool isActive,
      required String reason}) async {
    final adminId = _auth.currentUser?.uid;
    if (adminId == null) {
      throw StateError('You must be signed in as an administrator.');
    }
    if (userId == adminId) {
      throw StateError('You cannot change your own active status.');
    }
    if (userId.trim().isEmpty || userId.length > 128 || userId.contains('/')) {
      throw ArgumentError('Invalid user ID.');
    }
    if (reason.trim().isEmpty || reason.trim().length > 500) {
      throw ArgumentError('A valid reason is required.');
    }
    final userRef = _firestore.collection('users').doc(userId);
    final auditRef = _firestore.collection('adminActions').doc();
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw StateError('This user no longer exists.');
      final user = AppUserModel.fromFirestore(userDoc);
      if (user.uid != userId ||
          ![AppUserModel.customerRole, AppUserModel.ownerRole]
              .contains(user.role)) {
        throw StateError(
            'Only customer and owner accounts can be administered.');
      }
      transaction.update(userRef,
          {'isActive': isActive, 'updatedAt': FieldValue.serverTimestamp()});
      transaction.set(auditRef, {
        'adminId': adminId,
        'actionType': isActive ? 'reactivate_user' : 'deactivate_user',
        'targetType': 'user',
        'targetId': userId,
        'reason': reason.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'previousValue': user.isActive.toString(),
        'newValue': isActive.toString()
      });
    });
  }
}
