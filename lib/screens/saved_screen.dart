import 'package:flutter/material.dart';

import '../models/room_model.dart';
import '../services/saved_rooms_service.dart';
import '../widgets/room_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  late final Stream<List<RoomModel>> _savedRoomsStream;

  @override
  void initState() {
    super.initState();
    _savedRoomsStream = SavedRoomsService().watchSavedRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SavedScreen.bgColor,
      appBar: AppBar(
        backgroundColor: SavedScreen.bgColor,
        elevation: 0,
        title: const Text(
          'Saved Rooms',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<RoomModel>>(
        stream: _savedRoomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Saved rooms could not be loaded. Please check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final rooms = snapshot.data ?? const <RoomModel>[];
          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                'No saved rooms yet',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              return RoomCard(room: rooms[index], isSaved: true);
            },
          );
        },
      ),
    );
  }
}
