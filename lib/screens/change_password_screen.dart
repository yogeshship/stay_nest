import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.authService});
  final AuthService? authService;
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  AuthService? service;
  final formKey = GlobalKey<FormState>();
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false,
      obscureCurrent = true,
      obscureNext = true,
      obscureConfirm = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (busy || !formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await (service ??= widget.authService ?? AuthService()).updatePassword(
          currentPassword: current.text, newPassword: next.text);
      current.clear();
      next.clear();
      confirm.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully.')));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (error) {
      current.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyPasswordChangeAuthError(error))));
      }
    } catch (error) {
      current.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error is ArgumentError || error is StateError
                ? error.toString().replaceFirst(
                    RegExp(r'^(Invalid argument|Bad state): '), '')
                : 'Password could not be changed. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  InputDecoration _decoration(
          String label, bool obscured, VoidCallback toggle) =>
      InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
              onPressed: toggle,
              icon: Icon(obscured ? Icons.visibility : Icons.visibility_off)));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Form(
          key: formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            TextFormField(
                controller: current,
                obscureText: obscureCurrent,
                autocorrect: false,
                decoration: _decoration('Current password', obscureCurrent,
                    () => setState(() => obscureCurrent = !obscureCurrent)),
                validator: (v) => v == null || v.isEmpty
                    ? 'Enter your current password.'
                    : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: next,
                obscureText: obscureNext,
                autocorrect: false,
                decoration: _decoration('New password', obscureNext,
                    () => setState(() => obscureNext = !obscureNext)),
                validator: (v) => v == null || v.length < 6
                    ? 'Password must be at least 6 characters.'
                    : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: confirm,
                obscureText: obscureConfirm,
                autocorrect: false,
                decoration: _decoration('Confirm new password', obscureConfirm,
                    () => setState(() => obscureConfirm = !obscureConfirm)),
                validator: (v) =>
                    v != next.text ? 'Passwords do not match.' : null),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: busy ? null : _submit,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Change password'))
          ])));
}
