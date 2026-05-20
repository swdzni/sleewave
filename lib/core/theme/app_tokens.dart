import 'package:flutter/material.dart';

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
