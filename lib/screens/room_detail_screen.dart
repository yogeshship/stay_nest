import 'package:flutter/material.dart';

import '../models/room_model.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import '../widgets/room_image.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.room,
  });

  final RoomModel room;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final InquiryService _inquiryService = InquiryService();
  bool _isSubmitting = false;

  Future<void> _sendInquiry(String type) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _inquiryService.createInquiry(
        room: widget.room,
        type: type,
        message: type == InquiryModel.visitRequestType
            ? 'Customer requested to visit this room.'
            : 'Customer sent an inquiry about this room.',
      );
      if (!mounted) return;
      final label =
          type == InquiryModel.visitRequestType ? 'Visit request' : 'Inquiry';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label sent successfully'),
          backgroundColor: const Color(0xFF6C3BFF),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyInquiryError(error))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: ListView(
          children: [
            Stack(
              children: [
                RoomImage(
                  source: widget.room.primaryImage,
                  height: 280,
                  width: double.infinity,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(widget.room.availabilityLabel),
                    backgroundColor: widget.room.isAvailable
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                  ),
                  if (!widget.room.isAvailable) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'This room is no longer available and is not accepting new inquiries or visit requests.',
                      style: TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    widget.room.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.room.location)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Rs. ${widget.room.formattedMonthlyRent}/month',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C3BFF),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Gender Preference: ${widget.room.genderPreference}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Property Owner',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFFEDE7FF),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF6C3BFF),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'StayNest Property Owner',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.room.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.room.canCreateCustomerRequest &&
                                  !_isSubmitting
                              ? () =>
                                  _sendInquiry(InquiryModel.visitRequestType)
                              : null,
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Request Visit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C3BFF),
                          ),
                          onPressed: widget.room.canCreateCustomerRequest &&
                                  !_isSubmitting
                              ? () => _sendInquiry(InquiryModel.inquiryType)
                              : null,
                          icon: const Icon(Icons.message, color: Colors.white),
                          label: const Text(
                            'Send Inquiry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Owner contact details are protected. StayNest will coordinate after inquiry approval.',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
