import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class ApiClient {
  final String serverIp;
  final String? sessionToken;

  ApiClient({required this.serverIp, this.sessionToken});

  String get _base => 'http://$serverIp:${AppConstants.serverPort}/api';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // ignore: use_null_aware_elements
        if (sessionToken != null) 'X-Session-Token': sessionToken!,
      };

  Future<Map<String, dynamic>> ping() async {
    final res = await http
        .get(Uri.parse('$_base/ping'), headers: _headers)
        .timeout(AppConstants.connectTimeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> login({
    required String userId,
    required String password,
    required String deviceId,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/auth/login'),
          headers: _headers,
          body: jsonEncode({
            'userId': userId,
            'password': password,
            'deviceId': deviceId,
          }),
        )
        .timeout(AppConstants.requestTimeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> getActiveClass() async {
    final res = await http
        .get(Uri.parse('$_base/active-class'), headers: _headers)
        .timeout(AppConstants.requestTimeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> markAttendance({
    required String userId,
    required String deviceId,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/mark-attendance'),
          headers: _headers,
          body: jsonEncode({
            'userId': userId,
            'deviceId': deviceId,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        )
        .timeout(AppConstants.requestTimeout);
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return {'statusCode': res.statusCode, ...body};
  }
}
