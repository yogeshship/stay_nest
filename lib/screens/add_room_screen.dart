import 'package:flutter/material.dart';
import '../services/room_service.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final RoomService _roomService = RoomService();

  bool _isSubmitting = false;

  String selectedImage = "assets/images/room1.jpeg";

  final List<String> roomImages = [
    "assets/images/room1.jpeg",
    "assets/images/room2.jpeg",
    "assets/images/room3.jpeg",
  ];

  Future<void> submitRoom() async {
    if (_isSubmitting) return;

    if (titleController.text.isEmpty ||
        locationController.text.isEmpty ||
        rentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the title, location, and rent.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final monthlyRent = num.tryParse(
      rentController.text.trim().replaceAll(',', ''),
    );
    if (monthlyRent == null || monthlyRent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid monthly rent greater than zero.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _roomService.addRoom(
        title: titleController.text,
        location: locationController.text,
        monthlyRent: monthlyRent,
        genderPreference: genderController.text.trim().isEmpty
            ? 'Any'
            : genderController.text,
        description: descriptionController.text.trim().isEmpty
            ? 'A clean and peaceful room.'
            : descriptionController.text,
        imageUrls: [selectedImage],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room listing added successfully'),
          backgroundColor: AddRoomScreen.primaryColor,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyRoomError(error)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    rentController.dispose();
    genderController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AddRoomScreen.bgColor,
      appBar: AppBar(
        backgroundColor: AddRoomScreen.bgColor,
        elevation: 0,
        title: const Text(
          "Add Room",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Choose Room Image",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 105,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: roomImages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final image = roomImages[index];
                final bool isSelected = selectedImage == image;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedImage = image;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AddRoomScreen.primaryColor
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        image,
                        height: 95,
                        width: 115,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _InputField(
            label: "Room Title",
            hint: "e.g. Peaceful room near college",
            controller: titleController,
          ),
          const SizedBox(height: 14),
          _InputField(
            label: "Location",
            hint: "e.g. Baneshwor, Kathmandu",
            controller: locationController,
          ),
          const SizedBox(height: 14),
          _InputField(
            label: "Monthly Rent",
            hint: "e.g. 8500",
            keyboardType: TextInputType.number,
            controller: rentController,
          ),
          const SizedBox(height: 14),
          _InputField(
            label: "Gender Preference",
            hint: "Boys / Girls / Any",
            controller: genderController,
          ),
          const SizedBox(height: 14),
          _InputField(
            label: "Description",
            hint: "Write room details, facilities, nearby places...",
            maxLines: 4,
            controller: descriptionController,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AddRoomScreen.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSubmitting ? null : submitRoom,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Listing',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final TextEditingController controller;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
