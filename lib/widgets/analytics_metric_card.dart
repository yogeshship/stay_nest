import 'package:flutter/material.dart';

class AnalyticsMetricCard extends StatelessWidget {
  const AnalyticsMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9E4F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF6C3BFF), size: 20),
            const SizedBox(height: 10),
          ],
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
