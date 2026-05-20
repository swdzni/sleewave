import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';
import 'package:sleewave/core/theme/app_colors.dart';
import 'package:sleewave/core/theme/app_theme.dart';

void main() {
  test('creates complete theme data for every Sleewave mode', () {
    for (final mode in SleewaveThemeMode.values) {
      final theme = AppTheme.fromMode(mode);
      final palette = theme.extension<AppPalette>();

      expect(palette, isNotNull);
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.filledButtonTheme.style, isNotNull);
      expect(theme.iconButtonTheme.style, isNotNull);
      expect(theme.bottomSheetTheme.shape, isNotNull);
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    }
  });
}
