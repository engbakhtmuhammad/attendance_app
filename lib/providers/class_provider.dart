import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/repositories/class_repository.dart';
import '../models/class_model.dart';

class ClassProvider extends ChangeNotifier {
  final ClassRepository _repo;
  final _uuid = const Uuid();

  List<ClassModel> _classes = [];
  ClassModel? _activeClass;
  bool _loading = false;
  String? _error;

  ClassProvider({ClassRepository? repo}) : _repo = repo ?? ClassRepository();

  List<ClassModel> get classes => _classes;
  ClassModel? get activeClass => _activeClass;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadClasses() async {
    _loading = true;
    notifyListeners();
    try {
      _classes = await _repo.getAll();
      _activeClass = await _repo.getActive();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> addClass({
    required String name,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final cls = ClassModel(
      id: _uuid.v4(),
      name: name,
      date: date,
      startTime: startTime,
      endTime: endTime,
      isActive: false,
      createdAt: DateTime.now(),
    );
    await _repo.add(cls);
    await loadClasses();
  }

  Future<String> startSession(String classId) async {
    final token = _uuid.v4();
    await _repo.startSession(classId, token);
    await loadClasses();
    return token;
  }

  Future<void> stopSession() async {
    await _repo.stopSession();
    await loadClasses();
  }

  Future<void> deleteClass(String id) async {
    await _repo.delete(id);
    await loadClasses();
  }
}
