import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/class_provider.dart';
import '../../../models/class_model.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
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
    final provider = context.watch<ClassProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        backgroundColor: cs.surface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/classes/create');
          if (context.mounted) context.read<ClassProvider>().loadClasses();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Class'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_outlined, size: 64, color: cs.outline),
                      const SizedBox(height: 16),
                      Text('No classes yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: cs.outline)),
                      const SizedBox(height: 8),
                      Text('Tap + to create one',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: cs.outline)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: provider.classes.length,
                  itemBuilder: (_, i) => _ClassTile(
                    cls: provider.classes[i],
                    onStart: () => _startSession(provider.classes[i]),
                    onStop: () => provider.stopSession(),
                    onDelete: () => _deleteClass(provider.classes[i].id),
                    onView: () =>
                        context.push('/admin/live/${provider.classes[i].id}'),
                  ),
                ),
    );
  }

  Future<void> _startSession(ClassModel cls) async {
    final provider = context.read<ClassProvider>();
    await provider.startSession(cls.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session started for ${cls.name}')),
      );
    }
  }

  Future<void> _deleteClass(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ClassProvider>().deleteClass(id);
    }
  }
}

class _ClassTile extends StatelessWidget {
  final ClassModel cls;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _ClassTile({
    required this.cls,
    required this.onStart,
    required this.onStop,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(cls.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (cls.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Active',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text(cls.date,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline)),
                const SizedBox(width: 16),
                Icon(Icons.schedule_rounded, size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text('${cls.startTime} – ${cls.endTime}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Attendance'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38)),
                ),
                const SizedBox(width: 8),
                cls.isActive
                    ? FilledButton.tonal(
                        onPressed: onStop,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(cs.errorContainer),
                          foregroundColor: WidgetStatePropertyAll(cs.onErrorContainer),
                        ),
                        child: const Text('Stop'),
                      )
                    : FilledButton(
                        onPressed: onStart,
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                        child: const Text('Start'),
                      ),
                const Spacer(),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
