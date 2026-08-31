import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActionModel {
  const AdminActionModel({
    required this.id,
    required this.adminId,
    required this.actionType,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.createdAt,
    this.previousValue,
    this.newValue,
  });

  final String id;
  final String adminId;
  final String actionType;
  final String targetType;
  final String targetId;
  final String reason;
  final DateTime? createdAt;
  final String? previousValue;
  final String? newValue;

  factory AdminActionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) throw StateError('The admin action does not exist.');
    DateTime? date;
    final timestamp = data['createdAt'];
    if (timestamp is Timestamp) date = timestamp.toDate();
    return AdminActionModel(
      id: document.id,
      adminId: data['adminId'] as String? ?? '',
      actionType: data['actionType'] as String? ?? '',
      targetType: data['targetType'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      createdAt: date,
      previousValue: data['previousValue'] as String?,
      newValue: data['newValue'] as String?,
    );
  }
}
