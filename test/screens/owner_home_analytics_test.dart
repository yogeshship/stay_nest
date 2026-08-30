import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/app_user_model.dart';
import 'package:stay_nest/models/inquiry_model.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/screens/owner_analytics_screen.dart';
import 'package:stay_nest/screens/owner_home_screen.dart';

AppUserModel ownerProfile({bool verified = true, bool active = true}) =>
    AppUserModel(
      uid: 'owner',
      email: 'owner@example.com',
      fullName: 'Owner',
      phoneNumber: '',
      role: AppUserModel.ownerRole,
      verificationStatus: verified
          ? AppUserModel.approvedVerification
          : AppUserModel.pendingVerification,
      isActive: active,
    );

RoomModel ownerRoom(String id, bool available) => RoomModel(
      id: id,
      ownerId: 'owner',
      title: id,
      location: 'Kathmandu',
      monthlyRent: 10000,
      genderPreference: 'Any',
      description: 'Description',
      imageUrls: const [],
      isAvailable: available,
    );

InquiryModel ownerInquiry(String id) => InquiryModel(
      id: id,
      roomId: 'a',
      customerId: 'customer',
      ownerId: 'owner',
      type: InquiryModel.inquiryType,
      message: 'Message',
      status: InquiryModel.pendingStatus,
      hiddenByCustomer: false,
      roomTitle: 'Room',
      roomLocation: 'Kathmandu',
      customerDisplayName: 'Customer',
    );

void main() {
  testWidgets('dashboard uses one inquiry subscription and shows live counts',
      (tester) async {
    var inquirySubscriptions = 0;
    final controller = StreamController<List<InquiryModel>>.broadcast(
      onListen: () => inquirySubscriptions++,
    );
    await tester.pumpWidget(MaterialApp(
      home: OwnerHomeScreen(
        profileStream: Stream.value(ownerProfile()),
        roomsStream: Stream.value([
          ownerRoom('a', true),
          ownerRoom('b', false),
        ]),
        inquiriesStream: controller.stream,
      ),
    ));
    controller.add([ownerInquiry('request')]);
    await tester.pump();
    expect(inquirySubscriptions, 1);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(3));
    await controller.close();
  });

  testWidgets('verified analytics action opens analytics screen',
      (tester) async {
    Widget? opened;
    await tester.pumpWidget(MaterialApp(
      home: OwnerHomeScreen(
        profileStream: Stream.value(ownerProfile()),
        roomsStream: Stream.value(const []),
        inquiriesStream: Stream.value(const []),
        screenOpener: (_, screen) async => opened = screen,
      ),
    ));
    await tester.pump();
    expect(find.text('Requests, visits, ratings, and listing performance'),
        findsOneWidget);
    await tester.tap(find.text('Listing Analytics'));
    expect(opened, isA<OwnerAnalyticsScreen>());
  });

  testWidgets('unverified and inactive analytics actions fail closed',
      (tester) async {
    var opens = 0;
    Future<void> opener(_, __) async => opens++;
    await tester.pumpWidget(MaterialApp(
      home: OwnerHomeScreen(
        key: const ValueKey('unverified'),
        profileStream: Stream.value(ownerProfile(verified: false)),
        roomsStream: Stream.value(const []),
        inquiriesStream: Stream.value(const []),
        screenOpener: opener,
      ),
    ));
    await tester.pump();
    expect(find.text('Owner verification approval required'), findsNWidgets(2));
    expect(find.textContaining('required to view dashboard analytics'),
        findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: OwnerHomeScreen(
        key: const ValueKey('inactive'),
        profileStream: Stream.value(ownerProfile(active: false)),
        roomsStream: Stream.value(const []),
        inquiriesStream: Stream.value(const []),
        screenOpener: opener,
      ),
    ));
    await tester.pump();
    expect(find.text('Dashboard analytics are unavailable for this account.'),
        findsOneWidget);
    expect(find.text('Listing Analytics'), findsNothing);
    expect(opens, 0);
  });
}
