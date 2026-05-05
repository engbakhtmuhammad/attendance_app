import 'package:flutter/foundation.dart';
import '../core/utils/network_util.dart';
import '../server/local_server.dart';
import '../server/discovery_service.dart';

class ServerProvider extends ChangeNotifier {
  final LocalServer _server = LocalServer();
  final DiscoveryService _discovery = DiscoveryService();

  bool _running = false;
  String? _ip;
  String? _error;

  bool get isRunning => _running;
  String? get ip => _ip;
  String? get error => _error;

  Future<void> startServer() async {
    _error = null;
    try {
      _ip = await NetworkUtil.getWifiIp();
      await _server.start();
      await _discovery.start();
      _running = true;
    } catch (e) {
      _error = 'Failed to start server: $e';
    }
    notifyListeners();
  }

  Future<void> stopServer() async {
    _discovery.stop();
    await _server.stop();
    _running = false;
    notifyListeners();
  }
}
