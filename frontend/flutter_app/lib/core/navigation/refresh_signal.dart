// lib/core/navigation/refresh_signal.dart
import 'dart:async';
import 'package:fortaleza_basketball_analytics/main.dart'; // Import for global logger

class RefreshSignal {
  static final RefreshSignal _instance = RefreshSignal._internal();
  factory RefreshSignal() => _instance;
  RefreshSignal._internal();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    try {
      _controller.add(null);
      logger.d('RefreshSignal: Notifying listeners.');
    } catch (e) {
      logger.w('RefreshSignal: Error notifying listeners: $e');
    }
  }

  void dispose() {
    _controller.close();
  }
}
