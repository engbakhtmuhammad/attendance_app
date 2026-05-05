import 'package:flutter/material.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/user_model.dart';

class PendingUsersScreen extends StatefulWidget {
  const PendingUsersScreen({super.key});

  @override
  State<PendingUsersScreen> createState() => _PendingUsersScreenState();
}

class _PendingUsersScreenState extends State<PendingUsersScreen> {
  final _repo = UserRepository();
  List<UserModel> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _pending = await _repo.getPending();
    setState(() => _loading = false);
  }

  Future<void> _approve(String id) async {
    await _repo.approve(id);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved')),
      );
    }
  }

  Future<void> _reject(String id) async {
    await _repo.reject(id);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User rejected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Registrations'),
        backgroundColor: cs.surface,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.how_to_reg_outlined, size: 64, color: cs.outline),
                      const SizedBox(height: 16),
                      Text('No pending requests',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: cs.outline)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pending.length,
                  itemBuilder: (_, i) {
                    final u = _pending[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  child: Text(
                                    u.name.isNotEmpty
                                        ? u.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(color: cs.onPrimaryContainer),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(u.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      Text('ID: ${u.id}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: cs.outline)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (u.deviceId != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone_android_rounded,
                                      size: 14, color: cs.outline),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(u.deviceId!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: cs.outline,
                                                fontFamily: 'monospace'),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _reject(u.id),
                                    icon: const Icon(Icons.close_rounded),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: cs.error,
                                      side: BorderSide(color: cs.error),
                                      minimumSize: const Size(0, 40),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => _approve(u.id),
                                    icon: const Icon(Icons.check_rounded),
                                    label: const Text('Approve'),
                                    style: FilledButton.styleFrom(
                                        minimumSize: const Size(0, 40)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
