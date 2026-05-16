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
    this.onAddToPlaylist,
    this.onRemoveFromPlaylist,
    this.onDownload,
    this.onDelete,
    this.sourceLabel,
    this.downloadProgress,
    this.onlineAvailable = true,
  });

  final Track track;
  final SongCardMode mode;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLike;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final String? sourceLabel;
  final double? downloadProgress;
  final bool onlineAvailable;

  @override
  Widget build(BuildContext context) {
    final compact = mode == SongCardMode.compact;
    final coverSize = mode == SongCardMode.featured
        ? 52.0
        : compact
        ? 38.0
        : 44.0;
    final height = compact ? 66.0 : 94.0;
    final isDownloading = downloadProgress != null;
    final playable =
        track.isLocalPlayable || track.resultId == null || onlineAvailable;
    final unavailable = !playable;
    final onEffectiveTap = playable ? onTap : null;
    return Semantics(
      button: playable,
      enabled: playable,
      label: playable ? 'Play ${track.title}' : '${track.title} unavailable',
      child: AnimatedContainer(
        key: ValueKey('song-card-${track.id}'),
        duration: const Duration(milliseconds: 260),
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: playable
              ? context.palette.surface
              : context.palette.surface.withValues(alpha: 0.62),
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
          onTap: onEffectiveTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: 8,
            ),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: unavailable
                                  ? context.palette.secondaryText
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        playable ? track.displayArtist : 'Unavailable offline',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: playable
                              ? null
                              : context.palette.secondaryText,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 22,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: TrackBadges(
                              track: track,
                              sourceLabel: sourceLabel,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  track.displayDuration,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  key: ValueKey('like-${track.id}-${track.isLiked}'),
                  tooltip: track.isLiked ? 'Unlike' : 'Like',
                  onPressed: onLike,
                  icon: Icon(
                    track.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: track.isLiked
                        ? context.palette.danger
                        : context.palette.secondaryText,
                  ),
                ),
                if (!compact)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Add to playlist',
                    onPressed: onAddToPlaylist,
                    icon: const Icon(Icons.playlist_add_rounded),
                  ),
                if (!compact && onRemoveFromPlaylist != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove from playlist',
                    onPressed: onRemoveFromPlaylist,
                    icon: const Icon(Icons.playlist_remove_rounded),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: track.isLocalPlayable
                      ? 'Delete'
                      : onlineAvailable
                      ? 'Download'
                      : 'Unavailable',
                  onPressed:
                      isDownloading ||
                          (!track.isLocalPlayable && !onlineAvailable)
                      ? null
                      : track.isLocalPlayable
                      ? onDelete
                      : onDownload,
                  icon: isDownloading
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value:
                                (downloadProgress ?? 0) > 0 &&
                                    (downloadProgress ?? 0) < 1
                                ? downloadProgress
                                : null,
                          ),
                        )
                      : Icon(
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
