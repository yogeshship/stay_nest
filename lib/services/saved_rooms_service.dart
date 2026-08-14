import 'package:flutter/material.dart';
import '../models/room_model.dart';

class SavedRoomsService {
  static final ValueNotifier<List<RoomModel>> savedRoomsNotifier =
      ValueNotifier<List<RoomModel>>([]);

  static List<RoomModel> get savedRooms => savedRoomsNotifier.value;

  static bool isSaved(RoomModel room) {
    return savedRooms.any(
      (savedRoom) => savedRoom.id == room.id,
    );
  }

  static void toggleSave(RoomModel room) {
    final updatedList = List<RoomModel>.from(savedRooms);

    if (isSaved(room)) {
      updatedList.removeWhere(
        (savedRoom) => savedRoom.id == room.id,
      );
    } else {
      updatedList.add(room);
    }

    savedRoomsNotifier.value = updatedList;
  }
}
