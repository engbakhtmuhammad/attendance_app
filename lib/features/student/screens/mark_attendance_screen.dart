import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_provider.dart';
import '../../../services/api_client.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _scanned = false;
  bool _marking = false;
  String? _resultMessage;
  bool _success = false;
  bool _showScanner = true;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _handleQr(String rawValue) async {
    if (_scanned || _marking) return;
    setState(() {
      _scanned = true;
      _marking = true;
      _showScanner = false;
    });
    _scanner.stop();

    try {
      final payload = jsonDecode(rawValue) as Map<String, dynamic>;
      final sessionToken = payload['sessionToken'] as String?;
      if (sessionToken == null || sessionToken.isEmpty) {
        _setResult('Invalid QR code', false);
        return;
      }
      await _markWithToken(sessionToken);
    } catch (e) {
      _setResult('Invalid QR code format', false);
    }
  }

  Future<void> _markManually() async {
    if (_marking) return;
    setState(() {
      _marking = true;
      _showScanner = false;
      _scanned = true;
    });
    await _markWithToken(null);
  }

  Future<void> _markWithToken(String? token) async {
    final sp = context.read<StudentProvider>();
    if (sp.serverIp == null) {
      _setResult('Not connected to server', false);
      return;
    }
    try {
      final client = ApiClient(
        serverIp: sp.serverIp!,
        sessionToken: token ?? sp.sessionToken,
      );
      final res = await client.markAttendance(
        userId: sp.userId!,
        deviceId: sp.deviceId!,
      );
      if (res['statusCode'] == 200) {
        _setResult('Attendance marked successfully!', true);
      } else {
        _setResult(res['error'] ?? 'Failed to mark attendance', false);
      }
    } catch (e) {
      _setResult('Connection error: $e', false);
    }
  }

  void _setResult(String msg, bool success) {
    setState(() {
      _resultMessage = msg;
      _success = success;
      _marking = false;
    });
  }

  void _reset() {
    setState(() {
      _scanned = false;
      _marking = false;
      _resultMessage = null;
      _success = false;
      _showScanner = true;
    });
    _scanner.start();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: _resultMessage != null
            ? _ResultView(
                message: _resultMessage!,
                success: _success,
                onDone: () => context.go('/student/class'),
                onRetry: _reset,
              )
            : Column(
                children: [
                  if (_showScanner)
                    Expanded(
                      child: Stack(
                        children: [
                          MobileScanner(
                            controller: _scanner,
                            onDetect: (capture) {
                              final barcode = capture.barcodes.firstOrNull;
                              if (barcode?.rawValue != null) {
                                _handleQr(barcode!.rawValue!);
                              }
                            },
                          ),
                          Center(
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: cs.primary, width: 3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                'Point camera at QR code',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_marking)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showScanner)
                          const Text(
                            'Scan the QR code displayed by admin, or tap the button below.',
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _marking ? null : _markManually,
                          icon: const Icon(Icons.touch_app_rounded),
                          label: const Text('Mark Without QR'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final String message;
  final bool success;
  final VoidCallback onDone;
  final VoidCallback onRetry;

  const _ResultView({
    required this.message,
    required this.success,
    required this.onDone,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: success ? Colors.green.withValues(alpha: 0.1) : cs.errorContainer,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 60,
                color: success ? Colors.green : cs.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              success ? 'Success!' : 'Failed',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green : cs.error),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            if (success)
              FilledButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.home_rounded),
                label: const Text('Done'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white),
              )
            else ...[
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onDone,
                child: const Text('Go Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
