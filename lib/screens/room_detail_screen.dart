import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_model.dart';
import '../models/inquiry_model.dart';
import '../models/review_model.dart';
import '../models/room_model.dart';
import '../services/inquiry_service.dart';
import '../services/review_service.dart';
import '../widgets/rating_summary.dart';
import '../widgets/review_card.dart';
import '../widgets/review_editor.dart';
import '../widgets/room_image.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.room,
  });

  final RoomModel room;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final InquiryService _inquiryService = InquiryService();
  bool _isSubmitting = false;

  Future<void> _sendInquiry(String type) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _inquiryService.createInquiry(
        room: widget.room,
        type: type,
        message: type == InquiryModel.visitRequestType
            ? 'Customer requested to visit this room.'
            : 'Customer sent an inquiry about this room.',
      );
      if (!mounted) return;
      final label =
          type == InquiryModel.visitRequestType ? 'Visit request' : 'Inquiry';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label sent successfully'),
          backgroundColor: const Color(0xFF6C3BFF),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyInquiryError(error))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: ListView(
          children: [
            Stack(
              children: [
                RoomImage(
                  source: widget.room.primaryImage,
                  height: 280,
                  width: double.infinity,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(widget.room.availabilityLabel),
                    backgroundColor: widget.room.isAvailable
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                  ),
                  if (!widget.room.isAvailable) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'This room is no longer available and is not accepting new inquiries or visit requests.',
                      style: TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    widget.room.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.room.location)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Rs. ${widget.room.formattedMonthlyRent}/month',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C3BFF),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Gender Preference: ${widget.room.genderPreference}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Property Owner',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFFEDE7FF),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF6C3BFF),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'StayNest Property Owner',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.room.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.room.canCreateCustomerRequest &&
                                  !_isSubmitting
                              ? () =>
                                  _sendInquiry(InquiryModel.visitRequestType)
                              : null,
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Request Visit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C3BFF),
                          ),
                          onPressed: widget.room.canCreateCustomerRequest &&
                                  !_isSubmitting
                              ? () => _sendInquiry(InquiryModel.inquiryType)
                              : null,
                          icon: const Icon(Icons.message, color: Colors.white),
                          label: const Text(
                            'Send Inquiry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Owner contact details are protected. StayNest will coordinate after inquiry approval.',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  RoomReviewsSection(room: widget.room),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomReviewsSection extends StatefulWidget {
  const RoomReviewsSection({
    super.key,
    required this.room,
    this.reviewService,
    this.reviewsStream,
    this.profileFuture,
    this.ownReviewStream,
    this.eligibilityFuture,
    this.onSaveReview,
    this.onDeleteReview,
  });

  final RoomModel room;
  final ReviewService? reviewService;
  final Stream<List<ReviewModel>>? reviewsStream;
  final Future<AppUserModel?>? profileFuture;
  final Stream<ReviewModel?>? ownReviewStream;
  final Future<ReviewEligibility>? eligibilityFuture;
  final Future<void> Function(ReviewModel?, int, String)? onSaveReview;
  final Future<void> Function()? onDeleteReview;

  @override
  State<RoomReviewsSection> createState() => _RoomReviewsSectionState();
}

class _RoomReviewsSectionState extends State<RoomReviewsSection> {
  late final ReviewService _service = widget.reviewService ?? ReviewService();
  late final Stream<List<ReviewModel>> _reviews =
      widget.reviewsStream ?? _service.watchRoomReviews(widget.room.id);
  late final Future<AppUserModel?> _profile =
      widget.profileFuture ?? _loadProfile();
  Future<ReviewEligibility>? _eligibility;

  void _retryEligibility() {
    setState(() {
      _eligibility = _service.getReviewEligibility(widget.room.id);
    });
  }

  Future<AppUserModel?> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final document =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return document.exists ? AppUserModel.fromFirestore(document) : null;
  }

  Future<void> _showEditor(ReviewModel? review) async {
    await showDialog<void>(
      context: context,
      builder: (context) => ReviewEditor(
        existingReview: review,
        onSubmit: (rating, text) async {
          try {
            if (widget.onSaveReview != null) {
              await widget.onSaveReview!(review, rating, text);
              return;
            }
            if (review == null) {
              await _service.createReview(
                roomId: widget.room.id,
                rating: rating,
                reviewText: text,
              );
            } else {
              await _service.updateReview(
                roomId: widget.room.id,
                rating: rating,
                reviewText: text,
              );
            }
          } catch (error) {
            throw friendlyReviewError(error);
          }
        },
        onDelete: review == null
            ? null
            : () async {
                try {
                  if (widget.onDeleteReview != null) {
                    await widget.onDeleteReview!();
                  } else {
                    await _service.deleteReview(widget.room.id);
                  }
                } catch (error) {
                  throw friendlyReviewError(error);
                }
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('room-reviews-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<ReviewModel>>(
          stream: _reviews,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                'Reviews could not be loaded. Please try again.',
                key: Key('reviews-error'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                key: Key('reviews-loading'),
                child: CircularProgressIndicator(),
              );
            }
            final reviews = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingSummaryWidget(
                  summary: ReviewSummary.fromReviews(reviews),
                ),
                if (reviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'No reviews yet. Be the first eligible visitor to share an experience.',
                      key: Key('reviews-empty'),
                    ),
                  ),
                ...reviews.map((review) => ReviewCard(review: review)),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<AppUserModel?>(
          future: _profile,
          builder: (context, profileSnapshot) {
            if (!profileSnapshot.hasData) return const SizedBox.shrink();
            final profile = profileSnapshot.data!;
            if (!profile.isActive ||
                profile.role != AppUserModel.customerRole) {
              return const Text('Reviews are read-only for this account.');
            }
            if (profile.uid == widget.room.ownerId) {
              return const Text('You cannot review your own room.');
            }
            return StreamBuilder<ReviewModel?>(
              stream: widget.ownReviewStream ??
                  _service.watchOwnReview(widget.room.id),
              builder: (context, ownSnapshot) {
                if (ownSnapshot.hasError) {
                  return const Text('Your review could not be loaded.');
                }
                if (!ownSnapshot.hasData &&
                    ownSnapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final ownReview = ownSnapshot.data;
                if (ownReview != null) {
                  return FilledButton.icon(
                    key: const Key('edit-own-review'),
                    onPressed: () => _showEditor(ownReview),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit your review'),
                  );
                }
                return FutureBuilder<ReviewEligibility>(
                  future: widget.eligibilityFuture ??
                      (_eligibility ??=
                          _service.getReviewEligibility(widget.room.id)),
                  builder: (context, eligibilitySnapshot) {
                    if (eligibilitySnapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              'Review eligibility could not be checked.'),
                          if (widget.eligibilityFuture == null)
                            TextButton(
                              key: const Key('retry-review-eligibility'),
                              onPressed: _retryEligibility,
                              child: const Text('Retry'),
                            ),
                        ],
                      );
                    }
                    if (!eligibilitySnapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final eligibility = eligibilitySnapshot.data!;
                    if (!eligibility.isEligible) {
                      return Text(
                        eligibility.message,
                        key: const Key('review-ineligible-message'),
                      );
                    }
                    return FilledButton.icon(
                      key: const Key('write-review-button'),
                      onPressed: () => _showEditor(null),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Write a review'),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
