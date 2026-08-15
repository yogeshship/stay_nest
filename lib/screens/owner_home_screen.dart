import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/inquiry_model.dart';
import '../services/room_service.dart';
import '../services/inquiry_service.dart';
import 'add_room_screen.dart';
import 'my_listings_screen.dart';
import 'inquiries_screen.dart';
import 'owner_profile_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  late final Stream<List<RoomModel>> _roomsStream;
  late final Stream<List<InquiryModel>> _inquiriesStream;

  @override
  void initState() {
    super.initState();
    _roomsStream = RoomService().watchOwnerRooms();
    _inquiriesStream = InquiryService().watchOwnerInquiries();
  }

  Future<void> openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwnerHomeScreen.bgColor,
      appBar: AppBar(
        backgroundColor: OwnerHomeScreen.bgColor,
        elevation: 0,
        title: const Text(
          "Owner Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StreamBuilder<List<RoomModel>>(
            stream: _roomsStream,
            builder: (context, snapshot) {
              final rooms = snapshot.data ?? const <RoomModel>[];
              return StreamBuilder<List<InquiryModel>>(
                stream: _inquiriesStream,
                builder: (context, inquirySnapshot) => _StatsCard(
                  listingCount: rooms.length,
                  availableCount:
                      rooms.where((room) => room.isAvailable).length,
                  inquiryCount: inquirySnapshot.data?.length ?? 0,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _OwnerActionCard(
            icon: Icons.add_home_work_rounded,
            title: "Add Room",
            subtitle: "Post a new room or hostel listing",
            onTap: () => openScreen(const AddRoomScreen()),
          ),
          _OwnerActionCard(
            icon: Icons.home_work_outlined,
            title: "My Listings",
            subtitle: "Manage your added rooms",
            onTap: () => openScreen(const MyListingsScreen()),
          ),
          _OwnerActionCard(
            icon: Icons.chat_bubble_outline,
            title: "Inquiries",
            subtitle: "View messages from students",
            onTap: () => openScreen(const InquiriesScreen()),
          ),
          _OwnerActionCard(
            icon: Icons.person_outline,
            title: "Owner Profile",
            subtitle: "Manage account and contact details",
            onTap: () => openScreen(const OwnerProfileScreen()),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int listingCount;
  final int availableCount;
  final int inquiryCount;

  const _StatsCard({
    required this.listingCount,
    required this.availableCount,
    required this.inquiryCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: OwnerHomeScreen.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(title: "Listings", value: listingCount.toString()),
          _StatItem(title: "Available", value: availableCount.toString()),
          _StatItem(title: "Inquiries", value: inquiryCount.toString()),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _OwnerActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OwnerActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: OwnerHomeScreen.primaryColor, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
