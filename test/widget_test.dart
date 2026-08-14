import 'package:flutter_test/flutter_test.dart';

import 'package:stay_nest/main.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/screens/welcome_screen.dart';

void main() {
  testWidgets('StayNest opens welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StayNestApp(home: WelcomeScreen()));

    expect(find.text('StayNest'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  test('RoomModel keeps numeric rent and Firestore room fields', () {
    const room = RoomModel(
      id: 'room-id',
      ownerId: 'owner-id',
      title: 'Test Room',
      location: 'Kathmandu',
      monthlyRent: 8500,
      genderPreference: 'Any',
      description: 'Test description',
      imageUrls: ['assets/images/room1.jpeg'],
      isAvailable: true,
    );

    final data = room.toFirestore();

    expect(room.formattedMonthlyRent, '8,500');
    expect(data['monthlyRent'], 8500);
    expect(data['ownerId'], 'owner-id');
    expect(data.containsKey('ownerPhone'), isFalse);
  });
}
