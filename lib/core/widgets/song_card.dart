import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_list_tile.dart';
import 'cover_art.dart';
import 'now_playing_bars.dart';
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
  final double? downloadProgress;
  final bool onlineAvailable;

  @override
  Widget build(BuildContext context) {
    final compact = mode == SongCardMode.compact;
    final coverSize = mode == SongCardMode.featured
        ? 54.0
        : compact
        ? 42.0
        : 48.0;
    final height = compact ? AppSizes.compactSongRow : AppSizes.songRow;
    final isDownloading = downloadProgress != null;
    final playable =
        track.isLocalPlayable || (track.resultId != null && onlineAvailable);
    final unavailable = !playable;
    final canDownload =
        !track.isLocalPlayable && onlineAvailable && track.resultId != null;
    final showTransferAction =
        isDownloading ||
        (track.isLocalPlayable && onDelete != null) ||
        (!track.isLocalPlayable && canDownload && onDownload != null);
    final onEffectiveTap = playable ? onTap : null;
    final palette = context.palette;
    return Semantics(
      button: playable,
      enabled: playable,
      label: playable ? 'Play ${track.title}' : '${track.title} unavailable',
      child: AppListTile(
        key: ValueKey('song-card-${track.id}'),
        active: isPlaying,
        enabled: playable,
        onTap: onEffectiveTap,
        onLongPress: onLongPress,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 8,
        ),
        child: SizedBox(
          height: height - (compact ? 16 : 12),
          child: Row(
            children: [
              CoverArt(
                coverUrl: track.coverUrl,
                localCoverPath: track.localCoverPath,
                size: coverSize,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isPlaying) ...[
                          NowPlayingBars(
                            color: palette.accent,
                            playing: playable,
                            width: 18,
                            height: 16,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: unavailable
                                      ? palette.secondaryText
                                      : palette.primaryText,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      playable ? track.displayArtist : 'Unavailable offline',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: playable
                            ? palette.secondaryText
                            : palette.tertiaryText,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 3),
                      SizedBox(
                        height: 20,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: TrackBadges(track: track),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TrailingActions(
                track: track,
                isDownloading: isDownloading,
                showTransferAction: showTransferAction,
                downloadProgress: downloadProgress,
                onLike: onLike,
                onAddToPlaylist: onAddToPlaylist,
                onRemoveFromPlaylist: onRemoveFromPlaylist,
                onDownload: onDownload,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailingActions extends StatelessWidget {
  const _TrailingActions({
    required this.track,
    required this.isDownloading,
    required this.showTransferAction,
    required this.downloadProgress,
    this.onLike,
    this.onAddToPlaylist,
    this.onRemoveFromPlaylist,
    this.onDownload,
    this.onDelete,
  });

  final Track track;
  final bool isDownloading;
  final bool showTransferAction;
  final double? downloadProgress;
  final VoidCallback? onLike;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          track.displayDuration,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 2),
        if (onLike != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            key: ValueKey('like-${track.id}-${track.isLiked}'),
            tooltip: track.isLiked ? 'Unlike' : 'Like',
            onPressed: onLike,
            icon: Icon(
              track.isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: track.isLiked ? palette.danger : palette.secondaryText,
            ),
          ),
        if (onAddToPlaylist != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Add to playlist',
            onPressed: onAddToPlaylist,
            icon: const Icon(Icons.playlist_add_rounded),
          ),
        if (onRemoveFromPlaylist != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove from playlist',
            onPressed: onRemoveFromPlaylist,
            icon: const Icon(Icons.playlist_remove_rounded),
          ),
        if (showTransferAction)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: track.isLocalPlayable ? 'Delete' : 'Download',
            onPressed: isDownloading
                ? null
                : track.isLocalPlayable
                ? onDelete
                : onDownload,
            icon: AnimatedSwitcher(
              duration: AppDurations.state,
              child: isDownloading
                  ? SizedBox.square(
                      key: const ValueKey('download-progress'),
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
                      key: ValueKey(
                        track.isLocalPlayable ? 'delete-track' : 'download',
                      ),
                      track.isLocalPlayable
                          ? Icons.delete_outline_rounded
                          : Icons.download_rounded,
                    ),
            ),
          ),
      ],
    );
  }
}
