import 'package:flutter/material.dart';
import '../services/inquiry_service.dart';
import '../models/inquiry_model.dart';
import '../widgets/scheduled_visit_card.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  static const Color bgColor = Color(0xFFF8F7FC);
  static const Color primaryColor = Color(0xFF6C3BFF);

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late final Stream<List<InquiryModel>> _inquiriesStream;

  @override
  void initState() {
    super.initState();
    _inquiriesStream = InquiryService().watchCustomerInquiries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyRequestsScreen.bgColor,
      appBar: AppBar(
        backgroundColor: MyRequestsScreen.bgColor,
        elevation: 0,
        title: const Text(
          "My Room Requests",
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
            return const Center(child: Text('Requests could not be loaded.'));
          }
          final requests = snapshot.data ?? const <InquiryModel>[];
          if (requests.isEmpty) {
            return const Center(child: Text('No room requests yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (context, index) =>
                _RequestCard(inquiry: requests[index]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final InquiryModel inquiry;

  const _RequestCard({required this.inquiry});

  Color getStatusColor() {
    if (inquiry.status == InquiryModel.acceptedStatus) return Colors.green;
    if (inquiry.status == InquiryModel.declinedStatus) return Colors.red;
    if (inquiry.status == InquiryModel.completedStatus) return Colors.blue;
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
          Text(inquiry.typeLabel),
          const SizedBox(height: 10),
          Text(
            inquiry.statusLabel,
            style: TextStyle(
              color: getStatusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (inquiry.scheduledVisitAt != null) ...[
            const SizedBox(height: 14),
            ScheduledVisitCard(scheduledVisit: inquiry.scheduledVisitAt!),
          ],
          const SizedBox(height: 6),
          Text(
            inquiry.createdAt == null
                ? 'Sending…'
                : 'Requested ${MaterialLocalizations.of(context).formatMediumDate(inquiry.createdAt!.toLocal())}',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
