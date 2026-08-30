import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/review_model.dart';

ReviewModel review(int rating, {DateTime? createdAt, DateTime? updatedAt}) =>
    ReviewModel(
      id: 'customer_room',
      roomId: 'room',
      customerId: 'customer',
      eligibilityInquiryId: 'visit',
      rating: rating,
      reviewText: 'Helpful review',
      reviewerDisplayName: 'Customer',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

void main() {
  test('ReviewModel parses and serializes fields and timestamps', () {
    final date = DateTime.utc(2026, 8, 30);
    final model = ReviewModel.fromMap('customer_room', {
      'roomId': 'room',
      'customerId': 'customer',
      'eligibilityInquiryId': 'visit',
      'rating': 5,
      'reviewText': 'Excellent',
      'reviewerDisplayName': 'A Customer',
      'createdAt': Timestamp.fromDate(date),
      'updatedAt': Timestamp.fromDate(date.add(const Duration(minutes: 1))),
    });
    expect(model.rating, 5);
    expect(model.isEdited, isTrue);
    expect(model.toFirestore()['createdAt'], isA<Timestamp>());
  });

  test('ReviewModel tolerates pending server timestamps', () {
    final model = ReviewModel.fromMap('id', const {});
    expect(model.createdAt, isNull);
    expect(model.updatedAt, isNull);
    expect(model.isEdited, isFalse);
  });

  test('ReviewSummary handles empty, one, and fractional averages', () {
    expect(ReviewSummary.fromReviews([]).reviewCount, 0);
    expect(ReviewSummary.fromReviews([review(4)]).averageRating, 4);
    final summary = ReviewSummary.fromReviews([review(4), review(5)]);
    expect(summary.reviewCount, 2);
    expect(summary.averageRating, 4.5);
  });
}
