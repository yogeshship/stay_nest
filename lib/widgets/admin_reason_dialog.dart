import 'package:flutter/material.dart';

class AdminReasonDialog {
  static Future<String?> show(BuildContext context,
      {required String title, required String description}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(description),
          const SizedBox(height: 12),
          TextField(
              controller: controller,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Reason', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) Navigator.pop(context, value);
              },
              child: const Text('Continue')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
