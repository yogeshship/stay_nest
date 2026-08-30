import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../widgets/home_header.dart';
import '../widgets/search_box.dart';
import '../widgets/home_banner.dart';
import '../widgets/section_title.dart';
import '../widgets/category_item.dart';
import '../widgets/popular_areas.dart';
import '../widgets/room_card.dart';
import '../services/room_service.dart';
import '../services/saved_rooms_service.dart';
import 'search_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';
import 'activity_screen.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import 'trust_verification_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  void _onCategoryTap(BuildContext context, String category) {
    if (category == "Hostels") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      );
      return;
    }

    if (category == "Safety") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TrustVerificationScreen(),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.hourglass_empty_rounded,
          color: AppColors.primary,
          size: 36,
        ),
        title: Text("$category not available yet"),
        content: const Text(
          "Currently, only hostel listings are available. Please check back later.",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Okay"),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SearchScreen()),
      );
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SavedScreen()),
      );
    }

    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ActivityScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) => _onBottomNavTap(context, index),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: "Home"),
          const NavigationDestination(
              icon: Icon(Icons.search_rounded), label: "Search"),
          const NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: "Saved"),
          const NavigationDestination(
            icon: _CustomerActivityIcon(),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: "Activity",
          ),
          const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded), label: "Profile"),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            const HomeHeader(),
            const SizedBox(height: 18),
            SearchBox(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            const SizedBox(height: 18),
            const HomeBanner(),
            const SizedBox(height: 24),
            const SectionTitle(title: "Categories"),
            const SizedBox(height: 14),
            CategoryRow(
              onCategoryTap: (category) => _onCategoryTap(context, category),
            ),
            const SizedBox(height: 26),
            const SectionTitle(title: "Popular Areas"),
            const SizedBox(height: 14),
            PopularAreas(
              onAreaTap: (area) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(initialLocation: area),
                ),
              ),
            ),
            const SizedBox(height: 26),
            SectionTitle(
              title: "Recommended for you",
              actionLabel: 'See all',
              onAction: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            const SizedBox(height: 14),
            const _RecommendedRooms(),
          ],
        ),
      ),
    );
  }
}

class _CustomerActivityIcon extends StatefulWidget {
  const _CustomerActivityIcon();

  @override
  State<_CustomerActivityIcon> createState() => _CustomerActivityIconState();
}

class _CustomerActivityIconState extends State<_CustomerActivityIcon> {
  late final Stream<List<InquiryModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = InquiryService().watchCustomerInquiries();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InquiryModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        final count =
            snapshot.data?.where((item) => item.isUnreadForCustomer).length ??
                0;
        return Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: const Icon(Icons.notifications_outlined),
        );
      },
    );
  }
}

class _RecommendedRooms extends StatefulWidget {
  const _RecommendedRooms();

  @override
  State<_RecommendedRooms> createState() => _RecommendedRoomsState();
}

class _RecommendedRoomsState extends State<_RecommendedRooms> {
  late final Stream<List<RoomModel>> _roomsStream;
  late final Stream<Set<String>> _savedRoomIdsStream;

  @override
  void initState() {
    super.initState();
    _roomsStream = RoomService().watchAvailableRooms();
    _savedRoomIdsStream = SavedRoomsService().watchSavedRoomIds();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomModel>>(
      stream: _roomsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text(
            'Rooms could not be loaded. Please try again.',
            style: TextStyle(color: Colors.red),
          );
        }

        return StreamBuilder<Set<String>>(
          stream: _savedRoomIdsStream,
          builder: (context, savedSnapshot) {
            if (savedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (savedSnapshot.hasError) {
              return const Text(
                'Saved-room status could not be loaded. Please try again.',
                style: TextStyle(color: Colors.red),
              );
            }

            final rooms = snapshot.data ?? const <RoomModel>[];
            if (rooms.isEmpty) return const Text('No rooms available yet');
            final savedRoomIds = savedSnapshot.data ?? const <String>{};
            return Column(
              children: rooms
                  .take(3)
                  .map(
                    (room) => RoomCard(
                      room: room,
                      isSaved: savedRoomIds.contains(room.id),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}
