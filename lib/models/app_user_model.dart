import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  static const notRequestedVerification = 'notRequested';
  static const pendingVerification = 'pending';
  static const approvedVerification = 'approved';
  static const rejectedVerification = 'rejected';

  const AppUserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.verificationStatus,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String verificationStatus;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isVerifiedOwner =>
      role == 'owner' && isActive && verificationStatus == approvedVerification;

  bool get canRequestOwnerVerification =>
      role == 'owner' &&
      isActive &&
      (verificationStatus == notRequestedVerification ||
          verificationStatus == rejectedVerification);

  factory AppUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('The user profile does not exist.');
    }

    return AppUserModel(
      uid: data['uid'] as String? ?? document.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      role: data['role'] as String? ?? '',
      verificationStatus: data['verificationStatus'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
