import 'package:flutter/material.dart';

class OwnerVerificationRequestScreen extends StatelessWidget {
  const OwnerVerificationRequestScreen({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          "Owner Verification",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Request owner access",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Submit your property details. StayNest will verify before giving owner access.",
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),

            const SizedBox(height: 28),

            const _RequestField(label: "Full Name", hint: "Enter your name"),
            const SizedBox(height: 14),

            const _RequestField(label: "Phone Number", hint: "98XXXXXXXX"),
            const SizedBox(height: 14),

            const _RequestField(label: "Property Location", hint: "e.g. Baneshwor, Kathmandu"),
            const SizedBox(height: 14),

            const _RequestField(
              label: "Number of Rooms",
              hint: "e.g. 3",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),

            const _RequestField(
              label: "Message",
              hint: "Tell us about your property...",
              maxLines: 4,
            ),

            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Verification request submitted"),
                      backgroundColor: primaryColor,
                    ),
                  );

                  Navigator.pop(context);
                },
                child: const Text(
                  "Submit Request",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _RequestField extends StatelessWidget {
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  const _RequestField({
    required this.label,
    required this.hint,
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