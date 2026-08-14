import 'package:flutter/material.dart';
import '../services/inquiry_service.dart';
import '../models/inquiry_model.dart';
import '../widgets/scheduled_visit_card.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  static const Color bgColor = Color(0xFFF8F7FC);
  static const Color primaryColor = Color(0xFF6C3BFF);

  @override
  Widget build(BuildContext context) {
    final requests = InquiryService.inquiries
        .where((inquiry) => inquiry.isVisibleToCustomer)
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          "My Room Requests",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: requests.isEmpty
          ? const Center(
              child: Text(
                "No room requests yet",
                style: TextStyle(color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return _RequestCard(inquiry: requests[index]);
              },
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final InquiryModel inquiry;

  const _RequestCard({required this.inquiry});

  Color getStatusColor() {
    if (inquiry.status == "Accepted") return Colors.green;
    if (inquiry.status == "Rejected") return Colors.red;
    if (inquiry.status == "Visit Scheduled") return Colors.orange;
    if (inquiry.status == "Completed") return Colors.blue;
    return MyRequestsScreen.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
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
          Text(inquiry.roomTitle,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(inquiry.roomLocation,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(inquiry.type),
          const SizedBox(height: 10),
          Text(
            inquiry.status,
            style: TextStyle(
              color: getStatusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (inquiry.scheduledVisit != null) ...[
            const SizedBox(height: 14),
            ScheduledVisitCard(scheduledVisit: inquiry.scheduledVisit!),
          ],
          const SizedBox(height: 6),
          Text(
            "Requested at ${inquiry.time}",
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
