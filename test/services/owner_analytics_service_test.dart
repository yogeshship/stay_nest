import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/review_model.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/services/owner_analytics_service.dart';

RoomModel ownedRoom(String id, {String ownerId = 'owner'}) => RoomModel(
      id: id,
      ownerId: ownerId,
      title: id,
      location: 'Kathmandu',
      monthlyRent: 10000,
      genderPreference: 'Any',
      description: 'Description',
      imageUrls: const [],
      isAvailable: true,
    );

ReviewModel resultReview(String id, String roomId) => ReviewModel(
      id: id,
      roomId: roomId,
      customerId: id,
      eligibilityInquiryId: 'visit',
      rating: 4,
      reviewText: 'Review',
      reviewerDisplayName: 'Customer',
    );

void main() {
  test('unauthenticated analytics review load is rejected', () async {
    final service = OwnerAnalyticsService(
      authenticatedUid: '',
      reviewBatchLoader: (_) async => [],
    );
    await expectLater(
      service.loadReviewsForOwnedRooms([ownedRoom('a')]),
      throwsStateError,
    );
  });

  test('foreign room is rejected before any review query', () async {
    var calls = 0;
    final service = OwnerAnalyticsService(
      authenticatedUid: 'owner',
      reviewBatchLoader: (_) async {
        calls++;
        return [];
      },
    );
    await expectLater(
      service.loadReviewsForOwnedRooms([ownedRoom('a', ownerId: 'other')]),
      throwsStateError,
    );
    expect(calls, 0);
  });

  test('empty rooms return without a query', () async {
    var calls = 0;
    final service = OwnerAnalyticsService(
      authenticatedUid: 'owner',
      reviewBatchLoader: (_) async {
        calls++;
        return [];
      },
    );
    final result = await service.loadReviewsForOwnedRooms(const []);
    expect(result.reviews, isEmpty);
    expect(calls, 0);
  });

  test('room IDs are deduplicated and deterministically chunked', () async {
    final chunks = <List<String>>[];
    final service = OwnerAnalyticsService(
      authenticatedUid: 'owner',
      reviewBatchLoader: (ids) async {
        chunks.add(ids);
        return ids.map((id) => resultReview('review-$id', id)).toList();
      },
    );
    final rooms = [
      for (var index = 10; index >= 0; index--) ownedRoom('room-$index'),
      ownedRoom('room-0'),
    ];
    final result = await service.loadReviewsForOwnedRooms(rooms);
    expect(chunks, hasLength(2));
    expect(chunks.first, hasLength(OwnerAnalyticsService.reviewRoomChunkSize));
    expect(chunks.first, orderedEquals([...chunks.first]..sort()));
    expect(result.reviews, hasLength(11));
  });

  test('duplicate review results are defensively deduplicated', () async {
    final duplicate = resultReview('same', 'a');
    final service = OwnerAnalyticsService(
      authenticatedUid: 'owner',
      reviewBatchLoader: (_) async => [duplicate, duplicate],
    );
    final result = await service.loadReviewsForOwnedRooms([ownedRoom('a')]);
    expect(result.reviews, hasLength(1));
  });

  test('failed batch fails the whole snapshot and retry starts fresh',
      () async {
    var calls = 0;
    final service = OwnerAnalyticsService(
      authenticatedUid: 'owner',
      reviewBatchLoader: (_) async {
        calls++;
        if (calls == 2) throw StateError('batch failed');
        return [];
      },
    );
    final rooms = [
      for (var index = 0; index <= 10; index++) ownedRoom('room-$index'),
    ];
    await expectLater(
        service.loadReviewsForOwnedRooms(rooms), throwsStateError);
    expect(calls, 2);
    await service.loadReviewsForOwnedRooms(rooms);
    expect(calls, 4);
  });
}
