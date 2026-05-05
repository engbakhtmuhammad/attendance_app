import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/user_repository.dart';
import '../models/attendance_model.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repo;
  final UserRepository _userRepo;

  List<AttendanceModel> _records = [];
  bool _loading = false;
  String? _error;
  Timer? _pollTimer;

  AttendanceProvider({AttendanceRepository? repo, UserRepository? userRepo})
      : _repo = repo ?? AttendanceRepository(),
        _userRepo = userRepo ?? UserRepository();

  List<AttendanceModel> get records => _records;
  bool get loading => _loading;
  String? get error => _error;
  int get count => _records.length;

  Future<void> loadForClass(String classId) async {
    _loading = true;
    notifyListeners();
    try {
      _records = await _repo.forClass(classId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void startPolling(String classId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      loadForClass(classId);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<String?> getUserName(String userId) async {
    final user = await _userRepo.getById(userId);
    return user?.name;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
