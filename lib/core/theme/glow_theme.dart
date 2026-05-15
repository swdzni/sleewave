import 'package:flutter/material.dart';

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
}
