import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/app_colors.dart';
import 'cover_art.dart';
import 'track_badges.dart';

enum SongCardMode { normal, compact, featured }

class SongCard extends StatelessWidget {
  const SongCard({
    super.key,
    required this.track,
    this.mode = SongCardMode.normal,
    this.isPlaying = false,
    this.onTap,
    this.onLongPress,
    this.onLike,
    this.onDownload,
    this.onDelete,
  });

  final Track track;
  final SongCardMode mode;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLike;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final compact = mode == SongCardMode.compact;
    final coverSize = mode == SongCardMode.featured
        ? 76.0
        : compact
        ? 46.0
        : 58.0;
    return Semantics(
      button: true,
      label: 'Play ${track.title}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPlaying ? context.palette.accent : context.palette.border,
          ),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: context.palette.accent.withValues(alpha: 0.2),
                    blurRadius: 24,
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 10),
            child: Row(
              children: [
                CoverArt(
                  coverUrl: track.coverUrl,
                  localCoverPath: track.localCoverPath,
                  size: coverSize,
                  borderRadius: 8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.displayArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 6),
                        TrackBadges(track: track),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  track.displayDuration,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  tooltip: track.isLiked ? 'Unlike' : 'Like',
                  onPressed: onLike,
                  icon: Icon(
                    track.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: track.isLiked
                        ? context.palette.danger
                        : context.palette.secondaryText,
                  ),
                ),
                IconButton(
                  tooltip: track.isLocalPlayable ? 'Delete' : 'Download',
                  onPressed: track.isLocalPlayable ? onDelete : onDownload,
                  icon: Icon(
                    track.isLocalPlayable
                        ? Icons.delete_outline_rounded
                        : Icons.download_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
