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
  });

  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback? onRename;

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
          border: Border.all(color: context.palette.border),
        ),
        child: Row(
          children: [
            PlaylistCover(colorHex: playlist.coverPath ?? playlist.id),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${playlist.trackCount} tracks'),
                ],
              ),
            ),
            if (onRename != null)
              IconButton(
                tooltip: 'Rename',
                onPressed: onRename,
                icon: const Icon(Icons.edit_rounded),
              )
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
