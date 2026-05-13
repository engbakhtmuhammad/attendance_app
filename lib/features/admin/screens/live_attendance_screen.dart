import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/attendance_model.dart';
import '../../../models/class_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/class_provider.dart';

class LiveAttendanceScreen extends StatefulWidget {
  final String classId;
  const LiveAttendanceScreen({super.key, required this.classId});

  @override
  State<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends State<LiveAttendanceScreen> {
  final _attendanceRepo = AttendanceRepository();
  final _classRepo = ClassRepository();
  final _userRepo = UserRepository();
  final _uuid = const Uuid();

  Timer? _poller;
  List<AttendanceModel> _records = [];
  ClassModel? _class;
  bool _loading = true;

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
      setState(() => _loading = true);
    }
    final classes = await _classRepo.getAll();
    _class = classes.where((c) => c.id == widget.classId).firstOrNull;
    _records = await _attendanceRepo.forClass(widget.classId);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final classProvider = context.watch<ClassProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_class?.name ?? 'Attendance'),
        backgroundColor: cs.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Mark Manually',
            onPressed: _markManualAttendance,
          ),
          if (_class != null)
            IconButton(
              icon: const Icon(Icons.qr_code_rounded),
              tooltip: 'Show QR',
              onPressed: _showQr,
            ),
        ],
      ),
      body: _loading && _records.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _SessionBar(
                  cls: _class,
                  onStart: () async {
                    await classProvider.startSession(widget.classId);
                    _load();
                  },
                  onStop: () async {
                    await classProvider.stopSession();
                    _load();
                  },
                ),
                Expanded(
                  child: _records.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline_rounded,
                                  size: 64, color: cs.outline),
                              const SizedBox(height: 12),
                              Text('No attendance yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: cs.outline)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          itemBuilder: (_, i) => _AttendanceTile(
                            record: _records[i],
                            userRepo: _userRepo,
                            index: i + 1,
                          ),
                        ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_rounded, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                '${_records.length} present',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.bold),
              ),
              if (_loading) ...[
                const SizedBox(width: 12),
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showQr() {
    if (_class == null) return;
    final payload = jsonEncode({
      'classId': _class!.id,
      'sessionToken': _class!.sessionToken ?? '',
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scan to Mark Attendance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_class!.name,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 24),
            if (_class!.sessionToken == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Start the session first to show QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else
              QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 260,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _markManualAttendance() async {
    if (_class == null || !(_class!.isActive)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start class session first.')),
      );
      return;
    }

    final approved = await _userRepo.getApproved();
    final markedIds = _records.map((r) => r.userId).toSet();
    final available = approved.where((u) => !markedIds.contains(u.id)).toList();

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All approved students are already marked.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mark Attendance Manually',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (_, i) => _ManualStudentTile(
                  user: available[i],
                  onTap: () => _confirmManualMark(available[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmManualMark(UserModel user) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Attendance'),
        content: Text('Mark ${user.name} (${user.id}) as present now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mark')),
        ],
      ),
    );

    if (proceed != true) return;

    final already = await _attendanceRepo.userAlreadyMarked(user.id, widget.classId);
    if (already) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student is already marked.')),
      );
      return;
    }

    await _attendanceRepo.add(
      AttendanceModel(
        id: _uuid.v4(),
        userId: user.id,
        deviceId: 'admin-manual-${user.id}',
        classId: widget.classId,
        timestamp: DateTime.now(),
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    await _load(showLoading: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.name} marked present by admin.')),
    );
  }
}

class _ManualStudentTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _ManualStudentTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(color: cs.onPrimaryContainer),
          ),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('ID: ${user.id}'),
        trailing: const Icon(Icons.how_to_reg_rounded),
      ),
    );
  }
}

class _SessionBar extends StatelessWidget {
  final ClassModel? cls;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _SessionBar({required this.cls, required this.onStart, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = cls?.isActive ?? false;
    return Container(
      color: isActive ? Colors.green.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : cs.outline,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isActive
                ? 'Session Active  ${cls!.startTime}–${cls!.endTime}'
                : 'Session Stopped',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.green.shade800 : cs.outline),
          ),
          const Spacer(),
          isActive
              ? OutlinedButton(
                  onPressed: onStop,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error),
                      minimumSize: const Size(0, 36)),
                  child: const Text('Stop'),
                )
              : FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                  child: const Text('Start'),
                ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatefulWidget {
  final AttendanceModel record;
  final UserRepository userRepo;
  final int index;

  const _AttendanceTile({
    required this.record,
    required this.userRepo,
    required this.index,
  });

  @override
  State<_AttendanceTile> createState() => _AttendanceTileState();
}

class _AttendanceTileState extends State<_AttendanceTile> {
  String? _name;

  @override
  void initState() {
    super.initState();
    widget.userRepo.getById(widget.record.userId).then((u) {
      if (mounted) setState(() => _name = u?.name ?? widget.record.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time = widget.record.timestamp;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text('${widget.index}',
              style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
        ),
        title: Text(_name ?? '...', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('ID: ${widget.record.userId}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(timeStr,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
          ],
        ),
      ),
    );
  }
}
