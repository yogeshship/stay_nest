import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../services/saved_rooms_service.dart';
import '../screens/room_detail_screen.dart';
import '../theme/app_theme.dart';

class RoomCard extends StatefulWidget {
  final String imagePath;
  final String title;
  final String location;
  final String price;
  final String gender;
  final String description;
  final bool isAvailable;
  final String ownerName;
  final String ownerPhone;

  const RoomCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.location,
    required this.price,
    this.gender = "Any",
    this.description = "A clean and peaceful room suitable for students.",
    this.isAvailable = true,
    this.ownerName = "Room Owner",
    this.ownerPhone = "98XXXXXXXX",
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  @override
  Widget build(BuildContext context) {
    final room = RoomModel(
      title: widget.title,
      location: widget.location,
      price: widget.price.replaceAll("Rs. ", "").replaceAll("/month", ""),
      imagePath: widget.imagePath,
      gender: widget.gender,
      description: widget.description,
      isAvailable: widget.isAvailable,
      ownerName: widget.ownerName,
      ownerPhone: widget.ownerPhone,
    );

    final bool isSaved = SavedRoomsService.isSaved(room);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomDetailScreen(
              imagePath: widget.imagePath,
              title: widget.title,
              location: widget.location,
              price: widget.price,
              gender: widget.gender,
              description: widget.description,
              isAvailable: widget.isAvailable,
              ownerName: widget.ownerName,
              ownerPhone: widget.ownerPhone,
            ),
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
              child: Image.asset(
                widget.imagePath,
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
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: AppColors.success, size: 14),
                      SizedBox(width: 4),
                      Text("VERIFIED",
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .7)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.price,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  SavedRoomsService.toggleSave(room);
                });
              },
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? const Color(0xFFE6506E) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
