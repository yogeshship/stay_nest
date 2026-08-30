import 'package:flutter/material.dart';

import '../models/review_model.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final date = review.createdAt;
    final dateLabel = date == null
        ? 'Date pending'
        : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.reviewerDisplayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('$dateLabel${review.isEdited ? ' · Edited' : ''}'),
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              label: '${review.rating} out of 5 stars',
              child: Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 19,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(review.reviewText),
          ],
        ),
      ),
    );
  }
}
