/// VisionBridge — Connectivity Service
///
/// Monitors network connectivity. Used by AI Bridge to decide
/// whether to attempt Groq calls or fall back to on-device only.
library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((results) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      _controller.add(_isOnline);
    });
  }

  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;

  /// Stream of connectivity changes (true = online).
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Current connectivity status.
  bool get isOnline => _isOnline;

  /// Check current connectivity.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    return _isOnline;
  }

  void dispose() {
    _controller.close();
  }
}
