import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_provider.dart';
import '../../../services/discovery_client.dart';
import '../../../services/api_client.dart';

class StudentConnectScreen extends StatefulWidget {
  const StudentConnectScreen({super.key});

  @override
  State<StudentConnectScreen> createState() => _StudentConnectScreenState();
}

class _StudentConnectScreenState extends State<StudentConnectScreen> {
  final _ipController = TextEditingController();
  bool _discovering = false;
  bool _connecting = false;
  String? _discoveryError;

  @override
  void initState() {
    super.initState();
    final sp = context.read<StudentProvider>();
    if (sp.serverIp != null) {
      _ipController.text = sp.serverIp!;
    }
    _autoDiscover();
  }

  Future<void> _autoDiscover() async {
    setState(() {
      _discovering = true;
      _discoveryError = null;
    });
    final ip = await DiscoveryClient.discover();
    if (!mounted) return;
    if (ip != null) {
      _ipController.text = ip;
      await context.read<StudentProvider>().setServerIp(ip);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server found at $ip')),
      );
    } else {
      setState(() => _discoveryError = 'Auto-discovery timed out. Enter IP manually.');
    }
    setState(() => _discovering = false);
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter server IP')),
      );
      return;
    }
    setState(() => _connecting = true);
    final sp = context.read<StudentProvider>();
    try {
      final client = ApiClient(serverIp: ip);
      await client.ping();
      await sp.setServerIp(ip);
      if (!mounted) return;
      if (sp.loggedIn) {
        context.go('/student/class');
      } else {
        context.push('/student/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Cannot connect to $ip. Check IP and try again.'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
    setState(() => _connecting = false);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Server'),
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.wifi_rounded, size: 72, color: cs.primary),
                  const SizedBox(height: 16),
                  Text('Connect to Admin Server',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Make sure you are connected to the admin's hotspot.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.outline)),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (_discovering)
                                Expanded(
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Searching...',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(color: cs.primary)),
                                    ],
                                  ),
                                )
                              else
                                Expanded(
                                  child: Text(
                                    _discoveryError ??
                                        (_ipController.text.isNotEmpty
                                            ? 'Server found automatically'
                                            : 'Auto-discover server'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: _discoveryError != null
                                              ? cs.error
                                              : cs.outline,
                                        ),
                                  ),
                                ),
                              TextButton.icon(
                                onPressed: _discovering ? null : _autoDiscover,
                                icon: const Icon(Icons.radar_rounded, size: 18),
                                label: const Text('Scan'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'Server IP Address',
                      hintText: '192.168.43.1',
                      prefixIcon: const Icon(Icons.router_rounded),
                      suffixText: ':3000',
                      suffixStyle: TextStyle(color: cs.outline),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _connecting ? null : _connect,
                    icon: _connecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.link_rounded),
                    label: const Text('Connect'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
