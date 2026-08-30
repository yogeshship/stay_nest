import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/app_user_model.dart';
import 'package:stay_nest/models/review_model.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/screens/owner_analytics_screen.dart';
import 'package:stay_nest/services/owner_analytics_service.dart';

AppUserModel profile({
  bool active = true,
  String verification = AppUserModel.approvedVerification,
}) =>
    AppUserModel(
      uid: 'owner',
      email: 'owner@example.com',
      fullName: 'Owner',
      phoneNumber: '',
      role: AppUserModel.ownerRole,
      verificationStatus: verification,
      isActive: active,
    );

RoomModel analyticsRoom(String id, {bool available = true}) => RoomModel(
      id: id,
      ownerId: 'owner',
      title: 'Room $id',
      location: 'Kathmandu',
      monthlyRent: 10000,
      genderPreference: 'Any',
      description: 'Description',
      imageUrls: const [],
      isAvailable: available,
    );

ReviewModel analyticsReview(String id, String roomId, int rating) =>
    ReviewModel(
      id: id,
      roomId: roomId,
      customerId: id,
      eligibilityInquiryId: 'visit',
      rating: rating,
      reviewText: 'Review',
      reviewerDisplayName: 'Customer',
    );

Widget screen({
  Key? key,
  required OwnerAnalyticsService service,
  AppUserModel? user,
  List<RoomModel> rooms = const [],
}) =>
    MaterialApp(
      home: OwnerAnalyticsScreen(
        key: key,
        analyticsService: service,
        profileStream: Stream.value(user ?? profile()),
        roomsStream: Stream.value(rooms),
        inquiriesStream: Stream.value(const []),
      ),
    );

void main() {
  testWidgets('unverified and inactive owners do not see analytics content',
      (tester) async {
    final service = OwnerAnalyticsService(
      authenticatedUid: 'owner',
      reviewBatchLoader: (_) async => [],
    );
    await tester.pumpWidget(screen(
      key: const ValueKey('unverified'),
      service: service,
      user: profile(verification: AppUserModel.pendingVerification),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('verification approval is required'),
        findsOneWidget);
    expect(find.text('Listing Overview'), findsNothing);

    await tester.pumpWidget(screen(
      key: const ValueKey('inactive'),
      service: service,
      user: profile(active: false),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('Analytics are unavailable for this account.'),
        findsOneWidget);
  });

  testWidgets(
      'verified owner sees weighted review analytics and empty requests',
      (tester) async {
    final service = OwnerAnalyticsService(
      authenticatedUid: 'owner',
      reviewBatchLoader: (_) async => [
        analyticsReview('a', 'one', 5),
        analyticsReview('b', 'two', 1),
        analyticsReview('c', 'two', 1),
        analyticsReview('d', 'two', 1),
      ],
      clock: () => DateTime(2026, 8, 30, 12, 15),
    );
    await tester.pumpWidget(screen(
      service: service,
      rooms: [analyticsRoom('one'), analyticsRoom('two', available: false)],
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Listing Overview'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Review Performance'), 300);
    await tester.pump();
    expect(find.text('2.0'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Recent Requests'), 300);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    expect(find.text('No requests received yet.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Per-room Performance'), -300);
    await tester.pump();
  });

  testWidgets('review loading does not hide room and request sections',
      (tester) async {
    final completer = Completer<List<ReviewModel>>();
    final service = OwnerAnalyticsService(
      authenticatedUid: 'owner',
      reviewBatchLoader: (_) => completer.future,
    );
    await tester.pumpWidget(screen(
      service: service,
      rooms: [analyticsRoom('one')],
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Listing Overview'), findsOneWidget);
    expect(find.text('Request Workflow'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Review Performance'), 300);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    completer.complete([]);
    await tester.pump();
  });

  testWidgets('review failure is section-only and retry loads fresh data',
      (tester) async {
    var calls = 0;
    final service = OwnerAnalyticsService(
      authenticatedUid: 'owner',
      reviewBatchLoader: (_) async {
        calls++;
        if (calls == 1) {
          await Future<void>.delayed(Duration.zero);
          throw StateError('Rating data could not be loaded.');
        }
        return [];
      },
    );
    await tester.pumpWidget(screen(
      service: service,
      rooms: [analyticsRoom('one')],
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Listing Overview'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Review Performance'), 300);
    await tester.pump();
    expect(find.textContaining('Rating data could not be loaded.'),
        findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(calls, 2);
    expect(
        find.textContaining('Rating data could not be loaded.'), findsNothing);
  });
}
