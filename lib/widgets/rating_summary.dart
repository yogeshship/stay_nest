import 'package:flutter/material.dart';

import '../models/review_model.dart';

class RatingSummaryWidget extends StatelessWidget {
  const RatingSummaryWidget({super.key, required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.reviewCount == 0) {
      return const Text('No ratings yet', key: Key('rating-summary-empty'));
    }
    return Row(
      key: const Key('rating-summary-value'),
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber),
        const SizedBox(width: 6),
        Text(
          '${summary.averageRating.toStringAsFixed(1)} '
          '(${summary.reviewCount} ${summary.reviewCount == 1 ? 'review' : 'reviews'})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
