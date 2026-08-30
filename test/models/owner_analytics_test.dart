import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/inquiry_model.dart';
import 'package:stay_nest/models/owner_analytics.dart';
import 'package:stay_nest/models/review_model.dart';
import 'package:stay_nest/models/room_model.dart';

RoomModel room(String id, {bool available = true, String title = 'Room'}) =>
    RoomModel(
      id: id,
      ownerId: 'owner',
      title: '$title $id',
      location: 'Kathmandu',
      monthlyRent: 10000,
      genderPreference: 'Any',
      description: 'Description',
      imageUrls: const [],
      isAvailable: available,
    );

InquiryModel inquiry(
  String id,
  String roomId,
  String status, {
  String type = InquiryModel.inquiryType,
  DateTime? createdAt,
  DateTime? ownerReadAt,
}) =>
    InquiryModel(
      id: id,
      roomId: roomId,
      customerId: 'customer',
      ownerId: 'owner',
      type: type,
      message: 'Message',
      status: status,
      hiddenByCustomer: false,
      roomTitle: 'Room',
      roomLocation: 'Kathmandu',
      customerDisplayName: 'Customer',
      createdAt: createdAt,
      ownerReadAt: ownerReadAt,
    );

ReviewModel review(String id, String roomId, int rating) => ReviewModel(
      id: id,
      roomId: roomId,
      customerId: id,
      eligibilityInquiryId: 'visit',
      rating: rating,
      reviewText: 'Review',
      reviewerDisplayName: 'Customer',
    );

void main() {
  test('listing and workflow counts preserve definitions and invariants', () {
    final analytics = calculateOwnerAnalytics(
      rooms: [room('a'), room('b', available: false)],
      inquiries: [
        inquiry('p', 'a', InquiryModel.pendingStatus),
        inquiry('a', 'a', InquiryModel.acceptedStatus),
        inquiry('c', 'a', InquiryModel.completedStatus),
        inquiry('v', 'b', InquiryModel.completedStatus,
            type: InquiryModel.visitRequestType),
        inquiry('d', 'b', InquiryModel.declinedStatus),
        inquiry('x', 'b', InquiryModel.cancelledStatus),
        inquiry('unknown', 'b', 'legacy-status'),
      ],
      reviews: const [],
    );
    expect(analytics.totalListings, 2);
    expect(analytics.availableListings + analytics.unavailableListings, 2);
    expect(analytics.totalRequests, 7);
    expect(analytics.completedRequests, 2);
    expect(analytics.completedVisits, 1);
    expect(analytics.cancelledOrOtherRequests, 2);
  });

  test('weighted owner rating is not an average of room averages', () {
    final analytics = calculateOwnerAnalytics(
      rooms: [room('a'), room('b')],
      inquiries: const [],
      reviews: [
        review('one', 'a', 5),
        review('two', 'b', 1),
        review('three', 'b', 1),
        review('four', 'b', 1),
      ],
    );
    expect(analytics.averageRating, 2);
    expect(analytics.totalReviews, 4);
    expect(analytics.ratedRoomCount, 2);
  });

  test('duplicates and malformed ratings are excluded safely', () {
    final analytics = calculateOwnerAnalytics(
      rooms: [room('a')],
      inquiries: const [],
      reviews: [
        review('same', 'a', 5),
        review('same', 'a', 1),
        review('invalid-low', 'a', 0),
        review('invalid-high', 'a', 6),
        review('foreign', 'missing', 4),
      ],
    );
    expect(analytics.totalReviews, 1);
    expect(analytics.averageRating, 5);
  });

  test('zero-activity rooms remain present with zero values', () {
    final analytics = calculateOwnerAnalytics(
      rooms: [room('empty')],
      inquiries: const [],
      reviews: const [],
    );
    expect(analytics.roomPerformance, hasLength(1));
    expect(analytics.roomPerformance.single.totalRequests, 0);
    expect(analytics.roomPerformance.single.reviewCount, 0);
    expect(analytics.roomPerformance.single.averageRating, 0);
  });

  test('orphaned inquiries remain in totals but not room performance', () {
    final analytics = calculateOwnerAnalytics(
      rooms: [room('current')],
      inquiries: [inquiry('old', 'deleted', InquiryModel.pendingStatus)],
      reviews: const [],
    );
    expect(analytics.totalRequests, 1);
    expect(analytics.orphanedInquiryCount, 1);
    expect(analytics.roomPerformance.single.totalRequests, 0);
  });

  test('owner unread semantics are reused', () {
    final created = DateTime.utc(2026, 8, 1, 10);
    final analytics = calculateOwnerAnalytics(
      rooms: [room('a')],
      inquiries: [
        inquiry('unread', 'a', InquiryModel.pendingStatus, createdAt: created),
        inquiry('read', 'a', InquiryModel.pendingStatus,
            createdAt: created,
            ownerReadAt: created.add(const Duration(hours: 1))),
      ],
      reviews: const [],
    );
    expect(analytics.unreadRequests, 1);
    expect(analytics.roomPerformance.single.unreadRequestCount, 1);
  });

  test('recent requests sort null dates last with deterministic ties', () {
    final same = DateTime.utc(2026, 8, 2);
    final items = recentOwnerInquiries([
      inquiry('z-null', 'a', InquiryModel.pendingStatus),
      inquiry('b', 'a', InquiryModel.pendingStatus, createdAt: same),
      inquiry('a', 'a', InquiryModel.pendingStatus, createdAt: same),
      inquiry('new', 'a', InquiryModel.pendingStatus,
          createdAt: same.add(const Duration(days: 1))),
    ]);
    expect(items.map((item) => item.id), ['new', 'a', 'b', 'z-null']);
  });

  test('room performance sorting follows unread pending total and title', () {
    final analytics = calculateOwnerAnalytics(
      rooms: [room('z', title: 'Zulu'), room('a', title: 'Alpha')],
      inquiries: [
        inquiry('read', 'z', InquiryModel.pendingStatus,
            createdAt: DateTime.utc(2026),
            ownerReadAt: DateTime.utc(2026, 1, 2)),
        inquiry('unread', 'a', InquiryModel.acceptedStatus),
      ],
      reviews: const [],
    );
    expect(analytics.roomPerformance.first.room.id, 'a');
  });
}
