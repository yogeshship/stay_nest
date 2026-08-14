import 'package:flutter/material.dart';
import '../services/inquiry_service.dart';
import '../models/inquiry_model.dart';

class InquiriesScreen extends StatefulWidget {
  const InquiriesScreen({super.key});

  static const Color bgColor = Color(0xFFF8F7FC);
  static const Color primaryColor = Color(0xFF6C3BFF);

  @override
  State<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends State<InquiriesScreen> {
  void updateInquiryStatus(int index, String status) {
    setState(() {
      InquiryService.updateStatus(index, status);
    });
  }

  Future<void> scheduleVisit(int index) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
      helpText: "SELECT VISIT DATE",
      cancelText: "CANCEL",
      confirmText: "NEXT",
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: "SELECT VISIT TIME",
      cancelText: "CANCEL",
      confirmText: "SCHEDULE",
    );
    if (time == null || !mounted) return;

    final scheduledVisit = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() => InquiryService.scheduleVisit(index, scheduledVisit));

    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(date);
    final timeLabel = time.format(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Visit scheduled for $dateLabel at $timeLabel"),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inquiries = InquiryService.inquiries;

    return Scaffold(
      backgroundColor: InquiriesScreen.bgColor,
      appBar: AppBar(
        backgroundColor: InquiriesScreen.bgColor,
        elevation: 0,
        title: const Text(
          "Inquiries",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: inquiries.isEmpty
          ? const Center(
              child: Text(
                "No inquiries yet",
                style: TextStyle(color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: inquiries.length,
              itemBuilder: (context, index) {
                return _InquiryCard(
                  inquiry: inquiries[index],
                  onAccept: () => updateInquiryStatus(index, "Accepted"),
                  onReject: () => updateInquiryStatus(index, "Rejected"),
                  onSchedule: () => scheduleVisit(index),
                  onComplete: () => updateInquiryStatus(index, "Completed"),
                );
              },
            ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final InquiryModel inquiry;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onSchedule;
  final VoidCallback onComplete;

  const _InquiryCard({
    required this.inquiry,
    required this.onAccept,
    required this.onReject,
    required this.onSchedule,
    required this.onComplete,
  });

  Color getStatusColor() {
    if (inquiry.status == "Accepted") return Colors.green;
    if (inquiry.status == "Rejected") return Colors.red;
    if (inquiry.status == "Visit Scheduled") return Colors.orange;
    if (inquiry.status == "Completed") return Colors.blue;
    return InquiriesScreen.primaryColor;
  }

  String getStatusMessage() {
    if (inquiry.status == "Accepted") {
      return "Accepted — StayNest will coordinate visit with customer.";
    }
    if (inquiry.status == "Rejected") {
      return "Rejected — This inquiry is closed.";
    }
    if (inquiry.status == "Visit Scheduled") {
      return "Visit confirmed — Please be available at the scheduled time.";
    }
    if (inquiry.status == "Completed") {
      return "Completed — Visit process has been completed.";
    }
    return "Pending — Waiting for owner response.";
  }

  @override
  Widget build(BuildContext context) {
    final bool isPending = inquiry.status == "Pending";
    final bool isAccepted = inquiry.status == "Accepted";
    final bool isScheduled = inquiry.status == "Visit Scheduled";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEDE7FF),
                child: Icon(Icons.person, color: InquiriesScreen.primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inquiry.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(inquiry.roomTitle,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(inquiry.roomLocation,
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                inquiry.time,
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            inquiry.type,
            style: const TextStyle(
              color: InquiriesScreen.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(inquiry.message),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: getStatusColor().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              inquiry.status,
              style: TextStyle(
                color: getStatusColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            getStatusMessage(),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          if (inquiry.scheduledVisit != null) ...[
            const SizedBox(height: 14),
            _ScheduleSummary(scheduledVisit: inquiry.scheduledVisit!),
          ],
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: InquiriesScreen.primaryColor,
                    ),
                    onPressed: onAccept,
                    child: const Text("Accept",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
          if (isAccepted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: onSchedule,
                child: const Text(
                  "Schedule Visit",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
          if (isScheduled) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: onComplete,
                child: const Text(
                  "Mark Completed",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleSummary extends StatelessWidget {
  final DateTime scheduledVisit;

  const _ScheduleSummary({required this.scheduledVisit});

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatFullDate(scheduledVisit);
    final time = TimeOfDay.fromDateTime(scheduledVisit).format(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD58A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Scheduled visit",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: InquiriesScreen.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
