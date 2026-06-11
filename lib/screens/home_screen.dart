import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/search_box.dart';
import '../widgets/home_banner.dart';
import '../widgets/section_title.dart';
import '../widgets/category_item.dart';
import '../widgets/popular_areas.dart';
import '../widgets/room_card.dart';
import '../services/room_data_service.dart';
import 'search_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

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
        MaterialPageRoute(builder: (context) => const MessagesScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = RoomDataService.ownerRooms
        .where((room) => room.isAvailable)
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) => _onBottomNavTap(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Saved"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const HomeHeader(),
            const SizedBox(height: 18),
            const SearchBox(),
            const SizedBox(height: 18),
            const HomeBanner(),
            const SizedBox(height: 24),
            const SectionTitle(title: "Categories"),
            const SizedBox(height: 14),
            const CategoryRow(),
            const SizedBox(height: 26),
            const SectionTitle(title: "Popular Areas"),
            const SizedBox(height: 14),
            const PopularAreas(),
            const SizedBox(height: 26),
            const SectionTitle(title: "Recommended for you"),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Rooms"),
              ),
            ),

            const SizedBox(height: 14),

            if (rooms.isEmpty)
              const Text("No rooms available yet")
            else
              ...rooms.take(3).map(
                    (room) => RoomCard(
                  imagePath: room.imagePath,
                  title: room.title,
                  location: room.location,
                  price: "Rs. ${room.price}/month",
                  gender: room.gender,
                  description: room.description,
                  isAvailable: room.isAvailable,
                      ownerName: room.ownerName,
                      ownerPhone: room.ownerPhone,
                ),
              ),
          ],
        ),
      ),
    );
  }
}