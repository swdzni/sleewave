import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.elevated,
    required this.input,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.border,
    required this.strongBorder,
    required this.accent,
    required this.accentSoft,
    required this.accentText,
    required this.primaryOnAccent,
    required this.danger,
    required this.dangerText,
    required this.success,
    required this.warning,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color elevated;
  final Color input;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color border;
  final Color strongBorder;
  final Color accent;
  final Color accentSoft;
  final Color accentText;
  final Color primaryOnAccent;
  final Color danger;
  final Color dangerText;
  final Color success;
  final Color warning;
  final Color shadow;

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? elevated,
    Color? input,
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? border,
    Color? strongBorder,
    Color? accent,
    Color? accentSoft,
    Color? accentText,
    Color? primaryOnAccent,
    Color? danger,
    Color? dangerText,
    Color? success,
    Color? warning,
    Color? shadow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      elevated: elevated ?? this.elevated,
      input: input ?? this.input,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      border: border ?? this.border,
      strongBorder: strongBorder ?? this.strongBorder,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentText: accentText ?? this.accentText,
      primaryOnAccent: primaryOnAccent ?? this.primaryOnAccent,
      danger: danger ?? this.danger,
      dangerText: dangerText ?? this.dangerText,
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
      input: Color.lerp(input, other.input, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      border: Color.lerp(border, other.border, t)!,
      strongBorder: Color.lerp(strongBorder, other.strongBorder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      primaryOnAccent: Color.lerp(primaryOnAccent, other.primaryOnAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class AppColors {
  const AppColors._();

  static const caffeineDark = AppPalette(
    background: Color(0xFF111111),
    surface: Color(0xFF191919),
    surfaceMuted: Color(0xFF222222),
    elevated: Color(0xFF191919),
    input: Color(0xFF484848),
    primaryText: Color(0xFFEEEEEE),
    secondaryText: Color(0xFFB4B4B4),
    tertiaryText: Color(0xFF7F7F7F),
    border: Color(0xFF201E18),
    strongBorder: Color(0xFFFFE0C2),
    accent: Color(0xFFFFE0C2),
    accentSoft: Color(0xFF393028),
    accentText: Color(0xFFEEEEEE),
    primaryOnAccent: Color(0xFF081A1B),
    danger: Color(0xFFE54D2E),
    dangerText: Color(0xFFFFFFFF),
    success: Color(0xFF67D09A),
    warning: Color(0xFFFFD38A),
    shadow: Color(0x52000000),
  );

  static const caffeineLight = AppPalette(
    background: Color(0xFFF9F9F9),
    surface: Color(0xFFFCFCFC),
    surfaceMuted: Color(0xFFEFEFEF),
    elevated: Color(0xFFFCFCFC),
    input: Color(0xFFD8D8D8),
    primaryText: Color(0xFF202020),
    secondaryText: Color(0xFF646464),
    tertiaryText: Color(0xFF8C8C8C),
    border: Color(0xFFD8D8D8),
    strongBorder: Color(0xFF644A40),
    accent: Color(0xFF644A40),
    accentSoft: Color(0xFFFFDFB5),
    accentText: Color(0xFF202020),
    primaryOnAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFE54D2E),
    dangerText: Color(0xFFFFFFFF),
    success: Color(0xFF2F7D4B),
    warning: Color(0xFF986A1E),
    shadow: Color(0x14000000),
  );

  static const monoDark = AppPalette(
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF191919),
    surfaceMuted: Color(0xFF262626),
    elevated: Color(0xFF262626),
    input: Color(0xFF525252),
    primaryText: Color(0xFFFAFAFA),
    secondaryText: Color(0xFFA1A1A1),
    tertiaryText: Color(0xFF717171),
    border: Color(0xFF383838),
    strongBorder: Color(0xFF737373),
    accent: Color(0xFF737373),
    accentSoft: Color(0xFF404040),
    accentText: Color(0xFFFAFAFA),
    primaryOnAccent: Color(0xFFFAFAFA),
    danger: Color(0xFFFF6467),
    dangerText: Color(0xFF262626),
    success: Color(0xFFB8F0C7),
    warning: Color(0xFFE8D28A),
    shadow: Color(0x00000000),
  );

  static const monoLight = AppPalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF5F5F5),
    elevated: Color(0xFFFFFFFF),
    input: Color(0xFFE5E5E5),
    primaryText: Color(0xFF0A0A0A),
    secondaryText: Color(0xFF717171),
    tertiaryText: Color(0xFFA1A1A1),
    border: Color(0xFFE5E5E5),
    strongBorder: Color(0xFFA1A1A1),
    accent: Color(0xFF737373),
    accentSoft: Color(0xFFF5F5F5),
    accentText: Color(0xFF171717),
    primaryOnAccent: Color(0xFFFAFAFA),
    danger: Color(0xFFE7000B),
    dangerText: Color(0xFFF5F5F5),
    success: Color(0xFF248A45),
    warning: Color(0xFF8A6816),
    shadow: Color(0x00000000),
  );
}

extension AppPaletteLookup on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
