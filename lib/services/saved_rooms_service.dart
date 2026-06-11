import 'package:flutter/material.dart';
import '../models/room_model.dart';

class SavedRoomsService {
  static final ValueNotifier<List<RoomModel>> savedRoomsNotifier =
  ValueNotifier<List<RoomModel>>([]);

  static List<RoomModel> get savedRooms => savedRoomsNotifier.value;

  static bool isSaved(RoomModel room) {
    return savedRooms.any(
          (savedRoom) =>
      savedRoom.title == room.title &&
          savedRoom.location == room.location,
    );
  }

  static void toggleSave(RoomModel room) {
    final updatedList = List<RoomModel>.from(savedRooms);

    if (isSaved(room)) {
      updatedList.removeWhere(
            (savedRoom) =>
        savedRoom.title == room.title &&
            savedRoom.location == room.location,
      );
    } else {
      updatedList.add(room);
    }

    savedRoomsNotifier.value = updatedList;
  }
}