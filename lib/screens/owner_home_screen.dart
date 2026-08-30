import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/inquiry_model.dart';
import '../services/room_service.dart';
import '../services/inquiry_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/app_user_model.dart';
import 'add_room_screen.dart';
import 'my_listings_screen.dart';
import 'inquiries_screen.dart';
import 'owner_profile_screen.dart';
import 'owner_verification_request_screen.dart';
import 'owner_analytics_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({
    super.key,
    this.roomsStream,
    this.inquiriesStream,
    this.profileStream,
    this.screenOpener,
  });

  final Stream<List<RoomModel>>? roomsStream;
  final Stream<List<InquiryModel>>? inquiriesStream;
  final Stream<AppUserModel?>? profileStream;
  final Future<void> Function(BuildContext context, Widget screen)?
      screenOpener;

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  late final Stream<List<RoomModel>> _roomsStream;
  late final Stream<List<InquiryModel>> _inquiriesStream;
  late final Stream<AppUserModel?> _profileStream;

  @override
  void initState() {
    super.initState();
    _roomsStream = widget.roomsStream ?? RoomService().watchOwnerRooms();
    _inquiriesStream =
        widget.inquiriesStream ?? InquiryService().watchOwnerInquiries();
    if (widget.profileStream != null) {
      _profileStream = widget.profileStream!;
    } else {
      final owner = AuthService().currentUser;
      if (owner == null) throw StateError('An owner must be signed in.');
      _profileStream = UserService().watchUserProfile(owner.uid);
    }
  }

  Future<void> openScreen(Widget screen) async {
    if (widget.screenOpener != null) {
      return widget.screenOpener!(context, screen);
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwnerHomeScreen.bgColor,
      appBar: AppBar(
        backgroundColor: OwnerHomeScreen.bgColor,
        elevation: 0,
        title: const Text(
          "Owner Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<AppUserModel?>(
        stream: _profileStream,
        builder: (context, profileSnapshot) {
          return StreamBuilder<List<RoomModel>>(
            stream: _roomsStream,
            builder: (context, roomSnapshot) {
              return StreamBuilder<List<InquiryModel>>(
                stream: _inquiriesStream,
                builder: (context, inquirySnapshot) {
                  final rooms = roomSnapshot.data ?? const <RoomModel>[];
                  final inquiries =
                      inquirySnapshot.data ?? const <InquiryModel>[];
                  final profile = profileSnapshot.data;
                  return _OwnerDashboardContent(
                    rooms: rooms,
                    inquiries: inquiries,
                    profile: profile,
                    profileLoading: profileSnapshot.connectionState ==
                        ConnectionState.waiting,
                    profileError: profileSnapshot.hasError,
                    onOpen: openScreen,
                    onVerificationRequired: _openVerificationPrompt,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openVerificationPrompt() async {
    final openVerification = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification required'),
        content: const Text(
          'Your owner verification must be approved before you can add a room listing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('View Verification'),
          ),
        ],
      ),
    );
    if (openVerification == true && mounted) {
      await openScreen(const OwnerVerificationRequestScreen());
    }
  }
}

class _OwnerDashboardContent extends StatelessWidget {
  const _OwnerDashboardContent({
    required this.rooms,
    required this.inquiries,
    required this.profile,
    required this.profileLoading,
    required this.profileError,
    required this.onOpen,
    required this.onVerificationRequired,
  });

  final List<RoomModel> rooms;
  final List<InquiryModel> inquiries;
  final AppUserModel? profile;
  final bool profileLoading;
  final bool profileError;
  final Future<void> Function(Widget) onOpen;
  final Future<void> Function() onVerificationRequired;

  @override
  Widget build(BuildContext context) {
    final verified = profile?.isVerifiedOwner == true;
    final active = profile?.isActive == true;
    final unread = unreadOwnerInquiryCount(inquiries);
    if (profileLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (profileError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Owner verification status could not be loaded.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!active) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Dashboard analytics are unavailable for this account.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (verified)
          _StatsCard(
            listingCount: rooms.length,
            availableCount: rooms.where((room) => room.isAvailable).length,
            pendingCount: pendingOwnerInquiryCount(inquiries),
            unreadCount: unread,
          )
        else
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Owner verification approval is required to view dashboard analytics.',
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 24),
        _OwnerActionCard(
          icon: Icons.add_home_work_rounded,
          title: 'Add Room',
          subtitle: verified
              ? 'Post a new room or hostel listing'
              : 'Owner verification approval required',
          onTap: profileLoading || profileError || !active
              ? null
              : () => verified
                  ? onOpen(const AddRoomScreen())
                  : onVerificationRequired(),
        ),
        _OwnerActionCard(
          icon: Icons.home_work_outlined,
          title: 'My Listings',
          subtitle: 'Manage your added rooms',
          onTap: () => onOpen(const MyListingsScreen()),
        ),
        _OwnerActionCard(
          icon: Icons.analytics_outlined,
          title: 'Listing Analytics',
          subtitle: verified
              ? 'Requests, visits, ratings, and listing performance'
              : 'Owner verification approval required',
          onTap: profileLoading || profileError || !active
              ? null
              : () => verified
                  ? onOpen(const OwnerAnalyticsScreen())
                  : onVerificationRequired(),
        ),
        _OwnerActionCard(
          icon: Icons.notifications_outlined,
          title: 'Request Activity',
          subtitle: unread == 0
              ? 'View inquiries and visit requests'
              : '$unread unread request${unread == 1 ? '' : 's'}',
          onTap: () => onOpen(const InquiriesScreen()),
        ),
        _OwnerActionCard(
          icon: Icons.person_outline,
          title: 'Owner Profile',
          subtitle: 'Manage account and contact details',
          onTap: () => onOpen(const OwnerProfileScreen()),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int listingCount;
  final int availableCount;
  final int pendingCount;
  final int unreadCount;

  const _StatsCard({
    required this.listingCount,
    required this.availableCount,
    required this.pendingCount,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: OwnerHomeScreen.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(title: "Listings", value: listingCount.toString()),
          _StatItem(title: "Available", value: availableCount.toString()),
          _StatItem(title: "Pending", value: pendingCount.toString()),
          _StatItem(title: "Unread", value: unreadCount.toString()),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _OwnerActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OwnerActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: OwnerHomeScreen.primaryColor, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
