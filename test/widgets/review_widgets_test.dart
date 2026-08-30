import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/review_model.dart';
import 'package:stay_nest/widgets/rating_summary.dart';
import 'package:stay_nest/widgets/review_card.dart';
import 'package:stay_nest/widgets/review_editor.dart';

ReviewModel review({int rating = 4, DateTime? updatedAt}) => ReviewModel(
      id: 'customer_room',
      roomId: 'room',
      customerId: 'customer',
      eligibilityInquiryId: 'visit',
      rating: rating,
      reviewText: 'A clear review',
      reviewerDisplayName: 'A Customer',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime.utc(2026, 1, 1),
    );

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('rating summary renders empty and fractional states',
      (tester) async {
    await tester.pumpWidget(app(const RatingSummaryWidget(
      summary: ReviewSummary(averageRating: 0, reviewCount: 0),
    )));
    expect(find.byKey(const Key('rating-summary-empty')), findsOneWidget);
    await tester.pumpWidget(app(const RatingSummaryWidget(
      summary: ReviewSummary(averageRating: 4.5, reviewCount: 2),
    )));
    expect(find.text('4.5 (2 reviews)'), findsOneWidget);
  });

  testWidgets('review card shows stars, text, date, and edited indicator',
      (tester) async {
    await tester.pumpWidget(app(ReviewCard(
      review: review(updatedAt: DateTime.utc(2026, 1, 2)),
    )));
    expect(find.text('A Customer'), findsOneWidget);
    expect(find.text('A clear review'), findsOneWidget);
    expect(find.textContaining('Edited'), findsOneWidget);
  });

  testWidgets('editor validates stars, prefills edit, and trims submission',
      (tester) async {
    int? rating;
    String? text;
    await tester.pumpWidget(app(ReviewEditor(
      existingReview: review(),
      onSubmit: (value, reviewText) async {
        rating = value;
        text = reviewText;
      },
    )));
    expect(find.text('A clear review'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('review-text-field')), '  Updated  ');
    await tester.tap(find.byKey(const Key('review-star-5')));
    await tester.tap(find.byKey(const Key('submit-review-button')));
    await tester.pumpAndSettle();
    expect(rating, 5);
    expect(text, 'Updated');
  });

  testWidgets('editor disables duplicate submit', (tester) async {
    final completer = Completer<void>();
    var submits = 0;
    await tester.pumpWidget(app(ReviewEditor(
      existingReview: review(),
      onSubmit: (_, __) {
        submits++;
        return completer.future;
      },
    )));
    await tester.tap(find.byKey(const Key('submit-review-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit-review-button')));
    expect(submits, 1);
    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('editor confirms deletion', (tester) async {
    var deletes = 0;
    await tester.pumpWidget(app(ReviewEditor(
      existingReview: review(),
      onSubmit: (_, __) async {},
      onDelete: () async {
        deletes++;
      },
    )));
    await tester.tap(find.byKey(const Key('delete-review-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(deletes, 1);
  });
}
