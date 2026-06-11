import 'package:flutter/material.dart';
import '../widgets/room_card.dart';
import '../services/saved_rooms_service.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          "Saved Rooms",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ValueListenableBuilder(
        valueListenable: SavedRoomsService.savedRoomsNotifier,
        builder: (context, savedRooms, child) {
          if (savedRooms.isEmpty) {
            return const Center(
              child: Text(
                "No saved rooms yet",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: savedRooms.length,
            itemBuilder: (context, index) {
              final room = savedRooms[index];

              return RoomCard(
                imagePath: room.imagePath,
                title: room.title,
                location: room.location,
                price: "Rs. ${room.price}/month",
                gender: room.gender,
                description: room.description,
                isAvailable: room.isAvailable,
              );
            },
          );
        },
      ),
    );
  }
}