import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/network_util.dart';
import '../../../providers/student_provider.dart';
import '../../../services/discovery_client.dart';
import '../../../services/api_client.dart';

class StudentConnectScreen extends StatefulWidget {
  const StudentConnectScreen({super.key});

  @override
  State<StudentConnectScreen> createState() => _StudentConnectScreenState();
}

class _StudentConnectScreenState extends State<StudentConnectScreen> {
  bool _discovering = false;
  bool _connecting = false;
  bool _hasAttemptedAutoConnect = false;
  String? _discoveryError;
  String _statusMessage = 'Tap "Retry Auto Connect" to start searching.';
  bool _showManualEntry = false;
  final _manualIpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ip = context.read<StudentProvider>().serverIp;
      if ((ip?.isNotEmpty ?? false)) {
        _manualIpController.text = ip!;
      }
    });
  }

  @override
  void dispose() {
    _manualIpController.dispose();
    super.dispose();
  }

  Future<void> _connectAutomatically() async {
    if (_discovering || _connecting) return;
    setState(() {
      _hasAttemptedAutoConnect = true;
      _discovering = true;
      _connecting = true;
      _discoveryError = null;
      _statusMessage = 'Looking for the admin hotspot server...';
    });

    final sp = context.read<StudentProvider>();
    final candidateIps = <String>{
      if (sp.serverIp != null && sp.serverIp!.isNotEmpty) sp.serverIp!,
    };

    // Same-network fallbacks: gateway and subnet .1
    final wifiGatewayIp = await NetworkUtil.getWifiGatewayIp();
    if (!mounted) return;
    if (wifiGatewayIp != null && wifiGatewayIp.isNotEmpty) {
      candidateIps.add(wifiGatewayIp);
    }
    final wifiIp = await NetworkUtil.getWifiIp();
    if (!mounted) return;
    final subnetGateway = _subnetGatewayFromIp(wifiIp);
    if (subnetGateway != null) {
      candidateIps.add(subnetGateway);
    }

    // Common Android hotspot defaults fallback.
    candidateIps.addAll(const {
      '192.168.43.1',
      '192.168.137.1',
      '192.168.1.1',
      '192.168.0.1',
    });

    final discoveredIp = await DiscoveryClient.discover();
    if (!mounted) return;

    if (discoveredIp != null) {
      candidateIps.add(discoveredIp);
    }

    for (final ip in candidateIps) {
      setState(() => _statusMessage = 'Connecting through hotspot at $ip...');
      final connected = await _tryConnect(ip, sp);
      if (!mounted) return;
      if (connected) {
        setState(() {
          _discovering = false;
          _connecting = false;
          _statusMessage = 'Connected to admin hotspot.';
        });

        if (sp.loggedIn) {
          context.go('/student/class');
        } else {
          context.go('/student/login');
        }
        return;
      }
    }

    setState(() {
      _discovering = false;
      _connecting = false;
      _discoveryError =
          'No admin server found. Make sure admin hotspot + server are ON, then tap Retry Auto Connect.';
      _statusMessage = 'Waiting for manual retry.';
    });
  }

  String? _subnetGatewayFromIp(String? ip) {
    if (ip == null || ip.isEmpty) return null;
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}.1';
  }

  Future<bool> _tryConnect(String ip, StudentProvider sp) async {
    try {
      final client = ApiClient(serverIp: ip);
      await client.ping().timeout(const Duration(seconds: 4));
      await sp.setServerIp(ip);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _connectManually() async {
    final ip = _manualIpController.text.trim();
    if (ip.isEmpty) {
      _showErrorSnack('Please enter a valid IP address');
      return;
    }

    setState(() {
      _connecting = true;
      _statusMessage = 'Connecting to $ip...';
      _discoveryError = null;
    });

    final sp = context.read<StudentProvider>();
    final connected = await _tryConnect(ip, sp);
    if (!mounted) return;

    if (connected) {
      setState(() {
        _connecting = false;
        _statusMessage = 'Connected!';
      });

      if (sp.loggedIn) {
        context.go('/student/class');
      } else {
        context.go('/student/login');
      }
    } else {
      setState(() {
        _connecting = false;
        _discoveryError = 'Failed to connect to $ip. Check the IP and try again.';
      });
    }
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Hotspot'),
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Icon(Icons.wifi_rounded, size: 72, color: cs.primary),
                const SizedBox(height: 16),
                Text('Join the Admin Hotspot',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    'Once connected to the admin hotspot, the app configures automatically.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.outline)),
                const SizedBox(height: 32),

                // Status Card
                Card(
                  color: _discoveryError != null
                      ? cs.errorContainer
                      : cs.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (_discovering || _connecting)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      cs.onSecondaryContainer),
                                ),
                              )
                            else if (_discoveryError != null)
                              Icon(Icons.error_outline_rounded,
                                  color: cs.error, size: 20)
                            else
                              Icon(Icons.wifi_find_rounded,
                                  color: cs.onSecondaryContainer, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _discovering || _connecting
                                    ? 'Searching...'
                                    : _discoveryError != null
                                        ? 'Waiting for server'
                                        : 'Ready to search',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _discoveryError != null
                                      ? cs.onErrorContainer
                                      : cs.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: _discoveryError != null
                                ? cs.onErrorContainer.withValues(alpha: 0.8)
                                : cs.onSecondaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                        if (!_hasAttemptedAutoConnect && _discoveryError == null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Auto-search is paused until you press Retry Auto Connect.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSecondaryContainer.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        if (_discoveryError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _discoveryError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _discoveryError != null
                                  ? cs.onErrorContainer.withValues(alpha: 0.7)
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                if (!_showManualEntry) ...[
                  FilledButton(
                    onPressed: _discovering ? null : _connectAutomatically,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: const Text('Retry Auto Connect'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        setState(() => _showManualEntry = !_showManualEntry),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: const Text('Enter IP Manually'),
                  ),
                ] else ...[
                  Text(
                    'Enter Admin IP Address',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _manualIpController,
                    decoration: InputDecoration(
                      labelText: 'IP Address',
                      hintText: '192.168.x.x',
                      prefixIcon: const Icon(Icons.router_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_connecting,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _connecting ? null : _connectManually,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: _connecting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Connect'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _connecting
                        ? null
                        : () => setState(() => _showManualEntry = false),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: const Text('Back to Auto Connect'),
                  ),
                ],

                const SizedBox(height: 24),

                // Help text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: cs.outline),
                          const SizedBox(width: 8),
                          Text(
                            'Troubleshooting',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Join the admin\'s WiFi hotspot first\n'
                        '2. Make sure admin has started the server\n'
                        '3. If auto-connect fails, enter the IP manually\n'
                        '4. Ask your admin for the hotspot IP if needed',
                        style: TextStyle(fontSize: 11, color: cs.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
