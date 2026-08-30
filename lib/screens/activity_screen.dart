import 'package:flutter/material.dart';

import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import '../widgets/request_activity_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    super.key,
    this.service,
    this.inquiriesStream,
    this.markReadOverride,
    this.markAllReadOverride,
    this.hideOverride,
  });

  final InquiryService? service;
  final Stream<List<InquiryModel>>? inquiriesStream;
  final Future<void> Function(String inquiryId)? markReadOverride;
  final Future<void> Function(List<InquiryModel> inquiries)?
      markAllReadOverride;
  final Future<void> Function(String inquiryId)? hideOverride;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  InquiryService? _service;
  late final Stream<List<InquiryModel>> _stream;

  @override
  void initState() {
    super.initState();
    if (widget.service != null ||
        widget.inquiriesStream == null ||
        widget.markReadOverride == null ||
        widget.markAllReadOverride == null ||
        widget.hideOverride == null) {
      _service = widget.service ?? InquiryService();
    }
    _stream = widget.inquiriesStream ?? _service!.watchCustomerInquiries();
  }

  Future<void> _markRead(InquiryModel inquiry) async {
    if (!inquiry.isUnreadForCustomer) return;
    try {
      await (widget.markReadOverride?.call(inquiry.id) ??
          _service!.markCustomerRead(inquiry.id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyInquiryError(error))),
      );
    }
  }

  Future<void> _markAllRead(List<InquiryModel> inquiries) async {
    try {
      await (widget.markAllReadOverride?.call(inquiries) ??
          _service!.markCustomerInquiriesRead(inquiries));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyInquiryError(error))),
      );
    }
  }

  Future<void> _removeFromActivity(InquiryModel inquiry) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from activity?'),
        content: const Text(
          'This request will be hidden from your activity list. The owner will still retain their copy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (shouldRemove != true) return;
    try {
      await (widget.hideOverride?.call(inquiry.id) ??
          _service!.hideForCustomer(inquiry.id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyInquiryError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FC),
        title: const Text('Activity'),
      ),
      body: StreamBuilder<List<InquiryModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Activity could not be loaded.'));
          }
          final inquiries = snapshot.data ?? const <InquiryModel>[];
          if (inquiries.isEmpty) {
            return const Center(
              child: Text('No request activity yet'),
            );
          }
          final unreadCount =
              inquiries.where((item) => item.isUnreadForCustomer).length;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      unreadCount == 0
                          ? 'You are all caught up'
                          : '$unreadCount unread update${unreadCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () => _markAllRead(inquiries),
                      child: const Text('Mark all as read'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              for (final inquiry in inquiries)
                RequestActivityCard(
                  inquiry: inquiry,
                  unread: inquiry.isUnreadForCustomer,
                  description: inquiry.customerActivityDescription,
                  activityAt: inquiry.updatedAt,
                  onTap: () => _markRead(inquiry),
                  trailing: PopupMenuButton<_CustomerActivityAction>(
                    tooltip: 'Activity actions',
                    onSelected: (action) {
                      switch (action) {
                        case _CustomerActivityAction.markRead:
                          _markRead(inquiry);
                          break;
                        case _CustomerActivityAction.remove:
                          _removeFromActivity(inquiry);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (inquiry.isUnreadForCustomer)
                        const PopupMenuItem(
                          value: _CustomerActivityAction.markRead,
                          child: Text('Mark as read'),
                        ),
                      const PopupMenuItem(
                        value: _CustomerActivityAction.remove,
                        child: Text('Remove from activity'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

enum _CustomerActivityAction { markRead, remove }
