import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:stay_nest/main.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/models/inquiry_model.dart';
import 'package:stay_nest/models/app_user_model.dart';
import 'package:stay_nest/models/verification_request_model.dart';
import 'package:stay_nest/screens/welcome_screen.dart';
import 'package:stay_nest/screens/admin_verification_dashboard_screen.dart';
import 'package:stay_nest/screens/auth_gate.dart';
import 'package:stay_nest/screens/owner_login_screen.dart';
import 'package:stay_nest/services/admin_verification_service.dart';
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

  test('Only active admin profiles satisfy the admin model helper', () {
    AppUserModel profile(String role, {bool isActive = true}) => AppUserModel(
          uid: 'user-id',
          email: 'user@example.com',
          fullName: 'Test User',
          phoneNumber: '',
          role: role,
          verificationStatus: AppUserModel.notRequestedVerification,
          isActive: isActive,
        );

    expect(profile(AppUserModel.adminRole).isActiveAdmin, isTrue);
    expect(
      profile(AppUserModel.adminRole, isActive: false).isActiveAdmin,
      isFalse,
    );
    expect(profile(AppUserModel.ownerRole).isActiveAdmin, isFalse);
    expect(profile(AppUserModel.customerRole).isActiveAdmin, isFalse);
  });

  test('Active admin role maps to the admin dashboard', () {
    const admin = AppUserModel(
      uid: 'admin-id',
      email: 'admin@example.com',
      fullName: 'Test Admin',
      phoneNumber: '',
      role: AppUserModel.adminRole,
      verificationStatus: AppUserModel.notRequestedVerification,
      isActive: true,
    );
    const inactiveAdmin = AppUserModel(
      uid: 'admin-id',
      email: 'admin@example.com',
      fullName: 'Test Admin',
      phoneNumber: '',
      role: AppUserModel.adminRole,
      verificationStatus: AppUserModel.notRequestedVerification,
      isActive: false,
    );

    expect(homeForActiveRole(admin), isA<AdminVerificationDashboardScreen>());
    expect(homeForActiveRole(inactiveAdmin), isNull);
  });

  testWidgets('Owner login success delegates to its AuthGate builder',
      (WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    final destination = ownerLoginDestinationAfterAuthentication(
      context,
      authGateBuilder: (_) => const Text('AuthGate destination'),
    );

    expect(destination, isA<Text>());
    expect((destination as Text).data, 'AuthGate destination');
  });

  test('Owner login role gate accepts only active owners and admins', () {
    AppUserModel profile(String role, {bool isActive = true}) => AppUserModel(
          uid: 'user-id',
          email: 'user@example.com',
          fullName: 'Test User',
          phoneNumber: '',
          role: role,
          verificationStatus: AppUserModel.notRequestedVerification,
          isActive: isActive,
        );

    expect(
      ownerLoginEligibility(profile(AppUserModel.ownerRole)),
      OwnerLoginEligibility.allowed,
    );
    expect(
      ownerLoginEligibility(profile(AppUserModel.adminRole)),
      OwnerLoginEligibility.allowed,
    );
    expect(
      ownerLoginEligibility(profile(AppUserModel.customerRole)),
      OwnerLoginEligibility.unsupportedRole,
    );
    expect(
      ownerLoginEligibility(
        profile(AppUserModel.ownerRole, isActive: false),
      ),
      OwnerLoginEligibility.inactive,
    );
    expect(
      ownerLoginEligibility(
        profile(AppUserModel.adminRole, isActive: false),
      ),
      OwnerLoginEligibility.inactive,
    );
    expect(
      ownerLoginEligibility(null),
      OwnerLoginEligibility.missingProfile,
    );
  });

  test('Rejection reason validation trims and enforces 500 characters', () {
    expect(validateRejectionReason(null), isNotNull);
    expect(validateRejectionReason('   '), isNotNull);
    expect(validateRejectionReason('Missing details'), isNull);
    expect(validateRejectionReason(List.filled(500, 'x').join()), isNull);
    expect(validateRejectionReason(List.filled(501, 'x').join()), isNotNull);
  });

  testWidgets('Admin dashboard shows its empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminVerificationDashboardScreen(
          adminVerificationService: _TestAdminVerificationService(
            Stream.value(const []),
          ),
          signOutOverride: () async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No pending requests'), findsOneWidget);
  });

  testWidgets('Admin dashboard shows pending owner information',
      (WidgetTester tester) async {
    final request = VerificationRequestModel(
      id: 'owner-id',
      ownerId: 'owner-id',
      status: VerificationRequestModel.pendingStatus,
      ownerDisplayName: 'Pending Owner',
      ownerEmail: 'pending@example.com',
      submittedAt: DateTime(2026, 8, 17, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminVerificationDashboardScreen(
          adminVerificationService: _TestAdminVerificationService(
            Stream.value([request]),
          ),
          signOutOverride: () async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Pending Owner'), findsOneWidget);
    expect(find.text('pending@example.com'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });
}

class _TestAdminVerificationService implements AdminVerificationService {
  _TestAdminVerificationService(this.requests);

  final Stream<List<VerificationRequestModel>> requests;

  @override
  Stream<List<VerificationRequestModel>> watchPendingVerificationRequests() =>
      requests;

  @override
  Future<void> approveVerificationRequest(String ownerUid) async {}

  @override
  Future<void> rejectVerificationRequest(
    String ownerUid,
    String reason,
  ) async {}
}
