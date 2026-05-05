import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/attendance_model.dart';
import '../../../models/class_model.dart';
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

  List<AttendanceModel> _records = [];
  ClassModel? _class;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final classes = await _classRepo.getAll();
    _class = classes.where((c) => c.id == widget.classId).firstOrNull;
    _records = await _attendanceRepo.forClass(widget.classId);
    setState(() => _loading = false);

    // Poll every 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _load();
    });
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
