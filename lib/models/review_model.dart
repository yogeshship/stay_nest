import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.roomId,
    required this.customerId,
    required this.eligibilityInquiryId,
    required this.rating,
    required this.reviewText,
    required this.reviewerDisplayName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String roomId;
  final String customerId;
  final String eligibilityInquiryId;
  final int rating;
  final String reviewText;
  final String reviewerDisplayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isEdited =>
      createdAt != null && updatedAt != null && updatedAt!.isAfter(createdAt!);

  factory ReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) throw StateError('The review does not exist.');
    return ReviewModel.fromMap(document.id, data);
  }

  factory ReviewModel.fromMap(String id, Map<String, dynamic> data) =>
      ReviewModel(
        id: id,
        roomId: data['roomId'] as String? ?? '',
        customerId: data['customerId'] as String? ?? '',
        eligibilityInquiryId: data['eligibilityInquiryId'] as String? ?? '',
        rating: data['rating'] as int? ?? 0,
        reviewText: data['reviewText'] as String? ?? '',
        reviewerDisplayName:
            data['reviewerDisplayName'] as String? ?? 'StayNest customer',
        createdAt: _dateTime(data['createdAt']),
        updatedAt: _dateTime(data['updatedAt']),
      );

  Map<String, dynamic> toFirestore() => {
        'roomId': roomId,
        'customerId': customerId,
        'eligibilityInquiryId': eligibilityInquiryId,
        'rating': rating,
        'reviewText': reviewText,
        'reviewerDisplayName': reviewerDisplayName,
        'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
        'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      };

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class ReviewSummary {
  const ReviewSummary({required this.averageRating, required this.reviewCount});

  final double averageRating;
  final int reviewCount;

  factory ReviewSummary.fromReviews(Iterable<ReviewModel> reviews) {
    final items = reviews.toList(growable: false);
    if (items.isEmpty) {
      return const ReviewSummary(averageRating: 0, reviewCount: 0);
    }
    final total = items.fold<int>(0, (total, review) => total + review.rating);
    return ReviewSummary(
      averageRating: total / items.length,
      reviewCount: items.length,
    );
  }
}
