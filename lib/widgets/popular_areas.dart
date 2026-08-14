import 'package:flutter/material.dart';

class PopularAreas extends StatelessWidget {
  final ValueChanged<String>? onAreaTap;

  const PopularAreas({super.key, this.onAreaTap});

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
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => onAreaTap?.call(areas[index]),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    areas[index],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
