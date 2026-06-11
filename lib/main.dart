import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const StayNestApp());
}

class StayNestApp extends StatelessWidget {
  const StayNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StayNest',
      home: const WelcomeScreen(),
    );
  }
}