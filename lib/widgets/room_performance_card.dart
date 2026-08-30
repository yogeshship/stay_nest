import 'package:flutter/material.dart';

import '../models/owner_analytics.dart';

class RoomPerformanceCard extends StatelessWidget {
  const RoomPerformanceCard({
    super.key,
    required this.performance,
    this.reviewsAvailable = true,
  });

  final RoomPerformance performance;
  final bool reviewsAvailable;

  @override
  Widget build(BuildContext context) {
    final room = performance.room;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        room.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(room.isAvailable ? 'Available' : 'Unavailable'),
                  labelStyle: TextStyle(
                    color:
                        room.isAvailable ? Colors.green.shade800 : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _Metric('Requests', performance.totalRequests.toString()),
                _Metric('Pending', performance.pendingRequests.toString()),
                _Metric(
                  'Completed visits',
                  performance.completedVisitCount.toString(),
                ),
                _Metric(
                  'Reviews',
                  reviewsAvailable ? performance.reviewCount.toString() : '—',
                ),
                _Metric(
                  'Rating',
                  !reviewsAvailable
                      ? 'Unavailable'
                      : performance.reviewCount == 0
                          ? 'No ratings yet'
                          : performance.averageRating.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          text: '$label: ',
          style: const TextStyle(color: Colors.black54),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
