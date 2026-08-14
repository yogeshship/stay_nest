import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryRow extends StatelessWidget {
  final ValueChanged<String>? onCategoryTap;

  const CategoryRow({super.key, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CategoryItem(
            icon: Icons.bed_rounded,
            title: "Rooms",
            onTap: () => onCategoryTap?.call("Rooms"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CategoryItem(
            icon: Icons.apartment_rounded,
            title: "Hostels",
            onTap: () => onCategoryTap?.call("Hostels"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CategoryItem(
            icon: Icons.people_rounded,
            title: "Sharing",
            onTap: () => onCategoryTap?.call("Sharing"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CategoryItem(
            icon: Icons.shield_outlined,
            title: "Safety",
            onTap: () => onCategoryTap?.call("Safety"),
          ),
        ),
      ],
    );
  }
}

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const CategoryItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Ink(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
