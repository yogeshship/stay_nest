import 'package:flutter/material.dart';
import '../models/admin_action_model.dart';
import '../services/admin_audit_service.dart';
import '../services/admin_room_service.dart';
import '../services/admin_verification_service.dart';
import '../widgets/admin_metric_card.dart';
import 'admin_audit_screen.dart';
import 'admin_rooms_screen.dart';
import 'admin_users_screen.dart';
import 'admin_verification_dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen(
      {super.key,
      required this.adminUid,
      this.auditService,
      this.roomService,
      this.verificationService,
      this.signOut});
  final String adminUid;
  final AdminAuditService? auditService;
  final AdminRoomService? roomService;
  final AdminVerificationService? verificationService;
  final Future<void> Function()? signOut;
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int index = 0;
  late final AdminAuditService audit;
  late final AdminRoomService rooms;
  late final AdminVerificationService verification;
  @override
  void initState() {
    super.initState();
    audit = widget.auditService ?? AdminAuditService();
    rooms = widget.roomService ?? AdminRoomService();
    verification = widget.verificationService ?? AdminVerificationService();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _Overview(audit: audit, rooms: rooms),
      AdminVerificationDashboardScreen(
          adminVerificationService: verification,
          signOutOverride: widget.signOut),
      AdminUsersScreen(adminUid: widget.adminUid),
      AdminRoomsScreen(service: rooms),
      AdminAuditScreen(service: audit),
    ];
    return Scaffold(
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
              NavigationDestination(
                  icon: Icon(Icons.verified_user_outlined),
                  label: 'Verification'),
              NavigationDestination(
                  icon: Icon(Icons.people_outline), label: 'Users'),
              NavigationDestination(
                  icon: Icon(Icons.home_work_outlined), label: 'Listings'),
              NavigationDestination(icon: Icon(Icons.history), label: 'Audit')
            ]));
  }
}

class _Overview extends StatefulWidget {
  const _Overview({required this.audit, required this.rooms});
  final AdminAuditService audit;
  final AdminRoomService rooms;
  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> {
  bool loading = true;
  int available = 0;
  int unavailable = 0;
  List<AdminActionModel> actions = const [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.rooms.loadRooms(isAvailable: true, limit: 100),
        widget.rooms.loadRooms(isAvailable: false, limit: 100),
        widget.audit.loadActions(limit: 5)
      ]);
      if (mounted) {
        setState(() {
          available = (results[0] as AdminRoomPage).rooms.length;
          unavailable = (results[1] as AdminRoomPage).rooms.length;
          actions = (results[2] as AdminActionPage).actions;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Platform Overview')),
          body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Platform Overview')),
        body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const Text(
                  'Operational snapshot (loaded pages, not global aggregates).'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: AdminMetricCard(
                        label: 'Available listings',
                        value: available,
                        icon: Icons.check_circle_outline)),
                Expanded(
                    child: AdminMetricCard(
                        label: 'Unavailable listings',
                        value: unavailable,
                        icon: Icons.pause_circle_outline))
              ]),
              const SizedBox(height: 16),
              const Text('Recent admin actions',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...actions.map((a) => ListTile(
                  title: Text(a.actionType),
                  subtitle: Text('${a.targetType}/${a.targetId}')))
            ])));
  }
}
