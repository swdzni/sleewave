import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PlaylistCover extends StatelessWidget {
  const PlaylistCover({
    super.key,
    this.size = 58,
    this.colorHex,
    this.isFavorite = false,
  });

  final double size;
  final String? colorHex;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final base = isFavorite
        ? const Color(0xffff4f86)
        : _colorFromHex(colorHex) ?? _fallbackColor(colorHex);
    final second = Color.lerp(base, Colors.white, 0.22)!;
    final third = Color.lerp(base, context.palette.background, 0.36)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [second, base, third],
                  stops: const [0, 0.52, 1],
                ),
              ),
            ),
            Positioned(
              left: -size * 0.15,
              top: size * 0.12,
              child: _softOval(
                width: size * 1.25,
                height: size * 0.36,
                color: Colors.white.withValues(alpha: 0.16),
                angle: -0.20,
              ),
            ),
            Positioned(
              right: -size * 0.40,
              bottom: -size * 0.10,
              child: _softOval(
                width: size * 1.22,
                height: size * 0.46,
                color: Colors.black.withValues(alpha: 0.10),
                angle: -0.24,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                borderRadius: BorderRadius.circular(size * 0.22),
              ),
            ),
            Icon(
              isFavorite ? Icons.favorite_rounded : Icons.music_note_rounded,
              size: size * 0.42,
              color: context.palette.primaryText.withValues(alpha: 0.90),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softOval({
    required double width,
    required double height,
    required Color color,
    required double angle,
  }) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Color? _colorFromHex(String? value) {
    final raw = value?.trim();
    if (raw == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(raw)) {
      return null;
    }
    return Color(int.parse('ff${raw.substring(1)}', radix: 16));
  }

  Color _fallbackColor(String? seed) {
    const colors = [
      Color(0xff6bbcff),
      Color(0xff8adfbb),
      Color(0xffff9b87),
      Color(0xffffca72),
      Color(0xffb49cff),
      Color(0xffd9f56f),
      Color(0xff6ae7df),
      Color(0xffff83ac),
    ];
    final index = (seed ?? '').hashCode.abs() % colors.length;
    return colors[index];
  }
}
