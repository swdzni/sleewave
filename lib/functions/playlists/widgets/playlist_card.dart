import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/playlist.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import 'playlist_cover.dart';

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    this.onRename,
    this.onDelete,
    this.active = false,
  });

  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tokens = context.themeTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: active ? palette.accentSoft : palette.surface,
        borderRadius: BorderRadius.circular(tokens.rowRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.rowRadius),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(tokens.rowRadius),
              border: Border.all(
                color: active ? palette.strongBorder : palette.border,
              ),
              boxShadow: active && palette.shadow.a > 0
                  ? [
                      BoxShadow(
                        color: palette.shadow,
                        blurRadius: tokens.shadowBlur,
                        offset: tokens.shadowOffset,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                PlaylistCover(
                  colorHex: playlist.coverPath ?? playlist.id,
                  isFavorite: playlist.isFavorite,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        active
                            ? 'Playing now · ${playlist.trackCount} tracks'
                            : '${playlist.trackCount} tracks',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? palette.accent
                              : palette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRename != null || onDelete != null)
                  PopupMenuButton<_PlaylistAction>(
                    tooltip: 'Playlist actions',
                    onSelected: (action) {
                      switch (action) {
                        case _PlaylistAction.rename:
                          onRename?.call();
                        case _PlaylistAction.delete:
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onRename != null)
                        const PopupMenuItem(
                          value: _PlaylistAction.rename,
                          child: Text('Rename'),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: _PlaylistAction.delete,
                          child: Text('Delete'),
                        ),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PlaylistAction { rename, delete }
