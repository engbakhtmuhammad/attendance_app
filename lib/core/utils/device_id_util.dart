import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceIdUtil {
  DeviceIdUtil._();

  static Future<String> getDeviceId() async {
    final info = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await info.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await info.iosInfo;
        return iosInfo.identifierForVendor ?? _fallback();
      }
    } catch (_) {}
    return _fallback();
  }

  static String _fallback() {
    // Stable enough for non-iOS/Android platforms (desktop testing)
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
}
