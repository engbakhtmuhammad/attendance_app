import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_provider.dart';
import '../../../services/api_client.dart';

class ActiveClassScreen extends StatefulWidget {
  const ActiveClassScreen({super.key});

  @override
  State<ActiveClassScreen> createState() => _ActiveClassScreenState();
}

class _ActiveClassScreenState extends State<ActiveClassScreen> {
  Map<String, dynamic>? _classInfo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final sp = context.read<StudentProvider>();
    if (sp.serverIp == null) {
      setState(() {
        _error = 'Not connected';
        _loading = false;
      });
      return;
    }
    try {
      final res = await ApiClient(serverIp: sp.serverIp!).getActiveClass();
      if (res['statusCode'] == 200) {
        setState(() => _classInfo = res);
      } else {
        setState(() => _error = res['error'] ?? 'No active session');
      }
    } catch (e) {
      setState(() => _error = 'Connection error');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sp = context.watch<StudentProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Session'),
        backgroundColor: cs.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final router = GoRouter.of(context);
              await sp.logout();
              if (mounted) router.go('/');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: cs.primaryContainer,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primary,
                        radius: 28,
                        child: Text(
                          sp.studentName?.isNotEmpty == true
                              ? sp.studentName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sp.studentName ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: cs.onPrimaryContainer,
                                        fontWeight: FontWeight.bold)),
                            Text('ID: ${sp.userId ?? ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: cs.onPrimaryContainer
                                            .withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null) ...[
                Card(
                  color: cs.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 40, color: cs.onErrorContainer),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onErrorContainer)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ] else if (_classInfo != null) ...[
                _ClassInfoCard(info: _classInfo!),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => context.push('/student/mark'),
                  icon: const Icon(Icons.how_to_reg_rounded),
                  label: const Text('Mark Attendance'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassInfoCard extends StatelessWidget {
  final Map<String, dynamic> info;
  const _ClassInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(width: 8),
                Text('Session Active',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Text(info['name'] as String? ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.calendar_today_rounded, value: info['date'] as String? ?? ''),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.schedule_rounded,
              value:
                  '${info['startTime']} – ${info['endTime']}',
            ),
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.tag_rounded, value: 'Class ID: ${info['classId']}'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.outline),
        const SizedBox(width: 8),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}
