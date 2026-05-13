import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/device_id_util.dart';

class StudentProvider extends ChangeNotifier {
  String? _serverIp;
  String? _userId;
  String? _studentName;
  String? _deviceId;
  String? _sessionToken;
  String? _lastUserId;
  String? _lastPassword;
  bool _loggedIn = false;
  bool _initialized = false;

  String? get serverIp => _serverIp;
  String? get userId => _userId;
  String? get studentName => _studentName;
  String? get deviceId => _deviceId;
  String? get sessionToken => _sessionToken;
  String? get lastUserId => _lastUserId;
  String? get lastPassword => _lastPassword;
  bool get loggedIn => _loggedIn;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString(AppConstants.kServerIp);
    _userId = prefs.getString(AppConstants.kStudentUserId);
    _studentName = prefs.getString(AppConstants.kStudentName);
    _deviceId = prefs.getString(AppConstants.kStudentDeviceId);
    _sessionToken = prefs.getString(AppConstants.kSessionToken);
    _lastUserId = prefs.getString(AppConstants.kStudentLastUserId);
    _lastPassword = prefs.getString(AppConstants.kStudentLastPassword);
    final storedLoggedIn = prefs.getBool(AppConstants.kStudentLoggedIn) ?? false;

    _deviceId ??= await DeviceIdUtil.getDeviceId();
    if (prefs.getString(AppConstants.kStudentDeviceId) == null) {
      await prefs.setString(AppConstants.kStudentDeviceId, _deviceId!);
    }

    _loggedIn = storedLoggedIn && _userId != null && _userId!.isNotEmpty;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setServerIp(String ip) async {
    _serverIp = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kServerIp, ip);
    notifyListeners();
  }

  Future<void> setSessionToken(String? token) async {
    _sessionToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(AppConstants.kSessionToken);
    } else {
      await prefs.setString(AppConstants.kSessionToken, token);
    }
    notifyListeners();
  }

  Future<void> setLoggedIn({
    required String userId,
    required String name,
    required String sessionToken,
    String? password,
  }) async {
    _userId = userId;
    _studentName = name;
    _sessionToken = sessionToken;
    _lastUserId = userId;
    if (password != null && password.isNotEmpty) {
      _lastPassword = password;
    }
    _loggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kStudentUserId, userId);
    await prefs.setString(AppConstants.kStudentName, name);
    await prefs.setString(AppConstants.kSessionToken, sessionToken);
    await prefs.setString(AppConstants.kStudentLastUserId, userId);
    if (password != null && password.isNotEmpty) {
      await prefs.setString(AppConstants.kStudentLastPassword, password);
    }
    await prefs.setBool(AppConstants.kStudentLoggedIn, true);
    notifyListeners();
  }

  Future<void> logout() async {
    _userId = null;
    _studentName = null;
    _sessionToken = null;
    _loggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.kStudentUserId);
    await prefs.remove(AppConstants.kStudentName);
    await prefs.remove(AppConstants.kSessionToken);
    await prefs.setBool(AppConstants.kStudentLoggedIn, false);
    notifyListeners();
  }
}
