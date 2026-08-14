import 'package:flutter/material.dart';
import '../services/inquiry_service.dart';
import '../models/inquiry_model.dart';
import '../widgets/scheduled_visit_card.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  static const Color bgColor = Color(0xFFF8F7FC);
  static const Color primaryColor = Color(0xFF6C3BFF);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  void confirmDelete(InquiryModel inquiry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Message?"),
          content: const Text(
            "This message will be hidden from your messages.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                final originalIndex = InquiryService.inquiries.indexOf(inquiry);

                if (originalIndex != -1) {
                  setState(() {
                    InquiryService.hideFromCustomer(originalIndex);
                  });
                }

                Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inquiries = InquiryService.inquiries
        .where((inquiry) => inquiry.isVisibleToCustomer)
        .toList();

    return Scaffold(
      backgroundColor: MessagesScreen.bgColor,
      appBar: AppBar(
        backgroundColor: MessagesScreen.bgColor,
        elevation: 0,
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: inquiries.isEmpty
          ? const Center(
              child: Text(
                "No messages yet",
                style: TextStyle(color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: inquiries.length,
              itemBuilder: (context, index) {
                final inquiry = inquiries[index];

                return _MessageCard(
                  inquiry: inquiry,
                  onDelete: () => confirmDelete(inquiry),
                );
              },
            ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final InquiryModel inquiry;
  final VoidCallback onDelete;

  const _MessageCard({
    required this.inquiry,
    required this.onDelete,
  });

  Color getStatusColor() {
    switch (inquiry.status) {
      case "Accepted":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      case "Visit Scheduled":
        return Colors.orange;
      case "Completed":
        return Colors.blue;
      default:
        return MessagesScreen.primaryColor;
    }
  }

  String getMessageText() {
    switch (inquiry.status) {
      case "Accepted":
        return "Your inquiry was accepted. StayNest will coordinate the visit.";
      case "Rejected":
        return "Your inquiry was rejected.";
      case "Visit Scheduled":
        return "Your room visit has been scheduled.";
      case "Completed":
        return "Your room visit process has been completed.";
      default:
        return "Your inquiry is pending owner response.";
    }
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEDE7FF),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: MessagesScreen.primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inquiry.roomTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inquiry.roomLocation,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(getMessageText()),
                    const SizedBox(height: 8),
                    Text(
                      inquiry.status,
                      style: TextStyle(
                        color: getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    inquiry.time,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (inquiry.scheduledVisit != null) ...[
            const SizedBox(height: 14),
            ScheduledVisitCard(scheduledVisit: inquiry.scheduledVisit!),
          ],
        ],
      ),
    );
  }
}
