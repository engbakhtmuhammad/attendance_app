import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkUtil {
  NetworkUtil._();

  static Future<String?> getWifiIp() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiIP();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getWifiGatewayIp() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiGatewayIP();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isPortAvailable(int port) async {
    try {
      final server = await ServerSocket.bind(InternetAddress.anyIPv4, port,
          shared: false);
      await server.close();
      return true;
    } catch (_) {
      return false;
    }
  }
}
