import '../models/room_model.dart';

class RoomDataService {
  static final List<RoomModel> ownerRooms = [
    RoomModel(
      title: "College View Room",
      location: "Baneshwor, Kathmandu",
      price: "8500",
      imagePath: "assets/images/room1.jpeg",
      gender: "Any",
      description: "Clean room near college with water and Wi-Fi.",
      ownerName: "Ramesh Shrestha",
      ownerPhone: "9800000001",
    ),
    RoomModel(
      title: "Budget Room for Boys",
      location: "New Baneshwor, Kathmandu",
      price: "6500",
      imagePath: "assets/images/room2.jpeg",
      gender: "Boys",
      description: "Affordable room suitable for students.",
      isAvailable: false,
      ownerName: "Sanjay Tamang",
      ownerPhone: "9800000002",
    ),
  ];

  static void addRoom(RoomModel room) {
    ownerRooms.add(room);
  }
}