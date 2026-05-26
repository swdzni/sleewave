import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';
import 'package:sleewave/core/theme/app_colors.dart';
import 'package:sleewave/core/theme/app_theme.dart';
import 'package:sleewave/core/theme/app_tokens.dart';

void main() {
  test('creates complete theme data for every Sleewave mode', () {
    for (final mode in SleewaveThemeMode.values) {
      final theme = AppTheme.fromMode(mode);
      final palette = theme.extension<AppPalette>();
      final tokens = theme.extension<AppThemeTokens>();

      expect(palette, isNotNull);
      expect(tokens, isNotNull);
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.filledButtonTheme.style, isNotNull);
      expect(theme.iconButtonTheme.style, isNotNull);
      expect(theme.bottomSheetTheme.shape, isNotNull);
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    }
  });

  test('theme annotations map typography and shape details', () {
    final caffeine = AppTheme.fromMode(SleewaveThemeMode.caffeineDark);
    final mono = AppTheme.fromMode(SleewaveThemeMode.monoDark);
    final caffeineTokens = caffeine.extension<AppThemeTokens>()!;
    final monoTokens = mono.extension<AppThemeTokens>()!;

    expect(caffeineTokens.controlRadius, 8);
    expect(caffeineTokens.fontFamily, '.SF Pro Text');
    expect(monoTokens.controlRadius, 0);
    expect(monoTokens.fontFamily, 'monospace');
    expect(mono.textTheme.titleMedium?.fontFamily, 'monospace');

    final glue = AppTheme.fromMode(SleewaveThemeMode.glueDark);
    final glueTokens = glue.extension<AppThemeTokens>()!;
    expect(glueTokens.isGlass, isTrue);
    expect(glueTokens.controlRadius, 20);
  });

  test('status tones are distinct from neutral text colors', () {
    for (final mode in SleewaveThemeMode.values) {
      final palette = AppTheme.paletteFor(mode);

      expect(palette.danger, isNot(palette.secondaryText));
      expect(palette.success, isNot(palette.secondaryText));
      expect(palette.warning, isNot(palette.secondaryText));
    }
  });
}
