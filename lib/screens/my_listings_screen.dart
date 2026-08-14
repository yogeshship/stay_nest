import 'package:flutter/material.dart';

import '../models/room_model.dart';
import '../services/room_service.dart';
import '../widgets/room_image.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final RoomService _roomService = RoomService();
  late final Stream<List<RoomModel>> _roomsStream;

  @override
  void initState() {
    super.initState();
    _roomsStream = _roomService.watchOwnerRooms();
  }

  Future<void> _toggleAvailability(RoomModel room, bool value) async {
    try {
      await _roomService.updateAvailability(room.id, value);
    } catch (error) {
      if (!mounted) return;
      _showError(friendlyRoomError(error));
    }
  }

  Future<void> _confirmDelete(RoomModel room) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: const Text(
          'Are you sure you want to delete this room listing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    try {
      await _roomService.deleteRoom(room.id);
    } catch (error) {
      if (!mounted) return;
      _showError(friendlyRoomError(error));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyListingsScreen.bgColor,
      appBar: AppBar(
        backgroundColor: MyListingsScreen.bgColor,
        elevation: 0,
        title: const Text(
          'My Listings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<RoomModel>>(
        stream: _roomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Your listings could not be loaded. Please check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final rooms = snapshot.data ?? const <RoomModel>[];
          if (rooms.isEmpty) {
            return const Center(child: Text('No listings added yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _ListingCard(
                room: room,
                onToggle: (value) => _toggleAvailability(room, value),
                onDelete: () => _confirmDelete(room),
              );
            },
          );
        },
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.room,
    required this.onToggle,
    required this.onDelete,
  });

  final RoomModel room;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
            child: RoomImage(
              source: room.primaryImage,
              height: 86,
              width: 86,
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
                  'Rs. ${room.formattedMonthlyRent}/month',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  room.isAvailable ? 'Available' : 'Occupied',
                  style: TextStyle(
                    color: room.isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: room.isAvailable,
                activeColor: MyListingsScreen.primaryColor,
                onChanged: onToggle,
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
