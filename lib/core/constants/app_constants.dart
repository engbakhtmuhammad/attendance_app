class AppConstants {
  AppConstants._();

  // Server
  static const int serverPort = 3000;
  static const int udpPort = 4567;
  static const String apiBase = '/api';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration discoveryTimeout = Duration(seconds: 12);
  static const Duration udpBroadcastInterval = Duration(milliseconds: 1000);
  static const Duration pollInterval = Duration(seconds: 2);

  // SharedPreferences keys
  static const String kAdminPinHash = 'admin_pin_hash';
  static const String kStudentUserId = 'student_user_id';
  static const String kStudentName = 'student_name';
  static const String kStudentDeviceId = 'student_device_id';
  static const String kStudentLoggedIn = 'student_logged_in';
  static const String kStudentLastUserId = 'student_last_user_id';
  static const String kStudentLastPassword = 'student_last_password';
  static const String kServerIp = 'last_server_ip';
  static const String kSessionToken = 'session_token';

  // Validation
  static const int minPinLength = 4;
  static const int maxPinLength = 8;

  // UDP discovery payload key
  static const String udpKey = 'attendance_server';
}
