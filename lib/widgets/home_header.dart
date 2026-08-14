import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good morning 👋',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Find your next stay',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.4)),
                ],
              ),
            ),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 13),
        const Row(
          children: [
            Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
            SizedBox(width: 5),
            Text('Kathmandu, Nepal',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }
}
