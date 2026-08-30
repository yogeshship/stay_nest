import 'package:flutter/material.dart';

import '../models/room_model.dart';
import '../screens/room_detail_screen.dart';
import '../services/saved_rooms_service.dart';
import '../theme/app_theme.dart';
import 'room_image.dart';

class RoomCard extends StatefulWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.isSaved,
  });

  final RoomModel room;
  final bool isSaved;

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  final SavedRoomsService _savedRoomsService = SavedRoomsService();
  bool _isWriting = false;
  bool? _savedOverride;

  @override
  void didUpdateWidget(covariant RoomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_savedOverride == widget.isSaved) _savedOverride = null;
  }

  Future<void> _toggleSaved() async {
    if (_isWriting) return;
    final wasSaved = _savedOverride ?? widget.isSaved;
    setState(() => _isWriting = true);
    try {
      await _savedRoomsService.toggleSavedRoom(
        widget.room.id,
        isCurrentlySaved: wasSaved,
      );
      if (mounted) setState(() => _savedOverride = !wasSaved);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlySavedRoomError(error)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isWriting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final isSaved = _savedOverride ?? widget.isSaved;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomDetailScreen(room: room),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.home_work_outlined,
                        color: AppColors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ROOM LISTING',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                        ),
                      ),
                      const Spacer(),
                      RoomAvailabilityBadge(room: room),
                    ],
                  ),
                  const SizedBox(height: 6),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Rs. ${room.formattedMonthlyRent}/month',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isWriting ? null : _toggleSaved,
              icon: _isWriting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved
                          ? const Color(0xFFE6506E)
                          : AppColors.textMuted,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomAvailabilityBadge extends StatelessWidget {
  const RoomAvailabilityBadge({super.key, required this.room});

  final RoomModel room;

  @override
  Widget build(BuildContext context) {
    if (room.isAvailable) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        room.availabilityLabel.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFC62828),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
        ),
      ),
    );
  }
}
