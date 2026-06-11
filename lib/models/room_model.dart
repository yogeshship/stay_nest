class RoomModel {
  final String title;
  final String location;
  final String price;
  final String imagePath;
  final String gender;
  final String description;
  final bool isAvailable;

  final String ownerName;
  final String ownerPhone;

  RoomModel({
    required this.title,
    required this.location,
    required this.price,
    required this.imagePath,
    required this.gender,
    required this.description,
    this.isAvailable = true,
    this.ownerName = "Room Owner",
    this.ownerPhone = "98XXXXXXXX",
  });
}