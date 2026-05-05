import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/server_provider.dart';

class ServerStatusCard extends StatelessWidget {
  const ServerStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final server = context.watch<ServerProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_tethering_rounded,
                    color: server.isRunning ? Colors.green : cs.outline),
                const SizedBox(width: 12),
                Text(
                  server.isRunning ? 'Server Running' : 'Server Stopped',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            server.isRunning ? Colors.green : cs.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                Switch(
                  value: server.isRunning,
                  onChanged: (v) =>
                      v ? server.startServer() : server.stopServer(),
                ),
              ],
            ),
            if (server.isRunning && server.ip != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.router_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${server.ip}:3000',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                    ),
                    const Spacer(),
                    Text('Share with students',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.outline)),
                  ],
                ),
              ),
            ],
            if (server.error != null) ...[
              const SizedBox(height: 8),
              Text(server.error!,
                  style: TextStyle(color: cs.error, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
