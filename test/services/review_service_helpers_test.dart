import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/inquiry_model.dart';
import 'package:stay_nest/services/review_service.dart';

InquiryModel inquiry({
  required String id,
  String customer = 'customer',
  String room = 'room',
  String type = InquiryModel.visitRequestType,
  String status = InquiryModel.completedStatus,
  DateTime? createdAt,
  DateTime? updatedAt,
}) =>
    InquiryModel(
      id: id,
      roomId: room,
      customerId: customer,
      ownerId: 'owner',
      type: type,
      message: 'message',
      status: status,
      hiddenByCustomer: false,
      roomTitle: 'Room',
      roomLocation: 'Location',
      customerDisplayName: 'Customer',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

void main() {
  test('validation trims text and enforces rating and text bounds', () {
    expect(validateReviewInput(rating: 5, reviewText: '  useful  '), 'useful');
    expect(() => validateReviewInput(rating: 0, reviewText: 'x'),
        throwsArgumentError);
    expect(() => validateReviewInput(rating: 6, reviewText: 'x'),
        throwsArgumentError);
    expect(() => validateReviewInput(rating: 3, reviewText: '   '),
        throwsArgumentError);
    expect(
      () => validateReviewInput(
        rating: 3,
        reviewText: List.filled(1001, 'x').join(),
      ),
      throwsArgumentError,
    );
  });

  test('review IDs validate and are deterministic', () {
    expect(ReviewService.reviewId('customer', 'room'), 'customer_room');
    for (final invalid in ['', 'bad/id', 'x' * 129]) {
      expect(() => validateReviewIdPart(invalid, 'ID'), throwsArgumentError);
    }
  });

  test('only completed matching visit requests are eligible', () {
    expect(
        selectReviewEligibility([inquiry(id: 'valid')],
                customerId: 'customer', roomId: 'room')
            ?.id,
        'valid');
    for (final invalid in [
      inquiry(id: 'ordinary', type: InquiryModel.inquiryType),
      inquiry(id: 'pending', status: InquiryModel.pendingStatus),
      inquiry(id: 'accepted', status: InquiryModel.acceptedStatus),
      inquiry(id: 'declined', status: InquiryModel.declinedStatus),
      inquiry(id: 'wrong-room', room: 'other'),
      inquiry(id: 'wrong-customer', customer: 'other'),
    ]) {
      expect(
          selectReviewEligibility([invalid],
              customerId: 'customer', roomId: 'room'),
          isNull);
    }
  });

  test('eligibility selects newest updated, then created, then ID', () {
    final base = DateTime.utc(2026, 1, 1);
    final selected = selectReviewEligibility([
      inquiry(id: 'old', updatedAt: base.add(const Duration(days: 1))),
      inquiry(
          id: 'b',
          updatedAt: base.add(const Duration(days: 2)),
          createdAt: base),
      inquiry(
          id: 'a',
          updatedAt: base.add(const Duration(days: 2)),
          createdAt: base),
    ], customerId: 'customer', roomId: 'room');
    expect(selected?.id, 'a');

    final byCreated = selectReviewEligibility([
      inquiry(id: 'older-created', createdAt: base),
      inquiry(
          id: 'newer-created', createdAt: base.add(const Duration(hours: 1))),
    ], customerId: 'customer', roomId: 'room');
    expect(byCreated?.id, 'newer-created');
  });
}
