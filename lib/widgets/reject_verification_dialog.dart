import 'package:flutter/material.dart';

import '../services/admin_verification_service.dart';

class RejectVerificationDialog extends StatefulWidget {
  const RejectVerificationDialog({
    super.key,
    required this.ownerDisplayName,
  });

  final String ownerDisplayName;

  static Future<String?> show(
    BuildContext context, {
    required String ownerDisplayName,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RejectVerificationDialog(
        ownerDisplayName: ownerDisplayName,
      ),
    );
  }

  @override
  State<RejectVerificationDialog> createState() =>
      _RejectVerificationDialogState();
}

class _RejectVerificationDialogState extends State<RejectVerificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject verification request?'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explain why ${widget.ownerDisplayName} was not approved. '
              'The owner will see this reason.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Rejection reason',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: validateRejectionReason,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
