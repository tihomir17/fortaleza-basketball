// lib/core/navigation/refresh_signal.dart
import 'package:flutter/foundation.dart';

class RefreshSignal with ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
