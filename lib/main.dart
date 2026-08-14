import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final hasAuthenticatedSession = AuthService().currentUser != null;
  runApp(StayNestApp(hasAuthenticatedSession: hasAuthenticatedSession));
}

class StayNestApp extends StatelessWidget {
  const StayNestApp({
    super.key,
    this.hasAuthenticatedSession = false,
  });

  final bool hasAuthenticatedSession;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StayNest',
      theme: AppTheme.light,
      home:
          hasAuthenticatedSession ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
