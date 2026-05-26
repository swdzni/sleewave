import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  const AppTheme._();

  static AppPalette paletteFor(SleewaveThemeMode mode) {
    return switch (mode) {
      SleewaveThemeMode.caffeineDark => AppColors.caffeineDark,
      SleewaveThemeMode.caffeineLight => AppColors.caffeineLight,
      SleewaveThemeMode.monoDark => AppColors.monoDark,
      SleewaveThemeMode.monoLight => AppColors.monoLight,
    };
  }

  static AppThemeTokens tokensFor(SleewaveThemeMode mode) {
    return switch (mode) {
      SleewaveThemeMode.caffeineDark ||
      SleewaveThemeMode.caffeineLight => AppThemeTokens.caffeine,
      SleewaveThemeMode.monoDark ||
      SleewaveThemeMode.monoLight => AppThemeTokens.mono,
    };
  }

  static ThemeData fromMode(SleewaveThemeMode mode) {
    final palette = paletteFor(mode);
    final tokens = tokensFor(mode);
    final brightness =
        mode == SleewaveThemeMode.caffeineLight ||
            mode == SleewaveThemeMode.monoLight
        ? Brightness.light
        : Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.primaryOnAccent,
      surface: palette.surface,
      onSurface: palette.primaryText,
      error: palette.danger,
      onError: palette.dangerText,
    );
    final textTheme = _textTheme(palette, tokens);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: scheme,
      fontFamily: tokens.fontFamily,
      fontFamilyFallback: tokens.fontFamilyFallback,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: palette.accent,
        scaffoldBackgroundColor: palette.background,
        textTheme: CupertinoTextThemeData(
          primaryColor: palette.primaryText,
          textStyle: textTheme.bodyMedium,
        ),
      ),
      textTheme: textTheme,
      iconTheme: IconThemeData(color: palette.primaryText, size: 22),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppSizes.iconButton),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? palette.tertiaryText
                : palette.primaryText,
          ),
          overlayColor: WidgetStatePropertyAll(palette.accentSoft),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.controlRadius),
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: palette.accent,
          foregroundColor: palette.primaryOnAccent,
          disabledBackgroundColor: palette.elevated.withValues(alpha: 0.55),
          disabledForegroundColor: palette.tertiaryText,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.controlRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: palette.primaryText,
          disabledForegroundColor: palette.tertiaryText,
          side: BorderSide(color: palette.border),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.controlRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 40),
          foregroundColor: palette.accent,
          disabledForegroundColor: palette.tertiaryText,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.controlRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.input.withValues(
          alpha: brightness == Brightness.dark ? 0.62 : 0.36,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.tertiaryText),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: palette.accent,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder(palette.border, tokens),
        enabledBorder: _inputBorder(palette.border, tokens),
        focusedBorder: _inputBorder(palette.strongBorder, tokens),
        errorBorder: _inputBorder(palette.danger, tokens),
        focusedErrorBorder: _inputBorder(palette.danger, tokens),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceMuted,
        selectedColor: palette.accentSoft,
        disabledColor: palette.surfaceMuted.withValues(alpha: 0.55),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: palette.primaryText,
        ),
        iconTheme: IconThemeData(color: palette.secondaryText, size: 16),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.chipRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        iconColor: palette.secondaryText,
        textColor: palette.primaryText,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.rowRadius),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.accent,
        inactiveTrackColor: palette.border,
        thumbColor: palette.primaryText,
        overlayColor: palette.accentSoft,
        trackHeight: 5,
        trackShape: tokens.isMono
            ? const RectangularSliderTrackShape()
            : const RoundedRectSliderTrackShape(),
        thumbShape: tokens.isMono
            ? const _SquareSliderThumbShape(size: 14)
            : const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.elevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.primaryText,
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 156),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.rowRadius),
          side: BorderSide(color: palette.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.sheetRadius),
          side: BorderSide(color: palette.border),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.elevated,
        modalBackgroundColor: palette.elevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.sheetRadius),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.elevated,
          borderRadius: BorderRadius.circular(tokens.controlRadius),
          border: Border.all(color: palette.border),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: palette.primaryText),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.elevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.rowRadius),
          side: BorderSide(color: palette.border),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: palette.primaryText),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primaryText
              : palette.tertiaryText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accentSoft
              : palette.surfaceMuted,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: palette.surfaceMuted,
        circularTrackColor: palette.surfaceMuted,
      ),
      extensions: [palette, tokens],
    );
  }

  static TextTheme _textTheme(AppPalette palette, AppThemeTokens tokens) {
    final headlineWeight = tokens.isMono ? FontWeight.w700 : FontWeight.w800;
    final titleWeight = tokens.isMono ? FontWeight.w600 : FontWeight.w700;
    final labelWeight = tokens.isMono ? FontWeight.w600 : FontWeight.w700;
    return TextTheme(
      headlineLarge: TextStyle(
        color: palette.primaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: tokens.isMono ? 31 : 34,
        fontWeight: headlineWeight,
        letterSpacing: 0,
        height: tokens.isMono ? 1.12 : 1.06,
      ),
      headlineMedium: TextStyle(
        color: palette.primaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: tokens.isMono ? 26 : 29,
        fontWeight: headlineWeight,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: palette.primaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: 22,
        fontWeight: titleWeight,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: palette.primaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: 17,
        fontWeight: titleWeight,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        color: palette.primaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: 15.5,
        fontWeight: titleWeight,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        color: palette.primaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: palette.secondaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: 14.5,
      ),
      bodySmall: TextStyle(
        color: palette.tertiaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: 12.5,
      ),
      labelLarge: TextStyle(
        color: palette.primaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: 14,
        fontWeight: labelWeight,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        color: palette.secondaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        color: palette.tertiaryText,
        fontFamily: tokens.fontFamily,
        fontFamilyFallback: tokens.fontFamilyFallback,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, AppThemeTokens tokens) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.controlRadius),
      borderSide: BorderSide(color: color),
    );
  }
}

class _SquareSliderThumbShape extends SliderComponentShape {
  const _SquareSliderThumbShape({required this.size});

  final double size;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.square(size);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final color =
        ColorTween(
          begin: sliderTheme.disabledThumbColor,
          end: sliderTheme.thumbColor,
        ).evaluate(enableAnimation) ??
        sliderTheme.thumbColor ??
        Colors.white;
    final half = size / 2;
    context.canvas.drawRect(
      Rect.fromLTRB(
        center.dx - half,
        center.dy - half,
        center.dx + half,
        center.dy + half,
      ),
      Paint()..color = color,
    );
  }
}
