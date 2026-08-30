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
  late final InquiryService _inquiryService;
  late final Stream<List<InquiryModel>> _inquiriesStream;

  @override
  void initState() {
    super.initState();
    _inquiryService = InquiryService();
    _inquiriesStream = _inquiryService.watchOwnerInquiries();
  }

  Future<void> updateInquiryStatus(String inquiryId, String status) async {
    try {
      await _inquiryService.updateStatus(
        inquiryId: inquiryId,
        status: status,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyInquiryError(error))),
      );
    }
  }

  Future<void> markRead(InquiryModel inquiry) async {
    if (!inquiry.isUnreadForOwner) return;
    try {
      await _inquiryService.markOwnerRead(inquiry.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyInquiryError(error))),
      );
    }
  }

  Future<void> markAllRead(List<InquiryModel> inquiries) async {
    try {
      await _inquiryService.markOwnerInquiriesRead(inquiries);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyInquiryError(error))),
      );
    }
  }

  Future<void> scheduleVisit(String inquiryId) async {
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

    try {
      await _inquiryService.scheduleVisit(
        inquiryId: inquiryId,
        scheduledVisitAt: scheduledVisit,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyInquiryError(error))),
      );
      return;
    }

    if (!mounted) return;

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
      body: StreamBuilder<List<InquiryModel>>(
        stream: _inquiriesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Inquiries could not be loaded.'));
          }
          final inquiries = snapshot.data ?? const <InquiryModel>[];
          if (inquiries.isEmpty) {
            return const Center(child: Text('No inquiries yet'));
          }
          final pendingCount = pendingOwnerInquiryCount(inquiries);
          final unreadCount = unreadOwnerInquiryCount(inquiries);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$pendingCount pending · $unreadCount unread',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () => markAllRead(inquiries),
                      child: const Text('Mark all as read'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              for (final inquiry in inquiries)
                _InquiryCard(
                  inquiry: inquiry,
                  onRead: () => markRead(inquiry),
                  onAccept: () => updateInquiryStatus(
                    inquiry.id,
                    InquiryModel.acceptedStatus,
                  ),
                  onReject: () => updateInquiryStatus(
                    inquiry.id,
                    InquiryModel.declinedStatus,
                  ),
                  onSchedule: () => scheduleVisit(inquiry.id),
                  onComplete: () => updateInquiryStatus(
                    inquiry.id,
                    InquiryModel.completedStatus,
                  ),
                ),
            ],
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
  final VoidCallback onRead;

  const _InquiryCard({
    required this.inquiry,
    required this.onAccept,
    required this.onReject,
    required this.onSchedule,
    required this.onComplete,
    required this.onRead,
  });

  Color getStatusColor() {
    if (inquiry.status == InquiryModel.acceptedStatus) return Colors.green;
    if (inquiry.status == InquiryModel.declinedStatus) return Colors.red;
    if (inquiry.status == InquiryModel.completedStatus) return Colors.blue;
    return InquiriesScreen.primaryColor;
  }

  String getStatusMessage() {
    if (inquiry.status == InquiryModel.acceptedStatus) {
      return "Accepted — StayNest will coordinate visit with customer.";
    }
    if (inquiry.status == InquiryModel.declinedStatus) {
      return "Declined — This inquiry is closed.";
    }
    if (inquiry.status == InquiryModel.completedStatus) {
      return "Completed — Visit process has been completed.";
    }
    return "Pending — Waiting for owner response.";
  }

  @override
  Widget build(BuildContext context) {
    final bool isPending = inquiry.status == InquiryModel.pendingStatus;
    final bool canSchedule = inquiry.status == InquiryModel.acceptedStatus &&
        inquiry.type == InquiryModel.visitRequestType;
    final bool canComplete = inquiry.status == InquiryModel.acceptedStatus &&
        (inquiry.type == InquiryModel.inquiryType ||
            inquiry.scheduledVisitAt != null);

    return GestureDetector(
      onTap: onRead,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              inquiry.isUnreadForOwner ? const Color(0xFFF1EDFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (inquiry.isUnreadForOwner) ...[
                  const CircleAvatar(
                    radius: 5,
                    backgroundColor: InquiriesScreen.primaryColor,
                  ),
                  const SizedBox(width: 10),
                ],
                const CircleAvatar(
                  backgroundColor: Color(0xFFEDE7FF),
                  child:
                      Icon(Icons.person, color: InquiriesScreen.primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inquiry.customerDisplayName,
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
                  inquiry.createdAt == null
                      ? 'New'
                      : TimeOfDay.fromDateTime(inquiry.createdAt!.toLocal())
                          .format(context),
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              inquiry.typeLabel,
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
                inquiry.statusLabel,
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
            if (inquiry.scheduledVisitAt != null) ...[
              const SizedBox(height: 14),
              _ScheduleSummary(scheduledVisit: inquiry.scheduledVisitAt!),
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
            if (canSchedule) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: onSchedule,
                  child: Text(
                    inquiry.scheduledVisitAt == null
                        ? "Schedule Visit"
                        : "Change Visit Time",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
            if (canComplete) ...[
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
