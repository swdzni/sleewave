import 'package:flutter/material.dart';

import '../../../core/models/playlist.dart';
import '../../../core/theme/app_colors.dart';
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? context.palette.accent : context.palette.border,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: context.palette.accent.withValues(alpha: 0.16),
                    blurRadius: 18,
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
                  Text(
                    active
                        ? 'Playing now · ${playlist.trackCount} tracks'
                        : '${playlist.trackCount} tracks',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: active
                        ? TextStyle(color: context.palette.accent)
                        : null,
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
    );
  }
}

enum _PlaylistAction { rename, delete }
