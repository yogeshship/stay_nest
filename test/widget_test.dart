import 'package:flutter_test/flutter_test.dart';

import 'package:stay_nest/main.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/models/inquiry_model.dart';
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

  test('InquiryModel serializes Firestore fields and nullable schedule', () {
    final createdAt = DateTime.utc(2026, 8, 15, 6, 30);
    final inquiry = InquiryModel.fromMap('inquiry-id', {
      'roomId': 'room-id',
      'customerId': 'customer-id',
      'ownerId': 'owner-id',
      'type': InquiryModel.visitRequestType,
      'message': 'I would like to visit.',
      'status': InquiryModel.acceptedStatus,
      'scheduledVisitAt': null,
      'hiddenByCustomer': false,
      'createdAt': createdAt,
      'updatedAt': createdAt,
      'roomTitle': 'Test Room',
      'roomLocation': 'Kathmandu',
      'customerDisplayName': 'Test Customer',
    });

    final data = inquiry.toFirestore();

    expect(inquiry.id, 'inquiry-id');
    expect(inquiry.scheduledVisitAt, isNull);
    expect(inquiry.typeLabel, 'Visit Request');
    expect(inquiry.statusLabel, 'Accepted');
    expect(data['customerId'], 'customer-id');
    expect(data['ownerId'], 'owner-id');
    expect(data['scheduledVisitAt'], isNull);
    expect(data.containsKey('phoneNumber'), isFalse);
  });
}
