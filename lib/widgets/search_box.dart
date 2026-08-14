import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  final VoidCallback? onTap;

  const SearchBox({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: onTap != null,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: "Search location, area or hostel",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.tune_rounded),
      ),
    );
  }
}
