import 'package:flutter/material.dart';

class PopularAreas extends StatelessWidget {
  const PopularAreas({super.key});

  @override
  Widget build(BuildContext context) {
    final areas = ["Baneshwor", "Kuleshwor", "Dhulikhel", "Lazimpat"];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: areas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              areas[index],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}