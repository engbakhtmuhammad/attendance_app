import 'dart:convert';
import 'dart:io';
import '../core/constants/app_constants.dart';
import '../core/utils/network_util.dart';

/// Runs on the admin device. Broadcasts server presence via UDP.
class DiscoveryService {
  RawDatagramSocket? _socket;
  bool _running = false;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    final ip = await NetworkUtil.getWifiIp();
    if (ip == null) return;

    _socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _running = true;

    _broadcast(ip);
  }

  Future<void> _broadcast(String ip) async {
    final payload = utf8.encode(jsonEncode({
      'service': AppConstants.udpKey,
      'ip': ip,
      'port': AppConstants.serverPort,
    }));

    while (_running) {
      try {
        _socket?.send(
          payload,
          InternetAddress('255.255.255.255'),
          AppConstants.udpPort,
        );
      } catch (_) {}
      await Future.delayed(AppConstants.udpBroadcastInterval);
    }
  }

  void stop() {
    _running = false;
    _socket?.close();
    _socket = null;
  }
}
