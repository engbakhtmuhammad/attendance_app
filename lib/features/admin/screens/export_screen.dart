import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/class_model.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _classRepo = ClassRepository();
  final _attendanceRepo = AttendanceRepository();
  final _userRepo = UserRepository();

  List<ClassModel> _classes = [];
  ClassModel? _selected;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _classRepo.getAll().then((c) => setState(() => _classes = c));
  }

  Future<void> _export() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      final records = await _attendanceRepo.forClass(_selected!.id);
      final users = await _userRepo.getAll();
      final userMap = {for (final u in users) u.id: u.name};

      final rows = [
        ['#', 'Student ID', 'Student Name', 'Class', 'Date', 'Time'],
        for (var i = 0; i < records.length; i++)
          [
            i + 1,
            records[i].userId,
            userMap[records[i].userId] ?? records[i].userId,
            _selected!.name,
            DateFormat('yyyy-MM-dd').format(records[i].timestamp),
            DateFormat('HH:mm:ss').format(records[i].timestamp),
          ],
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final filename =
          'attendance_${_selected!.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(file.path)],
          subject: 'Attendance – ${_selected!.name}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Attendance'),
        backgroundColor: cs.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.download_rounded, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text('Select a class to export its attendance as CSV.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            DropdownButtonFormField<ClassModel>(
              decoration: const InputDecoration(
                labelText: 'Class',
                prefixIcon: Icon(Icons.class_rounded),
              ),
              initialValue: _selected,
              items: _classes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selected = v),
              hint: const Text('Choose class'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading || _selected == null ? null : _export,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.share_rounded),
              label: const Text('Export & Share CSV'),
            ),
          ],
        ),
      ),
    );
  }
}
