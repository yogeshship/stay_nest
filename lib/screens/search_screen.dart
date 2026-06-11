import 'package:flutter/material.dart';
import '../widgets/room_card.dart';
import '../services/room_data_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String selectedLocation = "Location";
  String selectedPrice = "Price";
  String selectedGender = "Gender";

  List get filteredRooms {
    final rooms = RoomDataService.ownerRooms
        .where((room) => room.isAvailable)
        .toList();

    return rooms.where((room) {
      final roomLocation = room.location.toLowerCase();

      final locationMatch = selectedLocation == "Location" ||
          roomLocation.contains(selectedLocation.toLowerCase());

      final genderMatch = selectedGender == "Gender" ||
          selectedGender == "Any" ||
          room.gender == selectedGender ||
          room.gender == "Any";

      final price = int.tryParse(room.price) ?? 0;

      bool priceMatch = true;

      if (selectedPrice == "Below Rs. 5,000") {
        priceMatch = price < 5000;
      } else if (selectedPrice == "Rs. 5,000 - Rs. 8,000") {
        priceMatch = price >= 5000 && price <= 8000;
      } else if (selectedPrice == "Rs. 8,000 - Rs. 12,000") {
        priceMatch = price >= 8000 && price <= 12000;
      } else if (selectedPrice == "Above Rs. 12,000") {
        priceMatch = price > 12000;
      }

      return locationMatch && genderMatch && priceMatch;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      selectedLocation = "Location";
      selectedPrice = "Price";
      selectedGender = "Gender";
    });
  }

  void _showOptions({
    required String title,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...options.map(
                    (option) => ListTile(
                  title: Text(option),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectLocation() {
    _showOptions(
      title: "Select Location",
      options: const [
        "Baneshwor",
        "Kuleshwor",
        "Dhulikhel",
        "Lazimpat",
        "Kalanki",
      ],
      onSelected: (value) {
        setState(() {
          selectedLocation = value;
        });
      },
    );
  }

  void _selectPrice() {
    _showOptions(
      title: "Select Price Range",
      options: const [
        "Below Rs. 5,000",
        "Rs. 5,000 - Rs. 8,000",
        "Rs. 8,000 - Rs. 12,000",
        "Above Rs. 12,000",
      ],
      onSelected: (value) {
        setState(() {
          selectedPrice = value;
        });
      },
    );
  }

  void _selectGender() {
    _showOptions(
      title: "Select Gender Preference",
      options: const [
        "Any",
        "Boys",
        "Girls",
        "Family",
      ],
      onSelected: (value) {
        setState(() {
          selectedGender = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = filteredRooms;

    return Scaffold(
      backgroundColor: SearchScreen.bgColor,
      appBar: AppBar(
        backgroundColor: SearchScreen.bgColor,
        elevation: 0,
        title: const Text(
          "Search Rooms",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SearchInput(),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  icon: Icons.location_on_outlined,
                  label: selectedLocation,
                  onTap: _selectLocation,
                ),
                const SizedBox(width: 10),
                _FilterChipButton(
                  icon: Icons.payments_outlined,
                  label: selectedPrice,
                  onTap: _selectPrice,
                ),
                const SizedBox(width: 10),
                _FilterChipButton(
                  icon: Icons.people_outline,
                  label: selectedGender,
                  onTap: _selectGender,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh Results"),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${results.length} rooms found",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text("Clear"),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (results.isEmpty)
            const _EmptyResult()
          else
            ...results.map(
                  (room) => RoomCard(
                imagePath: room.imagePath,
                title: room.title,
                location: room.location,
                price: "Rs. ${room.price}/month",
                gender: room.gender,
                description: room.description,
                isAvailable: room.isAvailable,
                    ownerName: room.ownerName,
                    ownerPhone: room.ownerPhone,
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search location or area",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected =
        label != "Location" && label != "Price" && label != "Gender";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE7FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? SearchScreen.primaryColor
                : const Color(0xFFE0D7FF),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: SearchScreen.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No rooms found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            "Try changing location, price, or gender filter.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}