// lib/core/navigation/refresh_signal.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class RefreshSignal with ChangeNotifier {
  void notify() {
    notifyListeners();
    logger.d('RefreshSignal: Notifying listeners.');
  }
}
