import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/track.dart';

class GlowTheme {
  const GlowTheme._();

  static const staticGradient = LinearGradient(
    colors: [Color(0xFF49F3D3), Color(0xFF6D7CFF), Color(0xFFFF5CDA)],
  );

  static List<BoxShadow> softGlow(Color color, {double opacity = 0.28}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 24,
        spreadRadius: 1,
      ),
    ];
  }

  static Color playbackAccent({
    required GlowMode mode,
    required Track? track,
    required Color fallback,
  }) {
    if (mode == GlowMode.static || track == null) {
      return fallback;
    }
    final seed = [
      track.coverUrl,
      track.localCoverPath,
      track.title,
      track.displayArtist,
    ].whereType<String>().join('|');
    if (seed.isEmpty) {
      return fallback;
    }
    final hash = seed.codeUnits.fold<int>(
      0,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    return HSLColor.fromAHSL(1, (hash % 360).toDouble(), 0.62, 0.64).toColor();
  }
}
