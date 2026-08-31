import 'package:flutter/material.dart';
import '../models/room_model.dart';

class AdminRoomCard extends StatelessWidget {
  const AdminRoomCard(
      {super.key,
      required this.room,
      required this.onToggle,
      required this.busy});
  final RoomModel room;
  final VoidCallback? onToggle;
  final bool busy;
  @override
  Widget build(BuildContext context) => Card(
          child: ListTile(
        title: Text(room.title),
        subtitle: Text(
            '${room.location} • ${room.formattedMonthlyRent}/month\nOwner: ${room.ownerId}\n${room.isAvailable ? 'Available' : 'Unavailable'}'),
        isThreeLine: true,
        trailing: busy
            ? const SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator())
            : TextButton(
                onPressed: onToggle,
                child: Text(room.isAvailable ? 'Set unavailable' : 'Restore')),
      ));
}
