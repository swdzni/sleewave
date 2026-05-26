import 'package:flutter/material.dart';

class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.fontFamily,
    required this.fontFamilyFallback,
    required this.chipRadius,
    required this.rowRadius,
    required this.cardRadius,
    required this.controlRadius,
    required this.floatingRadius,
    required this.sheetRadius,
    required this.coverRadius,
    required this.previewRadius,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.isMono,
    this.isGlass = false,
  });

  final String fontFamily;
  final List<String> fontFamilyFallback;
  final double chipRadius;
  final double rowRadius;
  final double cardRadius;
  final double controlRadius;
  final double floatingRadius;
  final double sheetRadius;
  final double coverRadius;
  final double previewRadius;
  final double shadowBlur;
  final Offset shadowOffset;
  final bool isMono;
  final bool isGlass;

  static const caffeine = AppThemeTokens(
    fontFamily: '.SF Pro Text',
    fontFamilyFallback: ['SF Pro Text', 'Helvetica Neue', 'Arial'],
    chipRadius: 999,
    rowRadius: 8,
    cardRadius: 8,
    controlRadius: 8,
    floatingRadius: 18,
    sheetRadius: 18,
    coverRadius: 8,
    previewRadius: 8,
    shadowBlur: 18,
    shadowOffset: Offset(0, 8),
    isMono: false,
  );

  static const mono = AppThemeTokens(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Geist Mono', 'Menlo', 'Courier'],
    chipRadius: 0,
    rowRadius: 0,
    cardRadius: 0,
    controlRadius: 0,
    floatingRadius: 0,
    sheetRadius: 0,
    coverRadius: 0,
    previewRadius: 0,
    shadowBlur: 0,
    shadowOffset: Offset(0, 1),
    isMono: true,
  );

  static const glue = AppThemeTokens(
    fontFamily: '.SF Pro Text',
    fontFamilyFallback: [
      'Plus Jakarta Sans',
      'SF Pro Text',
      'Helvetica Neue',
      'Arial',
    ],
    chipRadius: 20,
    rowRadius: 20,
    cardRadius: 20,
    controlRadius: 20,
    floatingRadius: 26,
    sheetRadius: 28,
    coverRadius: 18,
    previewRadius: 18,
    shadowBlur: 10,
    shadowOffset: Offset(2, 2),
    isMono: false,
    isGlass: true,
  );

  @override
  AppThemeTokens copyWith({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? chipRadius,
    double? rowRadius,
    double? cardRadius,
    double? controlRadius,
    double? floatingRadius,
    double? sheetRadius,
    double? coverRadius,
    double? previewRadius,
    double? shadowBlur,
    Offset? shadowOffset,
    bool? isMono,
    bool? isGlass,
  }) {
    return AppThemeTokens(
      fontFamily: fontFamily ?? this.fontFamily,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
      chipRadius: chipRadius ?? this.chipRadius,
      rowRadius: rowRadius ?? this.rowRadius,
      cardRadius: cardRadius ?? this.cardRadius,
      controlRadius: controlRadius ?? this.controlRadius,
      floatingRadius: floatingRadius ?? this.floatingRadius,
      sheetRadius: sheetRadius ?? this.sheetRadius,
      coverRadius: coverRadius ?? this.coverRadius,
      previewRadius: previewRadius ?? this.previewRadius,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      isMono: isMono ?? this.isMono,
      isGlass: isGlass ?? this.isGlass,
    );
  }

  @override
  AppThemeTokens lerp(
    covariant ThemeExtension<AppThemeTokens>? other,
    double t,
  ) {
    if (other is! AppThemeTokens) {
      return this;
    }
    return AppThemeTokens(
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      fontFamilyFallback: t < 0.5
          ? fontFamilyFallback
          : other.fontFamilyFallback,
      chipRadius: _lerp(chipRadius, other.chipRadius, t),
      rowRadius: _lerp(rowRadius, other.rowRadius, t),
      cardRadius: _lerp(cardRadius, other.cardRadius, t),
      controlRadius: _lerp(controlRadius, other.controlRadius, t),
      floatingRadius: _lerp(floatingRadius, other.floatingRadius, t),
      sheetRadius: _lerp(sheetRadius, other.sheetRadius, t),
      coverRadius: _lerp(coverRadius, other.coverRadius, t),
      previewRadius: _lerp(previewRadius, other.previewRadius, t),
      shadowBlur: _lerp(shadowBlur, other.shadowBlur, t),
      shadowOffset: Offset.lerp(shadowOffset, other.shadowOffset, t)!,
      isMono: t < 0.5 ? isMono : other.isMono,
      isGlass: t < 0.5 ? isGlass : other.isGlass,
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

extension AppThemeTokenLookup on BuildContext {
  AppThemeTokens get themeTokens => Theme.of(this).extension<AppThemeTokens>()!;
}

class AppSpacing {
  const AppSpacing._();

  static const compactScreen = 16.0;
  static const screen = 20.0;
  static const section = 24.0;
  static const rowGap = 10.0;
}

class AppRadii {
  const AppRadii._();

  static const chip = 999.0;
  static const row = 14.0;
  static const card = 14.0;
  static const control = 22.0;
  static const floating = 28.0;
  static const sheet = 24.0;
}

class AppSizes {
  const AppSizes._();

  static const smallIconButton = 36.0;
  static const iconButton = 44.0;
  static const minTapTarget = 44.0;
  static const compactSongRow = 72.0;
  static const songRow = 88.0;
  static const miniPlayer = 72.0;
  static const playerPrimary = 68.0;
}

class AppDurations {
  const AppDurations._();

  static const press = Duration(milliseconds: 140);
  static const state = Duration(milliseconds: 220);
  static const sheet = Duration(milliseconds: 360);
  static const route = Duration(milliseconds: 320);
}

class AppCurves {
  const AppCurves._();

  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;
}
