import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/server_provider.dart';
import '../../../providers/class_provider.dart';
import '../widgets/server_status_card.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final server = context.watch<ServerProvider>();
    final classes = context.watch<ClassProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: cs.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Exit Admin',
            onPressed: () {
              if (server.isRunning) {
                server.stopServer();
              }
              context.go('/');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ServerStatusCard(),
              const SizedBox(height: 16),
              Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _ActionsGrid(
                items: [
                  _ActionItem(
                    icon: Icons.class_rounded,
                    label: 'Manage Classes',
                    color: cs.primaryContainer,
                    onColor: cs.onPrimaryContainer,
                    onTap: () => context.push('/admin/classes'),
                  ),
                  _ActionItem(
                    icon: Icons.pending_actions_rounded,
                    label: 'Pending Users',
                    color: cs.errorContainer,
                    onColor: cs.onErrorContainer,
                    badge: null,
                    onTap: () => context.push('/admin/pending'),
                  ),
                  _ActionItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Live Attendance',
                    color: cs.tertiaryContainer,
                    onColor: cs.onTertiaryContainer,
                    onTap: () {
                      final active = classes.activeClass;
                      if (active == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No active session')),
                        );
                        return;
                      }
                      context.push('/admin/live/${active.id}');
                    },
                  ),
                  _ActionItem(
                    icon: Icons.download_rounded,
                    label: 'Export CSV',
                    color: cs.secondaryContainer,
                    onColor: cs.onSecondaryContainer,
                    onTap: () => context.push('/admin/export'),
                  ),
                ],
              ),
              if (classes.activeClass != null) ...[
                const SizedBox(height: 16),
                _ActiveSessionBanner(classes: classes),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;
  final int? badge;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
    this.badge,
    required this.onTap,
  });
}

class _ActionsGrid extends StatelessWidget {
  final List<_ActionItem> items;
  const _ActionsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: items
          .map(
            (item) => Card(
              color: item.color,
              elevation: 0,
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 36, color: item.onColor),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: item.onColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  final ClassProvider classes;
  const _ActiveSessionBanner({required this.classes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cls = classes.activeClass!;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: Colors.green, borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Session',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: cs.onPrimaryContainer)),
                  Text(cls.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
                  Text('${cls.startTime} – ${cls.endTime}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => context.push('/admin/live/${cls.id}'),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}
