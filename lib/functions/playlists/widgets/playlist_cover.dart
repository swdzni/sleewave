import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PlaylistCover extends StatelessWidget {
  const PlaylistCover({super.key, this.size = 58, this.colorHex});

  final double size;
  final String? colorHex;

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(colorHex) ?? _fallbackColor(colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.95),
            Color.lerp(color, context.palette.elevated, 0.58)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.queue_music_rounded,
        color: context.palette.primaryText,
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
      Color(0xff5cc8ff),
      Color(0xffff6b9a),
      Color(0xffa98bff),
      Color(0xff65d89b),
      Color(0xffffbd5c),
      Color(0xff5ee6d1),
      Color(0xffff7d65),
      Color(0xffd7f75b),
    ];
    final index = (seed ?? '').hashCode.abs() % colors.length;
    return colors[index];
  }
}
