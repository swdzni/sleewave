import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PlaylistCover extends StatelessWidget {
  const PlaylistCover({super.key, this.size = 58});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            context.palette.accent.withValues(alpha: 0.85),
            context.palette.elevated,
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
}
