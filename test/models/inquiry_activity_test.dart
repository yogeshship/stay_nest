import 'package:flutter_test/flutter_test.dart';

import 'package:stay_nest/models/inquiry_model.dart';
import 'package:stay_nest/services/inquiry_service.dart';

InquiryModel inquiry({
  String id = 'request',
  String type = InquiryModel.inquiryType,
  String status = InquiryModel.pendingStatus,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? customerReadAt,
  DateTime? ownerReadAt,
  DateTime? scheduledVisitAt,
}) {
  return InquiryModel(
    id: id,
    roomId: 'room',
    customerId: 'customer',
    ownerId: 'owner',
    type: type,
    message: 'Is this available?',
    status: status,
    hiddenByCustomer: false,
    roomTitle: 'Test Room',
    roomLocation: 'Kathmandu',
    customerDisplayName: 'Student',
    createdAt: createdAt,
    updatedAt: updatedAt,
    customerReadAt: customerReadAt,
    ownerReadAt: ownerReadAt,
    scheduledVisitAt: scheduledVisitAt,
  );
}

void main() {
  final created = DateTime.utc(2026, 8, 20, 8);
  final updated = DateTime.utc(2026, 8, 20, 9);

  test('legacy inquiries without receipts are unread for both roles', () {
    final legacy = InquiryModel.fromMap('legacy', {
      'roomId': 'room',
      'customerId': 'customer',
      'ownerId': 'owner',
      'type': 'inquiry',
      'message': 'Hello',
      'status': 'pending',
      'hiddenByCustomer': false,
      'roomTitle': 'Room',
      'roomLocation': 'Kathmandu',
      'customerDisplayName': 'Student',
      'createdAt': created,
      'updatedAt': updated,
    });

    expect(legacy.customerReadAt, isNull);
    expect(legacy.ownerReadAt, isNull);
    expect(legacy.isUnreadForCustomer, isTrue);
    expect(legacy.isUnreadForOwner, isTrue);
  });

  test('role-specific unread comparisons use the meaningful timestamp', () {
    final ownerRead = DateTime.utc(2026, 8, 20, 8, 30);
    final customerRead = DateTime.utc(2026, 8, 20, 8, 30);
    final item = inquiry(
      createdAt: created,
      updatedAt: updated,
      ownerReadAt: ownerRead,
      customerReadAt: customerRead,
    );

    expect(item.isUnreadForOwner, isFalse,
        reason: 'A later updatedAt must not create owner activity.');
    expect(item.isUnreadForCustomer, isTrue);
  });

  test('customer and owner sorting use updatedAt and createdAt respectively',
      () {
    final readAt = DateTime.utc(2026, 8, 21);
    final olderCreationWithNewUpdate = inquiry(
      id: 'older-creation',
      createdAt: created,
      updatedAt: DateTime.utc(2026, 8, 20, 12),
      customerReadAt: readAt,
      ownerReadAt: readAt,
    );
    final newerCreation = inquiry(
      id: 'newer-creation',
      createdAt: DateTime.utc(2026, 8, 20, 10),
      updatedAt: DateTime.utc(2026, 8, 20, 10),
      customerReadAt: readAt,
      ownerReadAt: readAt,
    );

    expect(
        sortCustomerActivity([newerCreation, olderCreationWithNewUpdate])
            .first
            .id,
        'older-creation');
    expect(
        sortOwnerActivity([olderCreationWithNewUpdate, newerCreation]).first.id,
        'newer-creation');
  });

  test('unread items sort before read items', () {
    final unread = inquiry(
      id: 'unread',
      createdAt: created,
      updatedAt: created,
    );
    final read = inquiry(
      id: 'read',
      createdAt: updated,
      updatedAt: updated,
      customerReadAt: DateTime.utc(2026, 8, 21),
      ownerReadAt: DateTime.utc(2026, 8, 21),
    );
    expect(sortCustomerActivity([read, unread]).first.id, 'unread');
    expect(sortOwnerActivity([read, unread]).first.id, 'unread');
  });

  test('descriptions cover statuses and scheduled visits', () {
    expect(inquiry().customerActivityDescription, contains('awaiting'));
    expect(
      inquiry(status: InquiryModel.acceptedStatus).customerActivityDescription,
      'Your inquiry was accepted.',
    );
    expect(
      inquiry(status: InquiryModel.declinedStatus).customerActivityDescription,
      'Your inquiry was declined.',
    );
    expect(
      inquiry(
        type: InquiryModel.visitRequestType,
        status: InquiryModel.acceptedStatus,
        scheduledVisitAt: updated,
      ).customerActivityDescription,
      'Your visit has been scheduled.',
    );
    expect(
      inquiry(
        type: InquiryModel.visitRequestType,
        status: InquiryModel.completedStatus,
        scheduledVisitAt: updated,
      ).customerActivityDescription,
      'Your scheduled visit was completed.',
    );
    expect(
      inquiry(type: InquiryModel.visitRequestType).ownerActivityDescription,
      'New visit request from Student.',
    );
  });

  test('owner count helpers distinguish pending and unread requests', () {
    final readPending = inquiry(
      id: 'read-pending',
      createdAt: created,
      updatedAt: created,
      ownerReadAt: updated,
    );
    final unreadCompleted = inquiry(
      id: 'unread-completed',
      status: InquiryModel.completedStatus,
      createdAt: updated,
      updatedAt: updated,
    );

    expect(pendingOwnerInquiryCount([readPending, unreadCompleted]), 1);
    expect(unreadOwnerInquiryCount([readPending, unreadCompleted]), 1);
  });
}
