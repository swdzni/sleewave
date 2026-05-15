import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.primaryText,
    required this.secondaryText,
    required this.border,
    required this.accent,
    required this.danger,
    required this.success,
    required this.warning,
  });

  final Color background;
  final Color surface;
  final Color elevated;
  final Color primaryText;
  final Color secondaryText;
  final Color border;
  final Color accent;
  final Color danger;
  final Color success;
  final Color warning;

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? background,
    Color? surface,
    Color? elevated,
    Color? primaryText,
    Color? secondaryText,
    Color? border,
    Color? accent,
    Color? danger,
    Color? success,
    Color? warning,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(
    covariant ThemeExtension<AppPalette>? other,
    double t,
  ) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

class AppColors {
  const AppColors._();

  static const pureDark = AppPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF080808),
    elevated: Color(0xFF121216),
    primaryText: Colors.white,
    secondaryText: Color(0xFF9A9AA3),
    border: Color(0x22FFFFFF),
    accent: Color(0xFF60E6D2),
    danger: Color(0xFFFF5C7A),
    success: Color(0xFF45D483),
    warning: Color(0xFFFFC857),
  );

  static const dark = AppPalette(
    background: Color(0xFF0B0B0F),
    surface: Color(0xFF141419),
    elevated: Color(0xFF1D1D24),
    primaryText: Colors.white,
    secondaryText: Color(0xFFA6A6B0),
    border: Color(0x24FFFFFF),
    accent: Color(0xFF6AD8FF),
    danger: Color(0xFFFF5C7A),
    success: Color(0xFF4BE18A),
    warning: Color(0xFFFFCE5C),
  );

  static const white = AppPalette(
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFF1F1F3),
    primaryText: Color(0xFF16161B),
    secondaryText: Color(0xFF6D6D78),
    border: Color(0x1F000000),
    accent: Color(0xFF007AFF),
    danger: Color(0xFFE93355),
    success: Color(0xFF15995A),
    warning: Color(0xFFD99200),
  );
}

extension AppPaletteLookup on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
