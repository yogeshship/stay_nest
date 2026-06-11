import 'package:flutter/material.dart';

class TrustVerificationScreen extends StatelessWidget {
  const TrustVerificationScreen({super.key});

  static const Color bgColor = Color(0xFFF8F7FC);
  static const Color primaryColor = Color(0xFF6C3BFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          "Trust & Verification",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _TrustCard(
            icon: Icons.verified_user,
            title: "Verified Owners Only",
            text:
            "Owners cannot directly sign up. StayNest verifies property owners before giving access.",
          ),
          _TrustCard(
            icon: Icons.home_work_outlined,
            title: "Room Listing Review",
            text:
            "Room details, location, rent, and photos are reviewed before listings are trusted.",
          ),
          _TrustCard(
            icon: Icons.phone_locked_outlined,
            title: "Protected Contact Details",
            text:
            "Owner phone numbers are not shown directly to prevent fake deals and unsafe contact.",
          ),
          _TrustCard(
            icon: Icons.chat_bubble_outline,
            title: "Inquiry Through StayNest",
            text:
            "Students send inquiries and visit requests through StayNest so the process can be tracked.",
          ),
          _TrustCard(
            icon: Icons.school_outlined,
            title: "Student-Focused Housing",
            text:
            "StayNest focuses on rooms and hostels suitable for students near colleges.",
          ),
        ],
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TrustCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: TrustVerificationScreen.primaryColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}