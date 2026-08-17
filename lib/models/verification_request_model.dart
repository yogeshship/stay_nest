import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationRequestModel {
  const VerificationRequestModel({
    required this.id,
    required this.ownerId,
    required this.status,
    required this.ownerDisplayName,
    required this.ownerEmail,
    this.submittedAt,
    this.updatedAt,
    this.rejectionReason,
  });

  static const pendingStatus = 'pending';
  static const approvedStatus = 'approved';
  static const rejectedStatus = 'rejected';

  final String id;
  final String ownerId;
  final String status;
  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final String? rejectionReason;
  final String ownerDisplayName;
  final String ownerEmail;

  factory VerificationRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('The verification request does not exist.');
    }
    return VerificationRequestModel.fromMap(document.id, data);
  }

  factory VerificationRequestModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return VerificationRequestModel(
      id: id,
      ownerId: data['ownerId'] as String? ?? '',
      status: data['status'] as String? ?? pendingStatus,
      submittedAt: _dateTime(data['submittedAt']),
      updatedAt: _dateTime(data['updatedAt']),
      rejectionReason: data['rejectionReason'] as String?,
      ownerDisplayName: data['ownerDisplayName'] as String? ?? '',
      ownerEmail: data['ownerEmail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'status': status,
      'submittedAt':
          submittedAt == null ? null : Timestamp.fromDate(submittedAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'rejectionReason': rejectionReason,
      'ownerDisplayName': ownerDisplayName,
      'ownerEmail': ownerEmail,
    };
  }

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
