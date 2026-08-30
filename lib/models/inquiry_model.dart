import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryModel {
  const InquiryModel({
    required this.id,
    required this.roomId,
    required this.customerId,
    required this.ownerId,
    required this.type,
    required this.message,
    required this.status,
    required this.hiddenByCustomer,
    required this.roomTitle,
    required this.roomLocation,
    required this.customerDisplayName,
    this.scheduledVisitAt,
    this.createdAt,
    this.updatedAt,
    this.customerReadAt,
    this.ownerReadAt,
  });

  static const inquiryType = 'inquiry';
  static const visitRequestType = 'visitRequest';

  static const pendingStatus = 'pending';
  static const acceptedStatus = 'accepted';
  static const declinedStatus = 'declined';
  static const completedStatus = 'completed';
  static const cancelledStatus = 'cancelled';

  static const validTypes = {inquiryType, visitRequestType};
  static const validStatuses = {
    pendingStatus,
    acceptedStatus,
    declinedStatus,
    completedStatus,
    cancelledStatus,
  };

  final String id;
  final String roomId;
  final String customerId;
  final String ownerId;
  final String type;
  final String message;
  final String status;
  final DateTime? scheduledVisitAt;
  final bool hiddenByCustomer;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? customerReadAt;
  final DateTime? ownerReadAt;
  final String roomTitle;
  final String roomLocation;
  final String customerDisplayName;

  String get typeLabel =>
      type == visitRequestType ? 'Visit Request' : 'Inquiry';

  String get statusLabel => switch (status) {
        acceptedStatus => 'Accepted',
        declinedStatus => 'Declined',
        completedStatus => 'Completed',
        cancelledStatus => 'Cancelled',
        _ => 'Pending',
      };

  bool get isUnreadForCustomer =>
      customerReadAt == null ||
      (updatedAt != null && updatedAt!.isAfter(customerReadAt!));

  bool get isUnreadForOwner =>
      ownerReadAt == null ||
      (createdAt != null && createdAt!.isAfter(ownerReadAt!));

  String get customerActivityDescription {
    if (type == visitRequestType &&
        status == acceptedStatus &&
        scheduledVisitAt != null) {
      return 'Your visit has been scheduled.';
    }
    return switch (status) {
      acceptedStatus => type == visitRequestType
          ? 'Your visit request was accepted.'
          : 'Your inquiry was accepted.',
      declinedStatus => type == visitRequestType
          ? 'Your visit request was declined.'
          : 'Your inquiry was declined.',
      completedStatus => type == visitRequestType
          ? 'Your scheduled visit was completed.'
          : 'Your inquiry was completed.',
      cancelledStatus => type == visitRequestType
          ? 'Your visit request was cancelled.'
          : 'Your inquiry was cancelled.',
      _ => type == visitRequestType
          ? 'Your visit request is awaiting the owner.'
          : 'Your inquiry is awaiting the owner.',
    };
  }

  String get ownerActivityDescription => type == visitRequestType
      ? 'New visit request from $customerDisplayName.'
      : 'New inquiry from $customerDisplayName.';

  factory InquiryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) throw StateError('The inquiry does not exist.');
    return InquiryModel.fromMap(document.id, data);
  }

  factory InquiryModel.fromMap(String id, Map<String, dynamic> data) {
    return InquiryModel(
      id: id,
      roomId: data['roomId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      type: data['type'] as String? ?? inquiryType,
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? pendingStatus,
      scheduledVisitAt: _dateTime(data['scheduledVisitAt']),
      hiddenByCustomer: data['hiddenByCustomer'] as bool? ?? false,
      createdAt: _dateTime(data['createdAt']),
      updatedAt: _dateTime(data['updatedAt']),
      customerReadAt: _dateTime(data['customerReadAt']),
      ownerReadAt: _dateTime(data['ownerReadAt']),
      roomTitle: data['roomTitle'] as String? ?? '',
      roomLocation: data['roomLocation'] as String? ?? '',
      customerDisplayName:
          data['customerDisplayName'] as String? ?? 'StayNest customer',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'customerId': customerId,
      'ownerId': ownerId,
      'type': type,
      'message': message,
      'status': status,
      'scheduledVisitAt': scheduledVisitAt == null
          ? null
          : Timestamp.fromDate(scheduledVisitAt!),
      'hiddenByCustomer': hiddenByCustomer,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'customerReadAt':
          customerReadAt == null ? null : Timestamp.fromDate(customerReadAt!),
      'ownerReadAt':
          ownerReadAt == null ? null : Timestamp.fromDate(ownerReadAt!),
      'roomTitle': roomTitle,
      'roomLocation': roomLocation,
      'customerDisplayName': customerDisplayName,
    };
  }

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
