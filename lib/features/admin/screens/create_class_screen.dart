import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/class_provider.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<ClassProvider>().addClass(
          name: _nameController.text.trim(),
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Class'),
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Class Name',
                    hintText: 'e.g. BSCS-5A',
                    prefixIcon: Icon(Icons.class_rounded),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 20),
                Text('Date', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(DateFormat('EEE, dd MMM yyyy').format(_selectedDate)),
                ),
                const SizedBox(height: 20),
                Text('Time Slot', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickStartTime,
                        icon: const Icon(Icons.access_time_rounded),
                        label: Text(_formatTime(_startTime)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('to',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickEndTime,
                        icon: const Icon(Icons.access_time_filled_rounded),
                        label: Text(_formatTime(_endTime)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save Class'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
