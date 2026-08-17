import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
          "Help & Support",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _SupportCard(
            icon: Icons.help_outline,
            title: "How StayNest Works",
            text:
                "Students find rooms, send inquiries, and StayNest coordinates the next step safely.",
          ),
          _SupportCard(
            icon: Icons.home_work_outlined,
            title: "For Room Owners",
            text:
                "Owner verification requests are reviewed by trusted StayNest project administration.",
          ),
          _SupportCard(
            icon: Icons.report_problem_outlined,
            title: "Report a Problem",
            text:
                "If a listing looks fake, unsafe, or incorrect, contact StayNest support immediately.",
          ),
          _SupportCard(
            icon: Icons.email_outlined,
            title: "Email Support",
            text: "support@staynest.com",
          ),
          _SupportCard(
            icon: Icons.phone_outlined,
            title: "Support Phone",
            text: "+977 98XXXXXXXX",
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _SupportCard({
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
          Icon(icon, color: HelpSupportScreen.primaryColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(text,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
