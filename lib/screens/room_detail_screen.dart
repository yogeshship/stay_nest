import 'package:flutter/material.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';

class RoomDetailScreen extends StatelessWidget {
  final String imagePath;
  final String title;
  final String location;
  final String price;
  final String gender;
  final String description;
  final bool isAvailable;
  final String ownerName;
  final String ownerPhone;

  const RoomDetailScreen({
    super.key,
    required this.imagePath,
    required this.title,
    required this.location,
    required this.price,
    required this.gender,
    required this.description,
    required this.isAvailable,
    required this.ownerName,
    required this.ownerPhone,
  });

  void _sendInquiry(BuildContext context, String type) {
    final inquiry = InquiryModel(
      customerName: "Customer User",
      roomTitle: title,
      roomLocation: location,
      type: type,
      message: type == "Visit Request"
          ? "Customer requested to visit this room."
          : "Customer sent an inquiry about this room.",
      time: TimeOfDay.now().format(context),
    );

    InquiryService.addInquiry(inquiry);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$type sent to StayNest team"),
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
                Image.asset(
                  imagePath,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
                    label: Text(isAvailable ? "Available" : "Occupied"),
                    backgroundColor: isAvailable
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    title,
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
                      Expanded(child: Text(location)),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C3BFF),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    "Gender Preference: $gender",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Verified Owner",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFEDE7FF),
                          child: Icon(
                            Icons.verified_user,
                            color: Color(0xFF6C3BFF),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            ownerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text(
                          "Verified",
                          style: TextStyle(
                            color: Color(0xFF6C3BFF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    description,
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
                          onPressed: isAvailable
                              ? () => _sendInquiry(context, "Visit Request")
                              : null,
                          icon: const Icon(Icons.calendar_month),
                          label: const Text("Request Visit"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C3BFF),
                          ),
                          onPressed: isAvailable
                              ? () => _sendInquiry(context, "Inquiry")
                              : null,
                          icon: const Icon(Icons.message, color: Colors.white),
                          label: const Text(
                            "Send Inquiry",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Owner contact details are protected. StayNest will coordinate after inquiry approval.",
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