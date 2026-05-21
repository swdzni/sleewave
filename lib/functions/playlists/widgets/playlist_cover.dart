import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

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
        ? context.palette.accent
        : _colorFromHex(colorHex) ?? context.palette.surfaceMuted;
    final radius = context.themeTokens.coverRadius;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(color: base)),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: context.palette.border),
                borderRadius: BorderRadius.circular(radius),
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

  Color? _colorFromHex(String? value) {
    final raw = value?.trim();
    if (raw == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(raw)) {
      return null;
    }
    return Color(int.parse('ff${raw.substring(1)}', radix: 16));
  }
}
