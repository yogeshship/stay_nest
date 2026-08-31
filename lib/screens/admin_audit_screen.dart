import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/admin_action_model.dart';
import '../services/admin_audit_service.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key, this.service});
  final AdminAuditService? service;
  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  late final AdminAuditService service;
  final actions = <AdminActionModel>[];
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool loading = true, loadingMore = false, hasMore = true;
  String? error;
  @override
  void initState() {
    super.initState();
    service = widget.service ?? AdminAuditService();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (!hasMore || loadingMore || loading)) return;
    setState(() {
      if (more) {
        loadingMore = true;
      } else {
        loading = true;
        actions.clear();
        cursor = null;
        hasMore = true;
      }
      error = null;
    });
    try {
      final page = await service.loadActions(startAfter: more ? cursor : null);
      if (!mounted) return;
      setState(() {
        actions.addAll(page.actions);
        cursor = page.cursor;
        hasMore = page.hasMore;
      });
    } catch (_) {
      if (mounted) setState(() => error = 'Audit history could not be loaded.');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
            ? Center(child: Text(error!))
            : actions.isEmpty
                ? const Center(child: Text('No operational actions recorded.'))
                : ListView(children: [
                    ...actions.map((a) => ListTile(
                        title: Text(a.actionType),
                        subtitle:
                            Text('${a.targetType}/${a.targetId}\n${a.reason}'),
                        isThreeLine: true,
                        trailing: Text(a.createdAt
                                ?.toLocal()
                                .toString()
                                .split('.')
                                .first ??
                            'Pending'))),
                    if (loadingMore)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()))
                    else if (hasMore)
                      TextButton(
                          onPressed: () => _load(more: true),
                          child: const Text('Load more'))
                    else
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('End of history.')))
                  ]);
    return Scaffold(
        appBar: AppBar(title: const Text('Audit History'), actions: [
          IconButton(onPressed: () => _load(), icon: const Icon(Icons.refresh))
        ]),
        body: body);
  }
}
