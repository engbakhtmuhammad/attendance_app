import 'package:flutter/material.dart';
import '../../../core/utils/crypto_util.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/user_model.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final _repo = UserRepository();
  List<UserModel> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _students = await _repo.getAll();
    setState(() => _loading = false);
  }

  void _showAddStudentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddStudentSheet(
        onAdded: () {
          Navigator.pop(ctx);
          _load();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Student added successfully')),
            );
          }
        },
      ),
    );
  }

  Future<void> _approve(String id) async {
    await _repo.approve(id);
    _load();
  }

  Future<void> _removeStudent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student?'),
        content: const Text('This will block access for this student.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _repo.reject(id); // sets to blocked
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: cs.surface,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentSheet,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Student'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 64, color: cs.outline),
                      const SizedBox(height: 16),
                      Text('No students yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: cs.outline)),
                      const SizedBox(height: 8),
                      Text('Tap + to add a student',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: cs.outline)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: _students.length,
                  itemBuilder: (_, i) {
                    final u = _students[i];
                    return _StudentTile(
                      user: u,
                      onApprove: u.status == 'pending'
                          ? () => _approve(u.id)
                          : null,
                      onRemove: () => _removeStudent(u.id),
                    );
                  },
                ),
    );
  }
}

// ─── Student Tile ──────────────────────────────────────────────────────────

class _StudentTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onApprove;
  final VoidCallback onRemove;

  const _StudentTile({
    required this.user,
    this.onApprove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = switch (user.status) {
      'approved' => Colors.green,
      'pending' => cs.error,
      _ => cs.outline,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  Text('ID: ${user.id}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.outline)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'approve' && onApprove != null) onApprove!();
                if (v == 'remove') onRemove();
              },
              itemBuilder: (_) => [
                if (user.status == 'pending')
                  const PopupMenuItem(
                    value: 'approve',
                    child: Row(children: [
                      Icon(Icons.check_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Approve'),
                    ]),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(children: [
                    Icon(Icons.block_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Remove / Block'),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Student Bottom Sheet ──────────────────────────────────────────────

class _AddStudentSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddStudentSheet({required this.onAdded});

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  final _repo = UserRepository();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (id.isEmpty || name.isEmpty || password.isEmpty) {
      _showError('All fields are required');
      return;
    }
    if (password.length < 4) {
      _showError('Password must be at least 4 characters');
      return;
    }

    setState(() => _loading = true);
    final existing = await _repo.getById(id);
    if (!mounted) return;
    if (existing != null) {
      setState(() => _loading = false);
      _showError('Student ID already exists');
      return;
    }

    await _repo.add(UserModel(
      id: id,
      name: name,
      passwordHash: CryptoUtil.sha256Hash(password),
      deviceId: null,
      status: 'approved', // admin-created students are auto-approved
      createdAt: DateTime.now(),
    ));
    if (mounted) widget.onAdded();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.person_add_rounded, color: cs.primary),
              const SizedBox(width: 12),
              Text('Add Student',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 24),
          TextField(
            controller: _idController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Student ID',
              hintText: 'e.g. 2022-BSCS-001',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon:
                    Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loading ? null : _add,
            icon: _loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.person_add_rounded),
            label: const Text('Add Student'),
          ),
        ],
      ),
    );
  }
}
