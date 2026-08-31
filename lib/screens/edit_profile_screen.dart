import 'package:flutter/material.dart';
import '../models/app_user_model.dart';
import '../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile, this.userService});
  final AppUserModel profile;
  final UserService? userService;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  UserService? service;
  final formKey = GlobalKey<FormState>();
  bool saving = false;
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile.fullName);
    phoneController = TextEditingController(text: widget.profile.phoneNumber);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving || !formKey.currentState!.validate()) return;
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    if (name == widget.profile.fullName &&
        phone == widget.profile.phoneNumber) {
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => saving = true);
    try {
      await (service ??= widget.userService ?? UserService())
          .updateSafeProfileFields(fullName: name, phoneNumber: phone);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated.')));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profile could not be updated. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
          key: formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            TextFormField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                maxLength: 120,
                decoration: const InputDecoration(
                    labelText: 'Full name', border: OutlineInputBorder()),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  return value.isEmpty
                      ? 'Enter your full name.'
                      : value.length > 120
                          ? 'Name must be 120 characters or fewer.'
                          : null;
                }),
            const SizedBox(height: 16),
            TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 30,
                decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                    border: OutlineInputBorder()),
                validator: (v) => (v?.trim().length ?? 0) > 30
                    ? 'Phone number must be 30 characters or fewer.'
                    : null),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.profile.email,
              readOnly: true,
              decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  helperText: 'Email changes are not available.'),
            ),
            const SizedBox(height: 16),
            TextFormField(
                initialValue: widget.profile.role,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Role', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: saving ? null : _save,
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'))
          ])));
}
