import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';
import '../services/inquiry_service.dart';
import '../models/inquiry_model.dart';
import 'my_listings_screen.dart';
import 'inquiries_screen.dart';
import 'help_support_screen.dart';
import 'welcome_screen.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          "Owner Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundColor: primaryColor,
            child: Icon(Icons.person, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 14),
          const _OwnerProfileIdentity(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _OwnerListingCount(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OwnerInquiryCount(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _OwnerProfileOption(
            icon: Icons.home_work_outlined,
            title: "My Listings",
            subtitle: "View and manage your rooms",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyListingsScreen()),
              );
            },
          ),
          _OwnerProfileOption(
            icon: Icons.chat_bubble_outline,
            title: "Inquiries",
            subtitle: "Manage customer requests",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InquiriesScreen()),
              );
            },
          ),
          const _OwnerVerificationStatusOption(),
          const _OwnerProfileOption(
            icon: Icons.business_outlined,
            title: "Business Details",
            subtitle: "Manage property owner information",
          ),
          _OwnerProfileOption(
            icon: Icons.help_outline,
            title: "Help & Support",
            subtitle: "Get support from StayNest team",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          _OwnerProfileOption(
            icon: Icons.logout,
            title: "Logout",
            subtitle: "Sign out from owner account",
            onTap: () async {
              try {
                await AuthService().signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              } on FirebaseAuthException catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(friendlyAuthError(error))),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _OwnerListingCount extends StatefulWidget {
  @override
  State<_OwnerListingCount> createState() => _OwnerListingCountState();
}

class _OwnerInquiryCount extends StatefulWidget {
  @override
  State<_OwnerInquiryCount> createState() => _OwnerInquiryCountState();
}

class _OwnerInquiryCountState extends State<_OwnerInquiryCount> {
  late final Stream<List<InquiryModel>> _inquiriesStream;

  @override
  void initState() {
    super.initState();
    _inquiriesStream = InquiryService().watchOwnerInquiries();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InquiryModel>>(
      stream: _inquiriesStream,
      builder: (context, snapshot) => _OwnerStatCard(
        title: 'Inquiries',
        value: snapshot.hasError ? '—' : '${snapshot.data?.length ?? 0}',
      ),
    );
  }
}

class _OwnerListingCountState extends State<_OwnerListingCount> {
  late final Stream<List<RoomModel>> _roomsStream;

  @override
  void initState() {
    super.initState();
    _roomsStream = RoomService().watchOwnerRooms();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomModel>>(
      stream: _roomsStream,
      builder: (context, snapshot) {
        return _OwnerStatCard(
          title: 'Listings',
          value: snapshot.hasError ? '—' : '${snapshot.data?.length ?? 0}',
        );
      },
    );
  }
}

class _OwnerProfileIdentity extends StatelessWidget {
  const _OwnerProfileIdentity();

  @override
  Widget build(BuildContext context) {
    final firebaseUser = AuthService().currentUser;
    if (firebaseUser == null) return const SizedBox.shrink();

    return StreamBuilder(
      stream: UserService().watchUserProfile(firebaseUser.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name =
            profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Owner';
        final detail = profile?.phoneNumber.isNotEmpty == true
            ? profile!.phoneNumber
            : firebaseUser.email ?? 'StayNest owner';

        return Column(
          children: [
            Center(
              child: Text(
                name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OwnerVerificationStatusOption extends StatelessWidget {
  const _OwnerVerificationStatusOption();

  @override
  Widget build(BuildContext context) {
    final firebaseUser = AuthService().currentUser;
    if (firebaseUser == null) return const SizedBox.shrink();

    return StreamBuilder(
      stream: UserService().watchUserProfile(firebaseUser.uid),
      builder: (context, snapshot) {
        final status = snapshot.data?.verificationStatus ?? 'Unavailable';
        return _OwnerProfileOption(
          icon: Icons.verified_user_outlined,
          title: 'Verification Status',
          subtitle: status,
        );
      },
    );
  }
}

class _OwnerStatCard extends StatelessWidget {
  final String title;
  final String value;

  const _OwnerStatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OwnerProfileScreen.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
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
      ),
    );
  }
}

class _OwnerProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OwnerProfileOption({
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: OwnerProfileScreen.primaryColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
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
