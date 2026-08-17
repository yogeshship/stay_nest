import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/room_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

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
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  String? _submitStatus;
  final List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _recoverLostImages();
  }

  Future<void> _recoverLostImages() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final response = await _imagePicker.retrieveLostData();
      if (response.isEmpty || response.files == null || !mounted) return;
      _addSelectedImages(response.files!);
    } catch (_) {
      // The owner can still reopen the gallery if Android has no lost result.
    }
  }

  Future<void> _pickImages() async {
    if (_isSubmitting) return;
    final remaining = StorageService.maximumRoomImages - _selectedImages.length;
    if (remaining <= 0) {
      _showError(
          'You can select up to ${StorageService.maximumRoomImages} images.');
      return;
    }

    try {
      final images = remaining == 1
          ? <XFile>[
              if (await _imagePicker.pickImage(source: ImageSource.gallery)
                  case final XFile image)
                image,
            ]
          : await _imagePicker.pickMultiImage(limit: remaining);
      if (!mounted) return;
      _addSelectedImages(images);
    } catch (_) {
      if (!mounted) return;
      _showError('Photos could not be selected. Please try again.');
    }
  }

  void _addSelectedImages(List<XFile> images) {
    final existingPaths = _selectedImages.map((image) => image.path).toSet();
    final additions = images
        .where((image) => existingPaths.add(image.path))
        .take(StorageService.maximumRoomImages - _selectedImages.length);
    setState(() => _selectedImages.addAll(additions));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

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

    if (_selectedImages.isEmpty) {
      _showError('Please choose at least one real room photo.');
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

    setState(() {
      _isSubmitting = true;
      _submitStatus = 'Uploading images…';
    });
    String? roomId;
    var imageUrls = <String>[];
    try {
      final owner = AuthService().currentUser;
      final profile =
          owner == null ? null : await UserService().getUserProfile(owner.uid);
      if (profile?.isVerifiedOwner != true) {
        throw StateError(
          'Owner verification approval is required before adding a room.',
        );
      }
      roomId = _roomService.createRoomId();
      imageUrls = await _storageService.uploadRoomImages(
        roomId: roomId,
        images: _selectedImages,
      );
      if (mounted) setState(() => _submitStatus = 'Saving listing…');
      await _roomService.addRoomWithId(
        roomId: roomId,
        title: titleController.text,
        location: locationController.text,
        monthlyRent: monthlyRent,
        genderPreference: genderController.text.trim().isEmpty
            ? 'Any'
            : genderController.text,
        description: descriptionController.text.trim().isEmpty
            ? 'A clean and peaceful room.'
            : descriptionController.text,
        imageUrls: imageUrls,
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
      Object errorToShow = error;
      if (imageUrls.isNotEmpty && roomId != null) {
        try {
          await _storageService.deleteRoomImages(roomId: roomId);
        } catch (_) {
          errorToShow = StateError(
            'The listing was not created, but some uploaded images could not be cleaned up. Please try again or contact support.',
          );
        }
      }
      if (!mounted) return;
      _showError(
        imageUrls.isEmpty
            ? friendlyStorageError(errorToShow)
            : errorToShow is StateError
                ? friendlyStorageError(errorToShow)
                : friendlyRoomError(errorToShow),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitStatus = null;
        });
      }
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
            "Room Photos",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              _selectedImages.isEmpty
                  ? 'Choose from gallery'
                  : 'Add more photos (${_selectedImages.length}/${StorageService.maximumRoomImages})',
            ),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 105,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final image = _selectedImages[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(image.path),
                          height: 100,
                          width: 115,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 100,
                            width: 115,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 17,
                            color: Colors.white,
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(
                                      () => _selectedImages.removeAt(index),
                                    ),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
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
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _submitStatus ?? 'Saving…',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
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
