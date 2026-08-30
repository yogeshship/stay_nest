import 'package:flutter/material.dart';

import '../models/inquiry_model.dart';
import 'scheduled_visit_card.dart';

class RequestActivityCard extends StatelessWidget {
  const RequestActivityCard({
    super.key,
    required this.inquiry,
    required this.unread,
    required this.description,
    required this.activityAt,
    this.onTap,
    this.trailing,
  });

  final InquiryModel inquiry;
  final bool unread;
  final String description;
  final DateTime? activityAt;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: unread ? const Color(0xFFF1EDFF) : Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      elevation: unread ? 1 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unread) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: Color(0xFF6C3BFF),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inquiry.roomTitle,
                          style: TextStyle(
                            fontWeight:
                                unread ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          inquiry.roomLocation,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activityAt != null)
                    Text(
                      _activityTime(context, activityAt!),
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(description),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusChip(inquiry: inquiry),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
              if (inquiry.type == InquiryModel.visitRequestType &&
                  inquiry.status == InquiryModel.acceptedStatus &&
                  inquiry.scheduledVisitAt != null) ...[
                const SizedBox(height: 14),
                ScheduledVisitCard(scheduledVisit: inquiry.scheduledVisitAt!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.inquiry});

  final InquiryModel inquiry;

  @override
  Widget build(BuildContext context) {
    final color = switch (inquiry.status) {
      InquiryModel.acceptedStatus => Colors.green,
      InquiryModel.declinedStatus => Colors.red,
      InquiryModel.completedStatus => Colors.blue,
      InquiryModel.cancelledStatus => Colors.grey,
      _ => const Color(0xFF6C3BFF),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${inquiry.typeLabel} · ${inquiry.statusLabel}',
        style:
            TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

String _activityTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return TimeOfDay.fromDateTime(local).format(context);
  }
  return MaterialLocalizations.of(context).formatShortDate(local);
}
