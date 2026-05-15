import 'package:flutter/foundation.dart';

class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

  @protected
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) {
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    super.dispose();
  }
}
