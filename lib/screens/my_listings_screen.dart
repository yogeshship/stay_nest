import 'package:flutter/material.dart';
import '../services/room_data_service.dart';
import '../models/room_model.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  void toggleAvailability(int index) {
    final oldRoom = RoomDataService.ownerRooms[index];

    final updatedRoom = RoomModel(
      title: oldRoom.title,
      location: oldRoom.location,
      price: oldRoom.price,
      imagePath: oldRoom.imagePath,
      gender: oldRoom.gender,
      description: oldRoom.description,
      isAvailable: !oldRoom.isAvailable,
    );

    setState(() {
      RoomDataService.ownerRooms[index] = updatedRoom;
    });
  }

  void confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Listing?"),
          content: const Text(
            "Are you sure you want to delete this room listing?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  RoomDataService.ownerRooms.removeAt(index);
                });

                Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = RoomDataService.ownerRooms;

    return Scaffold(
      backgroundColor: MyListingsScreen.bgColor,
      appBar: AppBar(
        backgroundColor: MyListingsScreen.bgColor,
        elevation: 0,
        title: const Text(
          "My Listings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: rooms.isEmpty
          ? const Center(child: Text("No listings added yet"))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          return _ListingCard(
            room: rooms[index],
            onToggle: () => toggleAvailability(index),
            onDelete: () => confirmDelete(index),
          );
        },
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ListingCard({
    required this.room,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = room.isAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              room.imagePath,
              height: 86,
              width: 86,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  room.location,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 7),
                Text(
                  "Rs. ${room.price}/month",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAvailable ? "Available" : "Occupied",
                  style: TextStyle(
                    color: isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              Switch(
                value: isAvailable,
                activeColor: MyListingsScreen.primaryColor,
                onChanged: (_) => onToggle(),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}