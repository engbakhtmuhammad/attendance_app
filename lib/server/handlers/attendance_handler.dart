import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../models/attendance_model.dart';

class AttendanceHandler {
  final AttendanceRepository _attendanceRepo;
  final ClassRepository _classRepo;
  final UserRepository _userRepo;
  final _uuid = const Uuid();

  AttendanceHandler({
    AttendanceRepository? attendanceRepo,
    ClassRepository? classRepo,
    UserRepository? userRepo,
  })  : _attendanceRepo = attendanceRepo ?? AttendanceRepository(),
        _classRepo = classRepo ?? ClassRepository(),
        _userRepo = userRepo ?? UserRepository();

  // POST /api/mark-attendance
  // Headers: X-Session-Token
  // Body: { userId, deviceId, timestamp? }
  Future<Response> markAttendance(Request request) async {
    try {
      final token = request.headers['x-session-token'];
      if (token == null || token.isEmpty) {
        return _json({'error': 'Missing session token'}, 401);
      }

      // Verify active class & token
      final cls = await _classRepo.getActive();
      if (cls == null) {
        return _json({'error': 'No active session'}, 400);
      }
      if (cls.sessionToken != token) {
        return _json({'error': 'Invalid session token'}, 401);
      }

      // Rule 4: Time restriction
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      if (!cls.isTimeWithinWindow(timeStr)) {
        return _json({'error': 'Attendance window closed'}, 403);
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final userId = (body['userId'] as String?)?.trim();
      final deviceId = (body['deviceId'] as String?)?.trim();

      if (userId == null || userId.isEmpty || deviceId == null || deviceId.isEmpty) {
        return _json({'error': 'Missing userId or deviceId'}, 400);
      }

      // Validate user exists & approved
      final user = await _userRepo.getById(userId);
      if (user == null || user.status != 'approved') {
        return _json({'error': 'Unauthorized user'}, 403);
      }

      // Rule 3: Device binding
      if (user.deviceId != null && user.deviceId != deviceId) {
        return _json({'error': 'Device mismatch'}, 403);
      }

      // Rule 1: No duplicate attendance
      if (await _attendanceRepo.userAlreadyMarked(userId, cls.id)) {
        return _json({'error': 'Attendance already marked for this session'}, 409);
      }

      // Rule 2: No multiple users from same device
      if (await _attendanceRepo.deviceAlreadyUsed(deviceId, cls.id)) {
        return _json({'error': 'Another user already marked attendance from this device'}, 409);
      }

      final record = AttendanceModel(
        id: _uuid.v4(),
        userId: userId,
        deviceId: deviceId,
        classId: cls.id,
        timestamp: now,
      );
      await _attendanceRepo.add(record);

      return _json({'message': 'Attendance marked successfully', 'timestamp': now.toIso8601String()});
    } catch (e) {
      return _json({'error': 'Invalid request'}, 400);
    }
  }

  // GET /api/attendance?classId=xxx  (admin only)
  Future<Response> getAttendance(Request request) async {
    final classId = request.url.queryParameters['classId'];
    final records = classId != null
        ? await _attendanceRepo.forClass(classId)
        : await _attendanceRepo.all();

    return _json({
      'attendance': records
          .map((r) => {
                'id': r.id,
                'userId': r.userId,
                'deviceId': r.deviceId,
                'classId': r.classId,
                'timestamp': r.timestamp.toIso8601String(),
              })
          .toList()
    });
  }

  Response _json(Map<String, dynamic> body, [int status = 200]) =>
      Response(status, body: jsonEncode(body), headers: {'content-type': 'application/json'});
}
