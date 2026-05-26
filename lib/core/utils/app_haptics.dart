import 'package:flutter/services.dart';

class AppHaptics {
  const AppHaptics._();

  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> light() => HapticFeedback.lightImpact();

  static Future<void> warning() => light();
}
