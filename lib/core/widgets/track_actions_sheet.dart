import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/track.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'bottom_sheet_shell.dart';
import 'cover_art.dart';
import 'track_badges.dart';

Future<void> showTrackActionsSheet({
  required BuildContext context,
  required Track track,
  String? sourceLabel,
  VoidCallback? onLike,
  VoidCallback? onAddToPlaylist,
  VoidCallback? onRemoveFromPlaylist,
  VoidCallback? onDownload,
  VoidCallback? onShare,
  VoidCallback? onDeleteLocal,
  VoidCallback? onDeleteFromServer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => _TrackActionsSheet(
      track: track,
      sourceLabel: sourceLabel,
      onLike: onLike,
      onAddToPlaylist: onAddToPlaylist,
      onRemoveFromPlaylist: onRemoveFromPlaylist,
      onDownload: onDownload,
      onShare: onShare,
      onDeleteLocal: onDeleteLocal,
      onDeleteFromServer: onDeleteFromServer,
    ),
  );
}

class _TrackActionsSheet extends StatelessWidget {
  const _TrackActionsSheet({
    required this.track,
    required this.sourceLabel,
    this.onLike,
    this.onAddToPlaylist,
    this.onRemoveFromPlaylist,
    this.onDownload,
    this.onShare,
    this.onDeleteLocal,
    this.onDeleteFromServer,
  });

  final Track track;
  final String? sourceLabel;
  final VoidCallback? onLike;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onDeleteLocal;
  final VoidCallback? onDeleteFromServer;

  @override
  Widget build(BuildContext context) {
    return BottomSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: context.palette.secondaryText.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CoverArt(
                coverUrl: track.coverUrl,
                localCoverPath: track.localCoverPath,
                size: 58,
                borderRadius: context.themeTokens.coverRadius,
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.displayArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TrackBadges(track: track),
          if (track.sourceId != null ||
              track.trackKey != null ||
              track.baseTrackKey != null ||
              track.album != null) ...[
            const SizedBox(height: 8),
            if (track.sourceId != null)
              Text(
                'Source: ${sourceLabel ?? track.sourceId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (track.trackKey != null)
              Text(
                'Track key: ${track.trackKey}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (track.baseTrackKey != null)
              Text(
                'Base key: ${track.baseTrackKey}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (track.album != null)
              Text(
                'Album: ${track.album}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
          const SizedBox(height: 14),
          if (onLike != null)
            _ActionTile(
              icon: track.isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: track.isLiked ? 'Unlike' : 'Like',
              onTap: onLike!,
            ),
          if (onAddToPlaylist != null)
            _ActionTile(
              icon: Icons.playlist_add_rounded,
              label: 'Add to playlist',
              onTap: onAddToPlaylist!,
            ),
          if (onRemoveFromPlaylist != null)
            _ActionTile(
              icon: Icons.playlist_remove_rounded,
              label: 'Remove from playlist',
              onTap: onRemoveFromPlaylist!,
            ),
          if (onShare != null)
            _ActionTile(
              icon: Icons.ios_share_rounded,
              label: 'Share',
              onTap: onShare!,
            ),
          if (track.isLocalPlayable && onDeleteLocal != null)
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete from device',
              onTap: onDeleteLocal!,
            )
          else if (!track.isLocalPlayable &&
              track.resultId != null &&
              onDownload != null)
            _ActionTile(
              icon: Icons.download_rounded,
              label: 'Download',
              onTap: onDownload!,
            ),
          if (track.resultId != null && onDeleteFromServer != null)
            _ActionTile(
              icon: Icons.delete_forever_rounded,
              label: 'Delete from server',
              danger: true,
              onTap: onDeleteFromServer!,
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.palette.danger : null;
    return ListTile(
      minTileHeight: AppSizes.minTapTarget,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
