import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/admin_action_model.dart';

class AdminAuditService {
  AdminAuditService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _actions =>
      _firestore.collection('adminActions');

  Future<AdminActionPage> loadActions({
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (limit < 1 || limit > 100) throw ArgumentError('Invalid page size.');
    Query<Map<String, dynamic>> query =
        _actions.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snapshot = await query.get();
    return AdminActionPage(
        actions: snapshot.docs
            .map(AdminActionModel.fromFirestore)
            .toList(growable: false),
        cursor: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
        hasMore: snapshot.docs.length == limit);
  }

  Future<void> createAction({
    required String actionType,
    required String targetType,
    required String targetId,
    required String reason,
    String? previousValue,
    String? newValue,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('You must be signed in as an administrator.');
    }
    validateAdminActionReason(reason);
    validateAdminActionTargetId(targetId);
    final data = <String, dynamic>{
      'adminId': uid,
      'actionType': actionType,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (previousValue != null) data['previousValue'] = previousValue;
    if (newValue != null) data['newValue'] = newValue;
    await _actions.doc().set(data);
  }
}

class AdminActionPage {
  const AdminActionPage(
      {required this.actions, required this.cursor, required this.hasMore});
  final List<AdminActionModel> actions;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

void validateAdminActionReason(String value) {
  final reason = value.trim();
  if (reason.isEmpty || reason.length > 500) {
    throw ArgumentError('A reason between 1 and 500 characters is required.');
  }
}

void validateAdminActionTargetId(String value) {
  if (value.trim().isEmpty || value.length > 128 || value.contains('/')) {
    throw ArgumentError('A valid target ID is required.');
  }
}
