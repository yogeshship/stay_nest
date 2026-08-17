import 'package:flutter_test/flutter_test.dart';

import 'package:stay_nest/main.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/models/inquiry_model.dart';
import 'package:stay_nest/models/app_user_model.dart';
import 'package:stay_nest/models/verification_request_model.dart';
import 'package:stay_nest/screens/welcome_screen.dart';
import 'package:stay_nest/services/storage_service.dart';
import 'package:stay_nest/widgets/room_image.dart';

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

  test('RoomImage distinguishes network URLs from legacy asset paths', () {
    expect(isNetworkRoomImageSource('https://example.com/room.jpg'), isTrue);
    expect(isNetworkRoomImageSource('http://example.com/room.jpg'), isTrue);
    expect(isNetworkRoomImageSource('assets/images/room1.jpeg'), isFalse);
    expect(isNetworkRoomImageSource(''), isFalse);
  });

  test('Room image filenames preserve safe extensions and avoid collisions',
      () {
    final first = roomImageFileName(
      originalName: 'room photo.PNG',
      batchId: 1723456789,
      index: 0,
    );
    final second = roomImageFileName(
      originalName: 'room photo.PNG',
      batchId: 1723456789,
      index: 1,
    );

    expect(first, '1723456789_0.png');
    expect(second, '1723456789_1.png');
    expect(first, isNot(second));
    expect(roomImageContentType('room.webp'), 'image/webp');
    expect(roomImageContentType('room.unknown'), 'image/jpeg');
  });

  test('Owner verification request model keeps safe workflow metadata', () {
    final submittedAt = DateTime.utc(2026, 8, 15, 7);
    final request = VerificationRequestModel.fromMap('owner-id', {
      'ownerId': 'owner-id',
      'status': VerificationRequestModel.rejectedStatus,
      'submittedAt': submittedAt,
      'updatedAt': submittedAt,
      'rejectionReason': 'Please confirm the property details.',
      'ownerDisplayName': 'Test Owner',
      'ownerEmail': 'owner@example.com',
    });

    final data = request.toFirestore();

    expect(request.id, 'owner-id');
    expect(request.ownerId, 'owner-id');
    expect(data['status'], VerificationRequestModel.rejectedStatus);
    expect(data['rejectionReason'], isNotEmpty);
    expect(data.containsKey('phoneNumber'), isFalse);
    expect(data.containsKey('documentUrl'), isFalse);
  });

  test('Only eligible active owners can request verification', () {
    AppUserModel ownerWithStatus(String status) => AppUserModel(
          uid: 'owner-id',
          email: 'owner@example.com',
          fullName: 'Test Owner',
          phoneNumber: '',
          role: 'owner',
          verificationStatus: status,
          isActive: true,
        );

    expect(
      ownerWithStatus(AppUserModel.notRequestedVerification)
          .canRequestOwnerVerification,
      isTrue,
    );
    expect(
      ownerWithStatus(AppUserModel.rejectedVerification)
          .canRequestOwnerVerification,
      isTrue,
    );
    expect(
      ownerWithStatus(AppUserModel.pendingVerification)
          .canRequestOwnerVerification,
      isFalse,
    );
    expect(
      ownerWithStatus(AppUserModel.approvedVerification).isVerifiedOwner,
      isTrue,
    );
  });
}
