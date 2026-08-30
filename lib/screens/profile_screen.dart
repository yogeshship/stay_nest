import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/saved_rooms_service.dart';
import '../services/inquiry_service.dart';
import '../models/inquiry_model.dart';
import 'saved_screen.dart';
import 'activity_screen.dart';
import 'trust_verification_screen.dart';
import 'help_support_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
          "Customer Profile",
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
          const _CustomerProfileIdentity(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SavedRoomCount(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CustomerInquiryCount(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProfileOption(
            icon: Icons.favorite_border,
            title: "Saved Rooms",
            subtitle: "View rooms you shortlisted",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedScreen()),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.notifications_outlined,
            title: "Activity",
            subtitle: "Track inquiry and visit updates",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActivityScreen()),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.verified_user_outlined,
            title: "Trust & Verification",
            subtitle: "How StayNest verifies listings",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrustVerificationScreen(),
                ),
              );
            },
          ),
          _ProfileOption(
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
          _ProfileOption(
            icon: Icons.logout,
            title: "Logout",
            subtitle: "Sign out from your account",
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

class _SavedRoomCount extends StatefulWidget {
  @override
  State<_SavedRoomCount> createState() => _SavedRoomCountState();
}

class _CustomerInquiryCount extends StatefulWidget {
  @override
  State<_CustomerInquiryCount> createState() => _CustomerInquiryCountState();
}

class _CustomerInquiryCountState extends State<_CustomerInquiryCount> {
  late final Stream<List<InquiryModel>> _inquiriesStream;

  @override
  void initState() {
    super.initState();
    _inquiriesStream = InquiryService().watchCustomerInquiries();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InquiryModel>>(
      stream: _inquiriesStream,
      builder: (context, snapshot) => _ProfileStatCard(
        title: 'Unread',
        value: snapshot.hasError
            ? '—'
            : '${snapshot.data?.where((item) => item.isUnreadForCustomer).length ?? 0}',
      ),
    );
  }
}

class _SavedRoomCountState extends State<_SavedRoomCount> {
  late final Stream<Set<String>> _savedRoomIdsStream;

  @override
  void initState() {
    super.initState();
    _savedRoomIdsStream = SavedRoomsService().watchSavedRoomIds();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: _savedRoomIdsStream,
      builder: (context, snapshot) {
        return _ProfileStatCard(
          title: 'Saved',
          value: snapshot.hasError ? '—' : '${snapshot.data?.length ?? 0}',
        );
      },
    );
  }
}

class _CustomerProfileIdentity extends StatelessWidget {
  const _CustomerProfileIdentity();

  @override
  Widget build(BuildContext context) {
    final firebaseUser = AuthService().currentUser;
    if (firebaseUser == null) return const SizedBox.shrink();

    return StreamBuilder(
      stream: UserService().watchUserProfile(firebaseUser.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.fullName.isNotEmpty == true
            ? profile!.fullName
            : 'Customer';
        final detail = profile?.phoneNumber.isNotEmpty == true
            ? profile!.phoneNumber
            : firebaseUser.email ?? 'StayNest customer';

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

class _ProfileStatCard extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileStatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfileScreen.primaryColor,
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

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileOption({
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
            Icon(icon, color: ProfileScreen.primaryColor),
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
