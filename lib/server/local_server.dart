import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import '../core/constants/app_constants.dart';
import 'handlers/auth_handler.dart';
import 'handlers/class_handler.dart';
import 'handlers/attendance_handler.dart';

class LocalServer {
  HttpServer? _server;
  bool get isRunning => _server != null;

  Future<void> start() async {
    if (_server != null) return;

    final authHandler = AuthHandler();
    final classHandler = ClassHandler();
    final attendanceHandler = AttendanceHandler();

    final router = Router()
      ..get('/api/ping', _ping)
      ..post('/api/auth/register', authHandler.register)
      ..post('/api/auth/login', authHandler.login)
      ..get('/api/pending-users', classHandler.getPendingUsers)
      ..post('/api/approve-user/<id>', classHandler.handleUser)
      ..get('/api/active-class', classHandler.getActiveClass)
      ..post('/api/session/start', classHandler.startSession)
      ..post('/api/session/stop', classHandler.stopSession)
      ..post('/api/mark-attendance', attendanceHandler.markAttendance)
      ..get('/api/attendance', attendanceHandler.getAttendance);

    final pipeline = Pipeline()
        .addMiddleware(corsHeaders())
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(
      pipeline,
      InternetAddress.anyIPv4,
      AppConstants.serverPort,
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Response _ping(Request request) => Response.ok(
        jsonEncode({'status': 'ok', 'service': AppConstants.udpKey}),
        headers: {'content-type': 'application/json'},
      );
}
