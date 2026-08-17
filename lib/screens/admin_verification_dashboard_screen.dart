import 'package:flutter/material.dart';

import '../models/verification_request_model.dart';
import '../services/admin_verification_service.dart';
import '../services/auth_service.dart';
import '../widgets/admin_verification_request_card.dart';
import '../widgets/reject_verification_dialog.dart';

class AdminVerificationDashboardScreen extends StatefulWidget {
  const AdminVerificationDashboardScreen({
    super.key,
    this.adminVerificationService,
    this.authService,
    this.signOutOverride,
  });

  final AdminVerificationService? adminVerificationService;
  final AuthService? authService;
  final Future<void> Function()? signOutOverride;

  @override
  State<AdminVerificationDashboardScreen> createState() =>
      _AdminVerificationDashboardScreenState();
}

class _AdminVerificationDashboardScreenState
    extends State<AdminVerificationDashboardScreen> {
  late final AdminVerificationService _adminService;
  late final AuthService? _authService;
  late final Stream<List<VerificationRequestModel>> _pendingRequests;
  final Set<String> _busyOwnerIds = {};

  @override
  void initState() {
    super.initState();
    _adminService =
        widget.adminVerificationService ?? AdminVerificationService();
    _authService = widget.authService ??
        (widget.signOutOverride == null ? AuthService() : null);
    _pendingRequests = _adminService.watchPendingVerificationRequests();
  }

  Future<void> _approve(VerificationRequestModel request) async {
    if (_busyOwnerIds.contains(request.ownerId)) return;
    final ownerName = request.ownerDisplayName.trim().isEmpty
        ? 'this owner'
        : request.ownerDisplayName.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve verification request?'),
        content: Text(
          'Approve $ownerName as a verified StayNest owner?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runDecision(
      request.ownerId,
      () => _adminService.approveVerificationRequest(request.ownerId),
      'Owner verification approved.',
    );
  }

  Future<void> _reject(VerificationRequestModel request) async {
    if (_busyOwnerIds.contains(request.ownerId)) return;
    final reason = await RejectVerificationDialog.show(
      context,
      ownerDisplayName: request.ownerDisplayName.trim().isEmpty
          ? 'this owner'
          : request.ownerDisplayName.trim(),
    );
    if (reason == null || !mounted) return;
    await _runDecision(
      request.ownerId,
      () => _adminService.rejectVerificationRequest(request.ownerId, reason),
      'Owner verification rejected.',
    );
  }

  Future<void> _runDecision(
    String ownerUid,
    Future<void> Function() operation,
    String successMessage,
  ) async {
    if (_busyOwnerIds.contains(ownerUid)) return;
    setState(() => _busyOwnerIds.add(ownerUid));
    try {
      await operation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAdminVerificationError(error)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyOwnerIds.remove(ownerUid));
    }
  }

  Future<void> _signOut() async {
    try {
      final signOut = widget.signOutOverride ?? _authService!.signOut;
      await signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign out failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Management'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<VerificationRequestModel>>(
        stream: _pendingRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _DashboardMessage(
              icon: Icons.error_outline_rounded,
              title: 'Requests unavailable',
              message:
                  'Pending verification requests could not be loaded. Check your access and connection, then try again.',
            );
          }

          final requests = snapshot.data ?? const <VerificationRequestModel>[];
          if (requests.isEmpty) {
            return const _DashboardMessage(
              icon: Icons.task_alt_rounded,
              title: 'No pending requests',
              message:
                  'All owner verification requests are currently reviewed.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return AdminVerificationRequestCard(
                request: request,
                isBusy: _busyOwnerIds.contains(request.ownerId),
                onApprove: () => _approve(request),
                onReject: () => _reject(request),
              );
            },
          );
        },
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
