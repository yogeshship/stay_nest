import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';
import 'owner_home_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  AuthGate({
    super.key,
    AuthService? authService,
    UserService? userService,
  })  : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService();

  final AuthService _authService;
  final UserService _userService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      initialData: _authService.currentUser,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) return const WelcomeScreen();

        return StreamBuilder<AppUserModel?>(
          stream: _userService.watchUserProfile(firebaseUser.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            if (profileSnapshot.hasError) {
              return _AccessProblemScreen(
                message:
                    'We could not load your StayNest profile. Check your connection and try again.',
                authService: _authService,
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return _AccessProblemScreen(
                message:
                    'This account is missing its StayNest profile. Access has been denied. Please sign out and contact StayNest support so the account can be repaired safely.',
                authService: _authService,
              );
            }
            if (profile.uid != firebaseUser.uid) {
              return _AccessProblemScreen(
                message:
                    'This profile does not match the signed-in account. Access has been denied.',
                authService: _authService,
              );
            }
            if (!profile.isActive) {
              return _AccessProblemScreen(
                message:
                    'This account is inactive. Please contact StayNest support.',
                authService: _authService,
              );
            }

            return homeForActiveRole(profile) ??
                _AccessProblemScreen(
                  message:
                      'This account has an invalid role. Access has been denied. Please contact StayNest support.',
                  authService: _authService,
                );
          },
        );
      },
    );
  }
}

Widget? homeForActiveRole(AppUserModel profile) {
  if (!profile.isActive) return null;
  return switch (profile.role) {
    AppUserModel.customerRole => const HomeScreen(),
    AppUserModel.ownerRole => const OwnerHomeScreen(),
    AppUserModel.adminRole => AdminDashboardScreen(adminUid: profile.uid),
    _ => null,
  };
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _AccessProblemScreen extends StatelessWidget {
  const _AccessProblemScreen({
    required this.message,
    required this.authService,
  });

  final String message;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 52),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authService.signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
