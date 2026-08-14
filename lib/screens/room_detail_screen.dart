import 'package:flutter/material.dart';

import '../models/inquiry_model.dart';
import '../models/room_model.dart';
import '../services/inquiry_service.dart';
import '../widgets/room_image.dart';

class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({
    super.key,
    required this.room,
  });

  final RoomModel room;

  void _sendInquiry(BuildContext context, String type) {
    final inquiry = InquiryModel(
      customerName: 'Customer User',
      roomTitle: room.title,
      roomLocation: room.location,
      type: type,
      message: type == 'Visit Request'
          ? 'Customer requested to visit this room.'
          : 'Customer sent an inquiry about this room.',
      time: TimeOfDay.now().format(context),
    );

    InquiryService.addInquiry(inquiry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type sent to StayNest team'),
        backgroundColor: const Color(0xFF6C3BFF),
      ),
    );
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
                  source: room.primaryImage,
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
                    label: Text(room.isAvailable ? 'Available' : 'Occupied'),
                    backgroundColor: room.isAvailable
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    room.title,
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
                      Expanded(child: Text(room.location)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Rs. ${room.formattedMonthlyRent}/month',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C3BFF),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Gender Preference: ${room.genderPreference}',
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
                    room.description,
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
                          onPressed: room.isAvailable
                              ? () => _sendInquiry(context, 'Visit Request')
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
                          onPressed: room.isAvailable
                              ? () => _sendInquiry(context, 'Inquiry')
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
