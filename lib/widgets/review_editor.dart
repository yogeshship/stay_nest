import 'package:flutter/material.dart';

import '../models/review_model.dart';

class ReviewEditor extends StatefulWidget {
  const ReviewEditor({
    super.key,
    this.existingReview,
    required this.onSubmit,
    this.onDelete,
  });

  final ReviewModel? existingReview;
  final Future<void> Function(int rating, String reviewText) onSubmit;
  final Future<void> Function()? onDelete;

  @override
  State<ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<ReviewEditor> {
  late int _rating = widget.existingReview?.rating ?? 0;
  late final TextEditingController _controller = TextEditingController(
    text: widget.existingReview?.reviewText ?? '',
  );
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final text = _controller.text.trim();
    if (_rating == 0 || text.isEmpty || text.length > 1000) {
      setState(() => _error = _rating == 0
          ? 'Choose a star rating.'
          : 'Review text must be between 1 and 1000 characters.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_rating, text);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove review?'),
        content: const Text('You can write another review later if eligible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.onDelete == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onDelete!();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.existingReview == null ? 'Write a review' : 'Edit review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (index) => IconButton(
                  key: Key('review-star-${index + 1}'),
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            TextField(
              key: const Key('review-text-field'),
              controller: _controller,
              enabled: !_submitting,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration:
                  const InputDecoration(hintText: 'Share your experience'),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        if (widget.existingReview != null && widget.onDelete != null)
          TextButton(
            key: const Key('delete-review-button'),
            onPressed: _submitting ? null : _delete,
            child: const Text('Remove review'),
          ),
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('submit-review-button'),
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
