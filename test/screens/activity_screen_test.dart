import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stay_nest/models/inquiry_model.dart';
import 'package:stay_nest/screens/activity_screen.dart';

InquiryModel _activity({
  String id = 'activity',
  String type = InquiryModel.inquiryType,
  String status = InquiryModel.pendingStatus,
  DateTime? customerReadAt,
  DateTime? scheduledVisitAt,
}) {
  final createdAt = DateTime.utc(2026, 8, 20, 8);
  final updatedAt = DateTime.utc(2026, 8, 20, 9);
  return InquiryModel(
    id: id,
    roomId: 'room',
    customerId: 'customer',
    ownerId: 'owner',
    type: type,
    message: 'Is this available?',
    status: status,
    hiddenByCustomer: false,
    roomTitle: 'Test Room $id',
    roomLocation: 'Kathmandu',
    customerDisplayName: 'Student',
    createdAt: createdAt,
    updatedAt: updatedAt,
    customerReadAt: customerReadAt,
    scheduledVisitAt: scheduledVisitAt,
  );
}

Widget _screen({
  required List<InquiryModel> inquiries,
  required Future<void> Function(String) markRead,
  required Future<void> Function(List<InquiryModel>) markAll,
  required Future<void> Function(String) hide,
}) {
  return MaterialApp(
    home: ActivityScreen(
      inquiriesStream: Stream.value(inquiries),
      markReadOverride: markRead,
      markAllReadOverride: markAll,
      hideOverride: hide,
    ),
  );
}

void main() {
  testWidgets('entry does not mark activity read and tapping one item does',
      (tester) async {
    final marked = <String>[];
    final item = _activity();
    await tester.pumpWidget(_screen(
      inquiries: [item],
      markRead: (id) async => marked.add(id),
      markAll: (_) async {},
      hide: (_) async {},
    ));
    await tester.pump();

    expect(marked, isEmpty);
    await tester.tap(find.text(item.roomTitle));
    await tester.pump();
    expect(marked, [item.id]);
  });

  testWidgets('mark all receives only the currently loaded activity list',
      (tester) async {
    final items = [_activity(id: 'one'), _activity(id: 'two')];
    List<InquiryModel>? received;
    await tester.pumpWidget(_screen(
      inquiries: items,
      markRead: (_) async {},
      markAll: (value) async => received = value,
      hide: (_) async {},
    ));
    await tester.pump();

    await tester.tap(find.text('Mark all as read'));
    await tester.pump();
    expect(received, same(items));
  });

  testWidgets('remove from activity requires confirmation and invokes hide',
      (tester) async {
    String? hiddenId;
    final item = _activity();
    await tester.pumpWidget(_screen(
      inquiries: [item],
      markRead: (_) async {},
      markAll: (_) async {},
      hide: (id) async => hiddenId = id,
    ));
    await tester.pump();

    await tester.tap(find.byTooltip('Activity actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from activity'));
    await tester.pumpAndSettle();
    expect(hiddenId, isNull);
    expect(find.text('Remove from activity?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(hiddenId, item.id);
  });

  testWidgets('declined and completed activity use final-state presentation',
      (tester) async {
    final visitTime = DateTime.utc(2026, 9, 1, 10);
    final declined = _activity(
      id: 'declined',
      status: InquiryModel.declinedStatus,
    );
    final completed = _activity(
      id: 'completed',
      type: InquiryModel.visitRequestType,
      status: InquiryModel.completedStatus,
      scheduledVisitAt: visitTime,
    );
    await tester.pumpWidget(_screen(
      inquiries: [declined, completed],
      markRead: (_) async {},
      markAll: (_) async {},
      hide: (_) async {},
    ));
    await tester.pump();

    expect(find.text('Your inquiry was declined.'), findsOneWidget);
    expect(find.text('Your scheduled visit was completed.'), findsOneWidget);
    expect(find.text('Your visit is confirmed'), findsNothing);
    expect(find.text('Inquiry · Declined'), findsOneWidget);
    expect(find.text('Visit Request · Completed'), findsOneWidget);
  });
}
