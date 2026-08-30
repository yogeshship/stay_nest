import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  const RoomModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.location,
    required this.monthlyRent,
    required this.genderPreference,
    required this.description,
    required this.imageUrls,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  static const String fallbackAsset = 'assets/images/room1.jpeg';

  final String id;
  final String ownerId;
  final String title;
  final String location;
  final num monthlyRent;
  final String genderPreference;
  final String description;
  final List<String> imageUrls;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get primaryImage =>
      imageUrls.isEmpty ? fallbackAsset : imageUrls.first;

  String get availabilityLabel => isAvailable ? 'Available' : 'Unavailable';

  bool get canCreateCustomerRequest => isAvailable;

  String get formattedMonthlyRent {
    final value = monthlyRent is int
        ? monthlyRent.toInt().toString()
        : monthlyRent.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '');
    final parts = value.split('.');
    final digits = parts.first;
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return parts.length == 1 ? formatted : '$formatted.${parts.last}';
  }

  factory RoomModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) throw StateError('The room does not exist.');

    return RoomModel(
      id: document.id,
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      location: data['location'] as String? ?? '',
      monthlyRent: data['monthlyRent'] as num? ?? 0,
      genderPreference: data['genderPreference'] as String? ?? 'Any',
      description: data['description'] as String? ?? '',
      imageUrls: (data['imageUrls'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      isAvailable: data['isAvailable'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'location': location,
      'monthlyRent': monthlyRent,
      'genderPreference': genderPreference,
      'description': description,
      'imageUrls': imageUrls,
      'isAvailable': isAvailable,
    };
  }
}
