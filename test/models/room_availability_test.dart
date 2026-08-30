import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/widgets/room_card.dart';

void main() {
  RoomModel room({required bool isAvailable}) => RoomModel(
        id: 'room-id',
        ownerId: 'owner-id',
        title: 'Test Room',
        location: 'Kathmandu',
        monthlyRent: 8000,
        genderPreference: 'Any',
        description: 'Description',
        imageUrls: const [],
        isAvailable: isAvailable,
      );

  test('unavailable rooms have explicit presentation and disabled requests',
      () {
    final unavailableRoom = room(isAvailable: false);

    expect(unavailableRoom.availabilityLabel, 'Unavailable');
    expect(unavailableRoom.canCreateCustomerRequest, isFalse);
  });

  test('available room presentation and request behavior remain unchanged', () {
    final availableRoom = room(isAvailable: true);

    expect(availableRoom.availabilityLabel, 'Available');
    expect(availableRoom.canCreateCustomerRequest, isTrue);
  });

  testWidgets('availability badge is shown only for unavailable room cards',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoomAvailabilityBadge(room: room(isAvailable: false)),
      ),
    );
    expect(find.text('UNAVAILABLE'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: RoomAvailabilityBadge(room: room(isAvailable: true)),
      ),
    );
    expect(find.text('UNAVAILABLE'), findsNothing);
  });
}
