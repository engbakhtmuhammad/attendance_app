import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_provider.dart';
import '../../../services/api_client.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  Timer? _timer;
  String _status = 'Waiting for admin approval...';

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final sp = context.read<StudentProvider>();
    if (sp.serverIp == null || sp.userId == null) return;
    try {
      final client = ApiClient(serverIp: sp.serverIp!);
      // Re-attempt login to check if approved
      final res = await client.login(
        userId: sp.userId!,
        password: '', // intentionally wrong — we just need to check status field
        deviceId: sp.deviceId!,
      );
      // If approved, server returns status != 'pending' (password wrong → 401)
      // Pending returns 403 with status:'pending'
      // Approved with wrong password returns 401 (not pending anymore)
      if (res['statusCode'] != 403 || res['status'] != 'pending') {
        if (mounted) {
          setState(() => _status = 'Approved! Redirecting...');
          _timer?.cancel();
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) context.go('/student/login');
        }
      }
    } catch (_) {
      setState(() => _status = 'Checking approval status...');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sp = context.watch<StudentProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(Icons.hourglass_top_rounded,
                      size: 48, color: cs.primary),
                ),
                const SizedBox(height: 32),
                Text('Pending Approval',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Hi ${sp.studentName ?? ''}! Your registration is pending admin approval.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_status,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.outline)),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () {
                    _timer?.cancel();
                    context.go('/');
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
