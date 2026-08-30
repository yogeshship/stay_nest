import 'package:flutter/material.dart';

import '../models/app_user_model.dart';
import '../models/inquiry_model.dart';
import '../models/owner_analytics.dart';
import '../models/room_model.dart';
import '../services/auth_service.dart';
import '../services/owner_analytics_service.dart';
import '../services/user_service.dart';
import '../widgets/analytics_metric_card.dart';
import '../widgets/room_performance_card.dart';
import 'inquiries_screen.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({
    super.key,
    this.analyticsService,
    this.profileStream,
    this.roomsStream,
    this.inquiriesStream,
  });

  final OwnerAnalyticsService? analyticsService;
  final Stream<AppUserModel?>? profileStream;
  final Stream<List<RoomModel>>? roomsStream;
  final Stream<List<InquiryModel>>? inquiriesStream;

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  late final OwnerAnalyticsService _service;
  late Stream<AppUserModel?> _profileStream;
  late Stream<List<RoomModel>> _roomsStream;
  late Stream<List<InquiryModel>> _inquiriesStream;
  Future<OwnerReviewSnapshot>? _reviewFuture;
  String? _reviewRoomFingerprint;
  List<RoomModel> _latestRooms = const [];

  @override
  void initState() {
    super.initState();
    _service = widget.analyticsService ?? OwnerAnalyticsService();
    if (widget.profileStream != null) {
      _profileStream = widget.profileStream!;
    } else {
      final uid = AuthService().currentUser?.uid;
      if (uid == null) throw StateError('An owner must be signed in.');
      _profileStream = UserService().watchUserProfile(uid);
    }
    _roomsStream = widget.roomsStream ?? _service.watchOwnerRooms();
    _inquiriesStream = widget.inquiriesStream ?? _service.watchOwnerInquiries();
  }

  void _ensureReviewLoad(List<RoomModel> rooms) {
    final ids = rooms.map((room) => room.id).toList()..sort();
    final fingerprint = ids.join('\u0000');
    _latestRooms = rooms;
    if (_reviewRoomFingerprint == fingerprint && _reviewFuture != null) return;
    _reviewRoomFingerprint = fingerprint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _reviewRoomFingerprint != fingerprint) return;
      setState(() {
        _reviewFuture = _service.loadReviewsForOwnedRooms(rooms);
      });
    });
  }

  void _refreshReviews() {
    setState(() {
      _reviewFuture = _service.loadReviewsForOwnedRooms(_latestRooms);
    });
  }

  void _retryOwnerData() {
    setState(() {
      _roomsStream = widget.roomsStream ?? _service.watchOwnerRooms();
      _inquiriesStream =
          widget.inquiriesStream ?? _service.watchOwnerInquiries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FC),
        elevation: 0,
        title: const Text('Listing Analytics'),
      ),
      body: StreamBuilder<AppUserModel?>(
        stream: _profileStream,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profileSnapshot.hasError) {
            return _MessageState(
              message: 'Owner verification status could not be loaded.',
              actionLabel: 'Retry',
              onAction: () => setState(() {
                final uid = AuthService().currentUser?.uid;
                if (uid != null) {
                  _profileStream = UserService().watchUserProfile(uid);
                }
              }),
            );
          }
          final profile = profileSnapshot.data;
          if (profile == null || !profile.isActive) {
            return const _MessageState(
              message: 'Analytics are unavailable for this account.',
            );
          }
          if (!profile.isVerifiedOwner) {
            return const _MessageState(
              message:
                  'Owner verification approval is required to view analytics.',
            );
          }
          return _buildAnalytics();
        },
      ),
    );
  }

  Widget _buildAnalytics() {
    return StreamBuilder<List<RoomModel>>(
      stream: _roomsStream,
      builder: (context, roomSnapshot) {
        if (roomSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (roomSnapshot.hasError) {
          return _MessageState(
            message: 'Your listings could not be loaded. Please try again.',
            actionLabel: 'Retry',
            onAction: _retryOwnerData,
          );
        }
        final rooms = roomSnapshot.data ?? const <RoomModel>[];
        _ensureReviewLoad(rooms);
        return StreamBuilder<List<InquiryModel>>(
          stream: _inquiriesStream,
          builder: (context, inquirySnapshot) {
            final inquiries = inquirySnapshot.data ?? const <InquiryModel>[];
            final inquiryError = inquirySnapshot.hasError;
            return FutureBuilder<OwnerReviewSnapshot>(
              future: _reviewFuture,
              builder: (context, reviewSnapshot) {
                final reviews = reviewSnapshot.data?.reviews ?? const [];
                final analytics = _service.calculate(
                  rooms: rooms,
                  inquiries: inquiries,
                  reviews: reviews,
                );
                return _AnalyticsContent(
                  analytics: analytics,
                  hasRooms: rooms.isNotEmpty,
                  inquiryLoading: inquirySnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !inquirySnapshot.hasData,
                  inquiryError: inquiryError,
                  onRetryRequests: _retryOwnerData,
                  reviewLoading: reviewSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      _reviewFuture == null,
                  reviewError: reviewSnapshot.hasError,
                  reviewErrorMessage: reviewSnapshot.hasError
                      ? friendlyOwnerAnalyticsError(reviewSnapshot.error!)
                      : null,
                  reviewLoadedAt: reviewSnapshot.data?.loadedAt,
                  onRefreshReviews: _refreshReviews,
                  onOpenRequests: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InquiriesScreen(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.analytics,
    required this.hasRooms,
    required this.inquiryLoading,
    required this.inquiryError,
    required this.onRetryRequests,
    required this.reviewLoading,
    required this.reviewError,
    required this.reviewErrorMessage,
    required this.reviewLoadedAt,
    required this.onRefreshReviews,
    required this.onOpenRequests,
  });

  final OwnerAnalytics analytics;
  final bool hasRooms;
  final bool inquiryLoading;
  final bool inquiryError;
  final VoidCallback onRetryRequests;
  final bool reviewLoading;
  final bool reviewError;
  final String? reviewErrorMessage;
  final DateTime? reviewLoadedAt;
  final VoidCallback onRefreshReviews;
  final VoidCallback onOpenRequests;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionTitle('Listing Overview'),
        _MetricGrid(items: [
          ('Total', analytics.totalListings.toString()),
          ('Available', analytics.availableListings.toString()),
          ('Unavailable', analytics.unavailableListings.toString()),
        ]),
        if (!hasRooms)
          const _InlineMessage(
            'Add your first listing to start seeing performance.',
          ),
        const _SectionTitle('Request Workflow'),
        if (inquiryLoading)
          const LinearProgressIndicator()
        else if (inquiryError)
          _RetryMessage(
            'Request activity could not be loaded. Listing and rating data remain available.',
            onRetryRequests,
          )
        else
          _MetricGrid(items: [
            ('Total', analytics.totalRequests.toString()),
            ('Pending', analytics.pendingRequests.toString()),
            ('Accepted', analytics.acceptedRequests.toString()),
            ('Completed', analytics.completedRequests.toString()),
            ('Declined', analytics.declinedRequests.toString()),
            ('Unread', analytics.unreadRequests.toString()),
            ('Completed Visits', analytics.completedVisits.toString()),
            (
              'Cancelled / Other',
              analytics.cancelledOrOtherRequests.toString()
            ),
          ]),
        if (analytics.orphanedInquiryCount > 0)
          _InlineMessage(
            '${analytics.orphanedInquiryCount} historical request${analytics.orphanedInquiryCount == 1 ? '' : 's'} belong to deleted listings.',
          ),
        const _SectionTitle('Review Performance'),
        Row(
          children: [
            Expanded(
              child: Text(
                reviewLoadedAt == null
                    ? 'Current room reviews'
                    : 'Last refreshed ${_timeLabel(reviewLoadedAt!)}',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            TextButton.icon(
              onPressed: reviewLoading ? null : onRefreshReviews,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        if (reviewLoading)
          const LinearProgressIndicator()
        else if (reviewError)
          _RetryMessage(
            reviewErrorMessage ?? 'Rating data could not be loaded.',
            onRefreshReviews,
          )
        else
          _MetricGrid(items: [
            ('Reviews', analytics.totalReviews.toString()),
            (
              'Average Rating',
              analytics.totalReviews == 0
                  ? 'No ratings yet'
                  : analytics.averageRating.toStringAsFixed(1),
            ),
            ('Rated Rooms', analytics.ratedRoomCount.toString()),
          ]),
        const _SectionTitle('Per-room Performance'),
        if (!hasRooms)
          const _InlineMessage('No current listings to compare.')
        else
          for (final performance in analytics.roomPerformance)
            RoomPerformanceCard(
              performance: performance,
              reviewsAvailable: !reviewLoading && !reviewError,
            ),
        const _SectionTitle('Recent Requests'),
        if (!inquiryLoading && !inquiryError) ...[
          if (analytics.recentInquiries.isEmpty)
            const _InlineMessage('No requests received yet.')
          else
            for (final inquiry in analytics.recentInquiries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  inquiry.type == InquiryModel.visitRequestType
                      ? Icons.calendar_month_outlined
                      : Icons.chat_bubble_outline,
                ),
                title: Text(
                  inquiry.roomTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${inquiry.typeLabel} · ${inquiry.statusLabel}'),
                trailing: inquiry.isUnreadForOwner
                    ? const Icon(Icons.circle,
                        size: 10, color: Color(0xFF6C3BFF))
                    : null,
              ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpenRequests,
              child: const Text('View Request Activity'),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 700
              ? (constraints.maxWidth - 24) / 3
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: AnalyticsMetricCard(label: item.$1, value: item.$2),
                ),
            ],
          );
        },
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 12),
        child: Text(
          text,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
      );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(message, style: const TextStyle(color: Colors.black54)),
      );
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage(this.message, this.onRetry);
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (onAction != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}

String _timeLabel(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
