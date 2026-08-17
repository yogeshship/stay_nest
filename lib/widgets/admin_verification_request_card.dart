import 'package:flutter/material.dart';

import '../models/verification_request_model.dart';

class AdminVerificationRequestCard extends StatelessWidget {
  const AdminVerificationRequestCard({
    super.key,
    required this.request,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final VerificationRequestModel request;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final displayName = request.ownerDisplayName.trim().isEmpty
        ? 'Unnamed owner'
        : request.ownerDisplayName.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(request.ownerEmail.trim()),
            const SizedBox(height: 8),
            Text(
              'Submitted: ${formatVerificationSubmittedAt(request.submittedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isBusy ? null : onApprove,
                    child: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String formatVerificationSubmittedAt(DateTime? dateTime) {
  if (dateTime == null) return 'Pending server timestamp';
  final local = dateTime.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
