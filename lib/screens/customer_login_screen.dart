import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'customer_signup_screen.dart';
import 'home_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) _showError(friendlyAuthError(error));
    } finally {
      _passwordController.clear();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Login',
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Login to search and save rooms.',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 32),
                _LoginField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your email.'
                      : null,
                ),
                const SizedBox(height: 16),
                _LoginField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter password',
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your password.'
                      : null,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isSubmitting ? null : _login,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Login',
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerSignupScreen(),
                              ),
                            ),
                    child: const Text("Don't have an account? Sign up",
                        style: TextStyle(color: primaryColor)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: !obscureText,
          validator: validator,
          onFieldSubmitted: onSubmitted,
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
