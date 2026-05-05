import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/constants/app_constants.dart';

class DiscoveryClient {
  /// Listens on UDP port for admin broadcast.
  /// Returns the server IP or null if not found within timeout.
  static Future<String?> discover() async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, AppConstants.udpPort);
      socket.broadcastEnabled = true;

      final completer = Completer<String?>();

      final timer = Timer(AppConstants.discoveryTimeout, () {
        if (!completer.isCompleted) completer.complete(null);
      });

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket!.receive();
          if (datagram == null) return;
          try {
            final payload =
                jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
            if (payload['service'] == AppConstants.udpKey) {
              final ip = payload['ip'] as String?;
              if (ip != null && !completer.isCompleted) {
                timer.cancel();
                completer.complete(ip);
              }
            }
          } catch (_) {}
        }
      });

      return await completer.future;
    } finally {
      socket?.close();
    }
  }
}
