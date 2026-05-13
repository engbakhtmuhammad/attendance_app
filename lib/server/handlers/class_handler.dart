import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/user_repository.dart';

class ClassHandler {
  final ClassRepository _classRepo;
  final UserRepository _userRepo;
  final _uuid = const Uuid();

  ClassHandler({ClassRepository? classRepo, UserRepository? userRepo})
      : _classRepo = classRepo ?? ClassRepository(),
        _userRepo = userRepo ?? UserRepository();

  // GET /api/active-class
  Future<Response> getActiveClass(Request request) async {
    final cls = await _classRepo.getActive();
    if (cls == null) {
      return _json({'error': 'No active session'}, 404);
    }
    return _json({
      'classId': cls.id,
      'name': cls.name,
      'date': cls.date,
      'startTime': cls.startTime,
      'endTime': cls.endTime,
      'sessionToken': cls.sessionToken,
    });
  }

  // POST /api/session/start  { classId }
  Future<Response> startSession(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final classId = body['classId'] as String?;
      if (classId == null || classId.isEmpty) {
        return _json({'error': 'classId required'}, 400);
      }
      final token = _uuid.v4();
      await _classRepo.startSession(classId, token);
      return _json({'message': 'Session started', 'sessionToken': token});
    } catch (e) {
      return _json({'error': 'Invalid request'}, 400);
    }
  }

  // POST /api/session/stop
  Future<Response> stopSession(Request request) async {
    await _classRepo.stopSession();
    return _json({'message': 'Session stopped'});
  }

  // GET /api/pending-users
  Future<Response> getPendingUsers(Request request) async {
    final users = await _userRepo.getPending();
    return _json({
      'users': users
          .map((u) => {'id': u.id, 'name': u.name, 'createdAt': u.createdAt.toIso8601String()})
          .toList()
    });
  }

  // POST /api/approve-user/:id  { action: 'approve'|'reject' }
  Future<Response> handleUser(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final action = body['action'] as String?;
      if (action == 'approve') {
        await _userRepo.approve(id);
        return _json({'message': 'User approved'});
      } else if (action == 'reject') {
        await _userRepo.reject(id);
        return _json({'message': 'User rejected'});
      }
      return _json({'error': 'Invalid action'}, 400);
    } catch (e) {
      return _json({'error': 'Invalid request'}, 400);
    }
  }

  Response _json(Map<String, dynamic> body, [int status = 200]) =>
      Response(status, body: jsonEncode(body), headers: {'content-type': 'application/json'});
}
