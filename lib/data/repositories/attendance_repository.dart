import '../../models/attendance_model.dart';
import '../database/db_helper.dart';

class AttendanceRepository {
  final DbHelper _db;
  AttendanceRepository({DbHelper? db}) : _db = db ?? DbHelper.instance;

  Future<void> add(AttendanceModel record) => _db.insertAttendance(record);

  Future<bool> userAlreadyMarked(String userId, String classId) =>
      _db.existsAttendanceForUser(userId, classId);

  Future<bool> deviceAlreadyUsed(String deviceId, String classId) =>
      _db.existsAttendanceForDevice(deviceId, classId);

  Future<List<AttendanceModel>> forClass(String classId) =>
      _db.getAttendanceForClass(classId);

  Future<List<AttendanceModel>> all() => _db.getAllAttendance();
}
