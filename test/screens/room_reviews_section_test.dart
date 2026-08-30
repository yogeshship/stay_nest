import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/app_user_model.dart';
import 'package:stay_nest/models/inquiry_model.dart';
import 'package:stay_nest/models/review_model.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/screens/room_detail_screen.dart';
import 'package:stay_nest/services/review_service.dart';

const room = RoomModel(
  id: 'room',
  ownerId: 'owner',
  title: 'Room',
  location: 'Kathmandu',
  monthlyRent: 10000,
  genderPreference: 'Any',
  description: 'Description',
  imageUrls: [],
  isAvailable: true,
);

AppUserModel profile(String role, {String uid = 'customer'}) => AppUserModel(
      uid: uid,
      email: '$uid@example.com',
      fullName: 'User',
      phoneNumber: '',
      role: role,
      verificationStatus: AppUserModel.approvedVerification,
      isActive: true,
    );

final ownReview = ReviewModel(
  id: 'customer_room',
  roomId: 'room',
  customerId: 'customer',
  eligibilityInquiryId: 'visit',
  rating: 5,
  reviewText: 'Excellent room',
  reviewerDisplayName: 'Customer',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final completedVisit = InquiryModel(
  id: 'visit',
  roomId: 'room',
  customerId: 'customer',
  ownerId: 'owner',
  type: InquiryModel.visitRequestType,
  message: 'Visit',
  status: InquiryModel.completedStatus,
  hiddenByCustomer: false,
  roomTitle: 'Room',
  roomLocation: 'Kathmandu',
  customerDisplayName: 'Customer',
);

Widget section({
  required Stream<List<ReviewModel>> reviews,
  required AppUserModel user,
  Stream<ReviewModel?>? own,
  ReviewEligibility? eligibility,
  Future<ReviewEligibility>? eligibilityFuture,
  Future<void> Function(ReviewModel?, int, String)? onSave,
  Future<void> Function()? onDelete,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RoomReviewsSection(
            key: UniqueKey(),
            room: room,
            reviewsStream: reviews,
            profileFuture: Future.value(user),
            ownReviewStream: own,
            eligibilityFuture: eligibilityFuture ??
                (eligibility == null ? null : Future.value(eligibility)),
            onSaveReview: onSave,
            onDeleteReview: onDelete,
          ),
        ),
      ),
    );

void main() {
  testWidgets('review section renders loading, empty, and error states',
      (tester) async {
    await tester.pumpWidget(section(
      reviews: const Stream.empty(),
      user: profile(AppUserModel.ownerRole, uid: 'owner'),
    ));
    expect(find.byKey(const Key('reviews-loading')), findsOneWidget);

    await tester.pumpWidget(section(
      reviews: Stream.value([]),
      user: profile(AppUserModel.ownerRole, uid: 'owner'),
    ));
    await tester.pump();
    expect(find.byKey(const Key('reviews-empty')), findsOneWidget);
    expect(
        find.text('Reviews are read-only for this account.'), findsOneWidget);

    await tester.pumpWidget(section(
      reviews: Stream.error(StateError('failed')),
      user: profile(AppUserModel.ownerRole, uid: 'owner'),
    ));
    await tester.pump();
    expect(find.byKey(const Key('reviews-error')), findsOneWidget);
  });

  testWidgets('eligible customer sees write action and ineligible explanation',
      (tester) async {
    await tester.pumpWidget(section(
      reviews: Stream.value([]),
      user: profile(AppUserModel.customerRole),
      own: Stream.value(null),
      eligibility:
          ReviewEligibility(inquiry: completedVisit, message: 'Eligible'),
      onSave: (_, __, ___) async {},
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('write-review-button')), findsOneWidget);

    await tester.pumpWidget(section(
      reviews: Stream.value([]),
      user: profile(AppUserModel.customerRole),
      own: Stream.value(null),
      eligibility: const ReviewEligibility(message: 'Complete a visit first.'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Complete a visit first.'), findsOneWidget);
  });

  testWidgets('eligibility lookup errors show a stable error state',
      (tester) async {
    final eligibility = Completer<ReviewEligibility>();
    await tester.pumpWidget(section(
      reviews: Stream.value([]),
      user: profile(AppUserModel.customerRole),
      own: Stream.value(null),
      eligibilityFuture: eligibility.future,
    ));
    await tester.pump();
    await tester.pump();
    eligibility.completeError(StateError('permission denied'));
    await tester.pumpAndSettle();
    expect(
      find.text('Review eligibility could not be checked.'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('own review provides edit and confirmed delete controls',
      (tester) async {
    var deleted = false;
    await tester.pumpWidget(section(
      reviews: Stream.value([ownReview]),
      user: profile(AppUserModel.customerRole),
      own: Stream.value(ownReview),
      onSave: (_, __, ___) async {},
      onDelete: () async {
        deleted = true;
      },
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-own-review')));
    await tester.pumpAndSettle();
    expect(find.text('Edit review'), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete-review-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}
