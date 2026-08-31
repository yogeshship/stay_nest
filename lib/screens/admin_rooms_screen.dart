import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../services/admin_room_service.dart';
import '../widgets/admin_reason_dialog.dart';
import '../widgets/admin_room_card.dart';

class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key, this.service});
  final AdminRoomService? service;
  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  late final AdminRoomService service;
  final rooms = <RoomModel>[];
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool? filter;
  bool loading = true, loadingMore = false, hasMore = true;
  String? error;
  final busy = <String>{};
  @override
  void initState() {
    super.initState();
    service = widget.service ?? AdminRoomService();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (!hasMore || loadingMore || loading)) return;
    setState(() {
      if (more) {
        loadingMore = true;
      } else {
        loading = true;
        rooms.clear();
        cursor = null;
        hasMore = true;
      }
      error = null;
    });
    try {
      final page = await service.loadRooms(
          isAvailable: filter, startAfter: more ? cursor : null);
      if (!mounted) return;
      setState(() {
        rooms.addAll(page.rooms);
        cursor = page.cursor;
        hasMore = page.hasMore;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Listings could not be loaded. Please retry.');
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

  Future<void> _filter(bool? value) async {
    setState(() {
      filter = value;
      rooms.clear();
      cursor = null;
      hasMore = true;
    });
    await _load();
  }

  Future<void> _toggle(RoomModel room) async {
    if (busy.contains(room.id)) return;
    final next = !room.isAvailable;
    final reason = await AdminReasonDialog.show(context,
        title: next ? 'Restore availability?' : 'Set listing unavailable?',
        description:
            'This changes the listing’s current availability, but a verified owner can change availability again. It is not an enforceable platform suspension.');
    if (reason == null || !mounted) return;
    setState(() => busy.add(room.id));
    try {
      await service.setRoomAvailability(
          roomId: room.id, isAvailable: next, reason: reason);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Availability override could not be saved.')));
      }
    } finally {
      if (mounted) setState(() => busy.remove(room.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Listings')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(spacing: 8, children: [
              FilterChip(
                  label: const Text('Available'),
                  selected: filter == true,
                  onSelected: (v) => _filter(v ? true : null)),
              FilterChip(
                  label: const Text('Unavailable'),
                  selected: filter == false,
                  onSelected: (v) => _filter(v ? false : null)),
              TextButton(onPressed: () => _load(), child: const Text('Refresh'))
            ])),
        Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text(error!))
                    : rooms.isEmpty
                        ? const Center(child: Text('No listings found.'))
                        : ListView(children: [
                            ...rooms.map((r) => AdminRoomCard(
                                room: r,
                                onToggle: () => _toggle(r),
                                busy: busy.contains(r.id))),
                            if (loadingMore)
                              const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                      child: CircularProgressIndicator()))
                            else if (hasMore)
                              TextButton(
                                  onPressed: () => _load(more: true),
                                  child: const Text('Load more'))
                            else
                              const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: Text('End of results.')))
                          ]))
      ]));
}
