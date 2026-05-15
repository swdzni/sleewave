import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData fromMode(SleewaveThemeMode mode) {
    final palette = switch (mode) {
      SleewaveThemeMode.pureDark => AppColors.pureDark,
      SleewaveThemeMode.dark => AppColors.dark,
      SleewaveThemeMode.white => AppColors.white,
    };
    final brightness = mode == SleewaveThemeMode.white
        ? Brightness.light
        : Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
      surface: palette.surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: scheme,
      fontFamily: '.SF Pro Text',
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: palette.accent,
        scaffoldBackgroundColor: palette.background,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: palette.primaryText,
          fontSize: 34,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: palette.primaryText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: palette.primaryText,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: palette.primaryText, fontSize: 16),
        bodyMedium: TextStyle(color: palette.secondaryText, fontSize: 14),
        labelLarge: TextStyle(
          color: palette.primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      extensions: [palette],
    );
  }
}
