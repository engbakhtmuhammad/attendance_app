import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/student_provider.dart';
import '../../../services/api_client.dart';

class ActiveClassScreen extends StatefulWidget {
  const ActiveClassScreen({super.key});

  @override
  State<ActiveClassScreen> createState() => _ActiveClassScreenState();
}

class _ActiveClassScreenState extends State<ActiveClassScreen> {
  Timer? _poller;
  Map<String, dynamic>? _classInfo;
  bool _loading = true;
  bool _marking = false;
  String? _markedClassId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _poller = Timer.periodic(AppConstants.pollInterval, (_) {
      if (mounted) {
        _load(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final sp = context.read<StudentProvider>();
    if (sp.serverIp == null) {
      setState(() {
        _error = 'Not connected';
        _classInfo = null;
        _loading = false;
      });
      return;
    }
    try {
      final res = await ApiClient(serverIp: sp.serverIp!).getActiveClass();
      if (res['statusCode'] == 200) {
        await sp.setSessionToken(res['sessionToken'] as String?);
        if (!mounted) return;
        setState(() {
          _classInfo = res;
          _error = null;
          if (_markedClassId != res['classId']) {
            _markedClassId = null;
          }
        });
      } else {
        await sp.setSessionToken(null);
        if (!mounted) return;
        setState(() {
          _classInfo = null;
          _error = res['error'] ?? 'No active session';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _classInfo = null;
        _error = 'Connection error';
      });
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _markAttendance() async {
    if (_marking) return;

    final sp = context.read<StudentProvider>();
    final token = sp.sessionToken;
    if (sp.serverIp == null || token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active attendance session is available right now.')),
      );
      return;
    }

    setState(() => _marking = true);
    try {
      final client = ApiClient(serverIp: sp.serverIp!, sessionToken: token);
      final res = await client.markAttendance(userId: sp.userId!, deviceId: sp.deviceId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] as String? ?? res['error'] as String? ?? 'Attendance updated.'),
          backgroundColor: res['statusCode'] == 200
              ? Colors.green
              : Theme.of(context).colorScheme.error,
        ),
      );
      if (res['statusCode'] == 200) {
        setState(() => _markedClassId = _classInfo?['classId'] as String?);
      } else {
        await _load(showLoading: false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not mark attendance. $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _marking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sp = context.watch<StudentProvider>();
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: cs.primaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
              const SizedBox(height: 18),
              Text(
                'Today\'s Attendance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
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
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _marking || _markedClassId == _classInfo?['classId']
                      ? null
                      : _markAttendance,
                  icon: const Icon(Icons.how_to_reg_rounded),
                  label: Text(
                    _marking
                        ? 'Marking Attendance...'
                        : _markedClassId == _classInfo?['classId']
                            ? 'Attendance Marked'
                            : 'Mark Attendance Now',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/student/mark'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Use QR Scanner'),
                ),
                const SizedBox(height: 12),
                Text(
                  'You can mark attendance once per active class session.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline),
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
