import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stay_nest/models/inquiry_model.dart';
import 'package:stay_nest/widgets/request_activity_card.dart';

void main() {
  testWidgets('activity card shows unread and scheduled visit information',
      (tester) async {
    final visit = DateTime(2026, 9, 1, 10, 30);
    final inquiry = InquiryModel(
      id: 'visit',
      roomId: 'room',
      customerId: 'customer',
      ownerId: 'owner',
      type: InquiryModel.visitRequestType,
      message: 'Can I visit?',
      status: InquiryModel.acceptedStatus,
      hiddenByCustomer: false,
      roomTitle: 'Campus Room',
      roomLocation: 'Kathmandu',
      customerDisplayName: 'Student',
      scheduledVisitAt: visit,
      updatedAt: visit,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RequestActivityCard(
          inquiry: inquiry,
          unread: true,
          description: inquiry.customerActivityDescription,
          activityAt: inquiry.updatedAt,
        ),
      ),
    ));

    expect(find.text('Campus Room'), findsOneWidget);
    expect(find.text('Your visit has been scheduled.'), findsOneWidget);
    expect(find.text('Visit Request · Accepted'), findsOneWidget);
    expect(find.text('Your visit is confirmed'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
  });
}
