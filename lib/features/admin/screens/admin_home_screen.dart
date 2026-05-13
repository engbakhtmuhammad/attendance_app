import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/class_model.dart';
import '../../../providers/class_provider.dart';
import '../../../providers/server_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _totalStudents = 0;
  int _pendingStudents = 0;
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final server = context.read<ServerProvider>();
      if (!server.isRunning) {
        server.startServer();
      }
      context.read<ClassProvider>().loadClasses();
      _loadStats();
    });
    _statsTimer = Timer.periodic(AppConstants.pollInterval, (_) => _loadStats());
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final users = await UserRepository().getAll();
    if (!mounted) return;
    setState(() {
      _totalStudents = users.length;
      _pendingStudents = users.where((u) => u.status == 'pending').length;
    });
  }

  void _logout(ServerProvider server) {
    if (server.isRunning) server.stopServer();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final server = context.watch<ServerProvider>();
    final classes = context.watch<ClassProvider>();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, cs, server)),
            SliverToBoxAdapter(child: _buildStats(context, cs, classes)),
            if (classes.activeClass != null)
              SliverToBoxAdapter(
                child: _buildActiveSession(context, cs, classes.activeClass!),
              ),
            SliverToBoxAdapter(child: _buildActions(context, cs, classes)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ColorScheme cs, ServerProvider server) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM yyyy').format(now);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primary.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: cs.onPrimary.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Online/Offline pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: server.isRunning
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          server.isRunning ? Colors.green : Colors.redAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: server.isRunning
                              ? Colors.green
                              : Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        server.isRunning ? 'Live' : 'Offline',
                        style: TextStyle(
                          color: server.isRunning
                              ? Colors.green
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.logout_rounded, color: cs.onPrimary),
                  tooltip: 'Exit Admin',
                  onPressed: () => _logout(server),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Server toggle row
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_tethering_rounded,
                      color: cs.onPrimary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: server.isRunning && server.ip != null
                        ? Text(
                            '${server.ip}:${AppConstants.serverPort}',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          )
                        : Text(
                            'Start server to accept students',
                            style: TextStyle(
                              color: cs.onPrimary.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                  ),
                    Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: server.isRunning,
                      onChanged: (v) =>
                          v ? server.startServer() : server.stopServer(),
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(
      BuildContext context, ColorScheme cs, ClassProvider classes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.people_rounded,
            label: 'Students',
            value: '$_totalStudents',
            color: cs.primaryContainer,
            onColor: cs.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.hourglass_top_rounded,
            label: 'Pending',
            value: '$_pendingStudents',
            color: _pendingStudents > 0
                ? cs.errorContainer
                : cs.surfaceContainerHigh,
            onColor:
                _pendingStudents > 0 ? cs.onErrorContainer : cs.onSurface,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.broadcast_on_home_rounded,
            label: 'Session',
            value: classes.activeClass != null ? 'On' : 'Off',
            color: classes.activeClass != null
                ? Colors.green.withValues(alpha: 0.15)
                : cs.surfaceContainerHigh,
            onColor:
                classes.activeClass != null ? Colors.green : cs.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSession(
      BuildContext context, ColorScheme cs, ClassModel cls) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.green.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.broadcast_on_home_rounded,
                color: Colors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE SESSION',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cls.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${cls.startTime} \u2013 ${cls.endTime}',
                  style: TextStyle(color: cs.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => context.push('/admin/live/${cls.id}'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(70, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, ColorScheme cs, ClassProvider classes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'QUICK ACTIONS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.class_rounded,
                  label: 'Classes',
                  subtitle: 'Manage & schedule',
                  bgColor: cs.primaryContainer,
                  iconColor: cs.onPrimaryContainer,
                  onTap: () => context.push('/admin/classes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.people_rounded,
                  label: 'Students',
                  subtitle: 'Add & manage',
                  bgColor: cs.secondaryContainer,
                  iconColor: cs.onSecondaryContainer,
                  onTap: () => context.push('/admin/students'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Live View',
                  subtitle: 'Attendance tracker',
                  bgColor: cs.tertiaryContainer,
                  iconColor: cs.onTertiaryContainer,
                  onTap: () {
                    final active = classes.activeClass;
                    if (active == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'No active session. Start a session first.')),
                      );
                      return;
                    }
                    context.push('/admin/live/${active.id}');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.download_rounded,
                  label: 'Export',
                  subtitle: 'Download CSV',
                  bgColor: cs.surfaceContainerHigh,
                  iconColor: cs.onSurface,
                  onTap: () => context.push('/admin/export'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color onColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: onColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: onColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  color: onColor.withValues(alpha: 0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Card ───────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bgColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: iconColor.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
