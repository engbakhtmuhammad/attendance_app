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
  bool _loggedIn = false;
  bool _initialized = false;

  String? get serverIp => _serverIp;
  String? get userId => _userId;
  String? get studentName => _studentName;
  String? get deviceId => _deviceId;
  String? get sessionToken => _sessionToken;
  bool get loggedIn => _loggedIn;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString(AppConstants.kServerIp);
    _userId = prefs.getString(AppConstants.kStudentUserId);
    _studentName = prefs.getString(AppConstants.kStudentName);
    _deviceId = prefs.getString(AppConstants.kStudentDeviceId);
    _sessionToken = prefs.getString(AppConstants.kSessionToken);

    _deviceId ??= await DeviceIdUtil.getDeviceId();
    if (prefs.getString(AppConstants.kStudentDeviceId) == null) {
      await prefs.setString(AppConstants.kStudentDeviceId, _deviceId!);
    }

    _loggedIn = _userId != null && _userId!.isNotEmpty;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setServerIp(String ip) async {
    _serverIp = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kServerIp, ip);
    notifyListeners();
  }

  Future<void> setLoggedIn({
    required String userId,
    required String name,
    required String sessionToken,
  }) async {
    _userId = userId;
    _studentName = name;
    _sessionToken = sessionToken;
    _loggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kStudentUserId, userId);
    await prefs.setString(AppConstants.kStudentName, name);
    await prefs.setString(AppConstants.kSessionToken, sessionToken);
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
    notifyListeners();
  }
}
