import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

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
      primary: palette.accent,
      onPrimary: palette.background,
      surface: palette.surface,
      onSurface: palette.primaryText,
      error: palette.danger,
    );
    final textTheme = _textTheme(palette);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: scheme,
      fontFamily: '.SF Pro Text',
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
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: palette.accent,
          foregroundColor: brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          disabledBackgroundColor: palette.elevated.withValues(alpha: 0.55),
          disabledForegroundColor: palette.tertiaryText,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
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
            borderRadius: BorderRadius.circular(AppRadii.control),
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
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceMuted,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.tertiaryText),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: palette.accent,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder(palette.border),
        enabledBorder: _inputBorder(palette.border),
        focusedBorder: _inputBorder(palette.strongBorder),
        errorBorder: _inputBorder(palette.danger),
        focusedErrorBorder: _inputBorder(palette.danger),
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
          borderRadius: BorderRadius.circular(AppRadii.chip),
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
          borderRadius: BorderRadius.circular(AppRadii.row),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.accent,
        inactiveTrackColor: palette.border,
        thumbColor: palette.primaryText,
        overlayColor: palette.accentSoft,
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.elevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.primaryText,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.row),
          side: BorderSide(color: palette.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
          side: BorderSide(color: palette.border),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.elevated,
        modalBackgroundColor: palette.elevated,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.border),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: palette.primaryText),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.elevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.row),
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
      extensions: [palette],
    );
  }

  static TextTheme _textTheme(AppPalette palette) {
    return TextTheme(
      headlineLarge: TextStyle(
        color: palette.primaryText,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.06,
      ),
      headlineMedium: TextStyle(
        color: palette.primaryText,
        fontSize: 29,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: palette.primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: palette.primaryText,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        color: palette.primaryText,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(color: palette.primaryText, fontSize: 16),
      bodyMedium: TextStyle(color: palette.secondaryText, fontSize: 14.5),
      bodySmall: TextStyle(color: palette.tertiaryText, fontSize: 12.5),
      labelLarge: TextStyle(
        color: palette.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        color: palette.secondaryText,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        color: palette.tertiaryText,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.row),
      borderSide: BorderSide(color: color),
    );
  }
}
