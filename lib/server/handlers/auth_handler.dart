import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../core/utils/crypto_util.dart';
import '../../data/repositories/user_repository.dart';

class AuthHandler {
  final UserRepository _userRepo;
  AuthHandler({UserRepository? userRepo})
      : _userRepo = userRepo ?? UserRepository();

  // POST /api/auth/register — disabled; students are created by admin
  Future<Response> register(Request request) async {
    return _json(
        {'error': 'Self-registration is disabled. Contact your admin.'}, 403);
  }

  // POST /api/auth/login
  Future<Response> login(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final userId = (body['userId'] as String?)?.trim();
      final password = (body['password'] as String?)?.trim();
      final deviceId = (body['deviceId'] as String?)?.trim();

      if (userId == null || password == null || deviceId == null) {
        return _json({'error': 'Missing fields'}, 400);
      }

      final user = await _userRepo.getById(userId);
      if (user == null) {
        return _json({'error': 'User not found'}, 404);
      }

      if (!CryptoUtil.verifyHash(password, user.passwordHash)) {
        return _json({'error': 'Invalid password'}, 401);
      }

      if (user.status == 'pending') {
        return _json({'error': 'Pending approval', 'status': 'pending'}, 403);
      }

      if (user.status == 'blocked') {
        return _json({'error': 'Account blocked'}, 403);
      }

      // Device binding check
      if (user.deviceId != null && user.deviceId != deviceId) {
        return _json({'error': 'Device mismatch: account bound to another device'}, 403);
      }

      // Bind device if not set
      if (user.deviceId == null) {
        await _userRepo.bindDevice(userId, deviceId);
      }

      return _json({
        'message': 'Login successful',
        'userId': user.id,
        'name': user.name,
        'status': 'approved',
      });
    } catch (e) {
      return _json({'error': 'Invalid request'}, 400);
    }
  }

  Response _json(Map<String, dynamic> body, [int status = 200]) =>
      Response(status, body: jsonEncode(body), headers: {'content-type': 'application/json'});
}
