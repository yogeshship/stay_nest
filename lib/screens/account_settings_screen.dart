import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen(
      {super.key,
      this.profile,
      this.userService,
      this.authService,
      this.signOutOverride});
  final AppUserModel? profile;
  final UserService? userService;
  final AuthService? authService;
  final Future<void> Function()? signOutOverride;
  @override
  Widget build(BuildContext context) {
    final auth = authService;
    if (profile != null) return _content(context, profile!, auth);
    final session = auth ?? AuthService();
    final uid = session.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
          body: Center(child: Text('Please sign in to manage your account.')));
    }
    return StreamBuilder<AppUserModel?>(
        stream: (userService ?? UserService()).watchUserProfile(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final item = snapshot.data;
          if (item == null) {
            return const Scaffold(
                body: Center(child: Text('Profile unavailable.')));
          }
          return _content(context, item, auth);
        });
  }

  Widget _content(BuildContext context, AppUserModel item, AuthService? auth) =>
      Scaffold(
          appBar: AppBar(title: const Text('Account Settings')),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            Text('Profile', style: Theme.of(context).textTheme.titleMedium),
            ListTile(
                title: Text(
                    item.fullName.isEmpty ? 'Name not set' : item.fullName),
                subtitle: Text('${item.email}\n${item.role}'),
                isThreeLine: true,
                leading: const Icon(Icons.person_outline),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                            profile: item, userService: userService)))),
            if (item.role == AppUserModel.ownerRole)
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Verification status'),
                subtitle: Text(item.verificationStatus),
              ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change password'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordScreen(
                    authService: auth ?? AuthService(),
                  ),
                ),
              ),
            ),
            const Divider(height: 32),
            ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Account status'),
                subtitle: Text(item.isActive ? 'Active' : 'Inactive')),
            ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  try {
                    await (signOutOverride ??
                        (auth ?? AuthService()).signOut)();
                  } on FirebaseAuthException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyAuthError(e))));
                    }
                  }
                })
          ]));
}
