import 'package:flutter/material.dart';
import '../models/app_user_model.dart';

class AdminUserCard extends StatelessWidget {
  const AdminUserCard(
      {super.key,
      required this.user,
      required this.isCurrentAdmin,
      required this.onToggle,
      required this.busy});
  final AppUserModel user;
  final bool isCurrentAdmin;
  final VoidCallback? onToggle;
  final bool busy;
  @override
  Widget build(BuildContext context) => Card(
          child: ListTile(
        title: Text(user.fullName.isEmpty ? user.email : user.fullName),
        subtitle: Text(
            '${user.role} • ${user.email}\n${user.isActive ? 'Active' : 'Inactive'} • verification: ${user.verificationStatus}'),
        isThreeLine: true,
        trailing: user.role == AppUserModel.adminRole || isCurrentAdmin
            ? const Text('Protected')
            : busy
                ? const SizedBox(
                    width: 24, height: 24, child: CircularProgressIndicator())
                : Switch(
                    value: user.isActive, onChanged: (_) => onToggle?.call()),
      ));
}
