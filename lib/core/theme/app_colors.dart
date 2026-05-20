import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.elevated,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.border,
    required this.strongBorder,
    required this.accent,
    required this.accentSoft,
    required this.danger,
    required this.success,
    required this.warning,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color elevated;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color border;
  final Color strongBorder;
  final Color accent;
  final Color accentSoft;
  final Color danger;
  final Color success;
  final Color warning;
  final Color shadow;

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? elevated,
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? border,
    Color? strongBorder,
    Color? accent,
    Color? accentSoft,
    Color? danger,
    Color? success,
    Color? warning,
    Color? shadow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      elevated: elevated ?? this.elevated,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      border: border ?? this.border,
      strongBorder: strongBorder ?? this.strongBorder,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      shadow: shadow ?? this.shadow,
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
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      border: Color.lerp(border, other.border, t)!,
      strongBorder: Color.lerp(strongBorder, other.strongBorder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class AppColors {
  const AppColors._();

  static const pureDark = AppPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF080808),
    surfaceMuted: Color(0xFF0D0D0F),
    elevated: Color(0xFF151518),
    primaryText: Colors.white,
    secondaryText: Color(0xFFB0B0B8),
    tertiaryText: Color(0xFF75757D),
    border: Color(0x24FFFFFF),
    strongBorder: Color(0x66FFFFFF),
    accent: Color(0xFFD7DAE3),
    accentSoft: Color(0x22FFFFFF),
    danger: Color(0xFFFF5C7A),
    success: Color(0xFF45D483),
    warning: Color(0xFFFFC857),
    shadow: Color(0x00000000),
  );

  static const dark = AppPalette(
    background: Color(0xFF10100F),
    surface: Color(0xFF191917),
    surfaceMuted: Color(0xFF22221F),
    elevated: Color(0xFF292923),
    primaryText: Colors.white,
    secondaryText: Color(0xFFB5B3AC),
    tertiaryText: Color(0xFF7E7B74),
    border: Color(0x26FFFFFF),
    strongBorder: Color(0x52FFFFFF),
    accent: Color(0xFFBFC7FF),
    accentSoft: Color(0x26BFC7FF),
    danger: Color(0xFFFF5C7A),
    success: Color(0xFF4BE18A),
    warning: Color(0xFFFFCE5C),
    shadow: Color(0x66000000),
  );

  static const white = AppPalette(
    background: Color(0xFFF8F7F4),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF0EFEB),
    elevated: Color(0xFFEAE9E4),
    primaryText: Color(0xFF16161B),
    secondaryText: Color(0xFF64635E),
    tertiaryText: Color(0xFF92908A),
    border: Color(0x1F000000),
    strongBorder: Color(0x52000000),
    accent: Color(0xFF2D64D8),
    accentSoft: Color(0x1A2D64D8),
    danger: Color(0xFFE93355),
    success: Color(0xFF15995A),
    warning: Color(0xFFD99200),
    shadow: Color(0x24000000),
  );
}

extension AppPaletteLookup on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
