import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/owner_analytics.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/widgets/room_performance_card.dart';

RoomPerformance performance({bool available = true, int reviews = 0}) =>
    RoomPerformance(
      room: RoomModel(
        id: 'room',
        ownerId: 'owner',
        title: 'A very long listing title that should remain well behaved',
        location: 'Kathmandu',
        monthlyRent: 10000,
        genderPreference: 'Any',
        description: 'Description',
        imageUrls: const [],
        isAvailable: available,
      ),
      totalRequests: 3,
      pendingRequests: 1,
      acceptedRequests: 1,
      completedRequests: 1,
      completedVisitCount: 1,
      declinedRequests: 0,
      unreadRequestCount: 1,
      reviewCount: reviews,
      averageRating: reviews == 0 ? 0 : 4.5,
    );

void main() {
  testWidgets('room card shows zero-review and unavailable states',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: RoomPerformanceCard(
            performance: performance(available: false),
          ),
        ),
      ),
    ));
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.textContaining('No ratings yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('room card shows request visit review and rating values',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RoomPerformanceCard(performance: performance(reviews: 2)),
      ),
    ));
    expect(find.textContaining('Requests: 3'), findsOneWidget);
    expect(find.textContaining('Completed visits: 1'), findsOneWidget);
    expect(find.textContaining('Reviews: 2'), findsOneWidget);
    expect(find.textContaining('Rating: 4.5'), findsOneWidget);
  });
}
