import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/app_user_model.dart';
import '../services/admin_user_service.dart';
import '../widgets/admin_reason_dialog.dart';
import '../widgets/admin_user_card.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, this.service, required this.adminUid});
  final AdminUserService? service;
  final String adminUid;
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final AdminUserService service;
  final users = <AppUserModel>[];
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  String? roleFilter;
  bool? activeFilter;
  bool loading = true, loadingMore = false, hasMore = true;
  String? error;
  final busy = <String>{};
  @override
  void initState() {
    super.initState();
    service = widget.service ?? AdminUserService();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (!hasMore || loadingMore || loading)) return;
    setState(() {
      if (more) {
        loadingMore = true;
      } else {
        loading = true;
        users.clear();
        cursor = null;
        hasMore = true;
      }
      error = null;
    });
    try {
      final page = await service.loadUsers(
          role: roleFilter,
          isActive: activeFilter,
          startAfter: more ? cursor : null);
      if (!mounted) return;
      setState(() {
        users.addAll(page.users);
        cursor = page.cursor;
        hasMore = page.hasMore;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Users could not be loaded. Please retry.');
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  Future<void> _filter({String? role, bool? active}) async {
    setState(() {
      roleFilter = role;
      activeFilter = active;
      users.clear();
      cursor = null;
      hasMore = true;
    });
    await _load();
  }

  Future<void> _toggle(AppUserModel user) async {
    if (busy.contains(user.uid)) return;
    final reason = await AdminReasonDialog.show(context,
        title: user.isActive ? 'Deactivate user?' : 'Reactivate user?',
        description: 'This is reversible. Enter an operational reason.');
    if (reason == null || !mounted) return;
    setState(() => busy.add(user.uid));
    try {
      await service.setUserActive(
          userId: user.uid, isActive: !user.isActive, reason: reason);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User action could not be saved.')));
      }
    } finally {
      if (mounted) setState(() => busy.remove(user.uid));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(spacing: 8, children: [
              FilterChip(
                  label: const Text('Customers'),
                  selected: roleFilter == AppUserModel.customerRole,
                  onSelected: (v) => _filter(
                      role: v ? AppUserModel.customerRole : null,
                      active: activeFilter)),
              FilterChip(
                  label: const Text('Owners'),
                  selected: roleFilter == AppUserModel.ownerRole,
                  onSelected: (v) => _filter(
                      role: v ? AppUserModel.ownerRole : null,
                      active: activeFilter)),
              FilterChip(
                  label: const Text('Inactive'),
                  selected: activeFilter == false,
                  onSelected: (v) =>
                      _filter(role: roleFilter, active: v ? false : null)),
              TextButton(onPressed: () => _load(), child: const Text('Refresh'))
            ])),
        Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text(error!))
                    : users.isEmpty
                        ? const Center(child: Text('No users found.'))
                        : ListView.builder(
                            itemCount: users.length + 1,
                            itemBuilder: (_, i) => i < users.length
                                ? AdminUserCard(
                                    user: users[i],
                                    isCurrentAdmin:
                                        users[i].uid == widget.adminUid,
                                    onToggle: () => _toggle(users[i]),
                                    busy: busy.contains(users[i].uid))
                                : loadingMore
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                            child: CircularProgressIndicator()))
                                    : hasMore
                                        ? TextButton(
                                            onPressed: () => _load(more: true),
                                            child: const Text('Load more'))
                                        : const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Center(
                                                child:
                                                    Text('End of results.')))))
      ]));
}
