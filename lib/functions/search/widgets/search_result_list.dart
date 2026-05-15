import 'package:flutter/material.dart';

import '../../../core/models/track.dart';
import '../../../core/widgets/song_card.dart';
import '../../playlists/widgets/add_to_playlist_sheet.dart';

class SearchResultList extends StatelessWidget {
  const SearchResultList({
    super.key,
    required this.localMatches,
    required this.streamedResults,
    required this.onPlay,
    required this.onLike,
    required this.onDownload,
    required this.onDelete,
    required this.currentTrackId,
    required this.sourceNames,
    required this.downloadProgress,
  });

  final List<Track> localMatches;
  final List<Track> streamedResults;
  final ValueChanged<Track> onPlay;
  final ValueChanged<Track> onLike;
  final ValueChanged<Track> onDownload;
  final ValueChanged<Track> onDelete;
  final String? currentTrackId;
  final Map<String, String> sourceNames;
  final Map<String, double> downloadProgress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (localMatches.isNotEmpty) ...[
          _GroupLabel('On this device'),
          for (final track in localMatches) _card(context, track),
          const SizedBox(height: 16),
        ],
        if (streamedResults.isNotEmpty) ...[
          _GroupLabel('Results'),
          for (final track in streamedResults) _card(context, track),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, Track track) {
    return SongCard(
      track: track,
      isPlaying: currentTrackId == track.id,
      sourceLabel: sourceNames[track.sourceId],
      onTap: () => onPlay(track),
      onLike: () => onLike(track),
      onAddToPlaylist: () => _showAddToPlaylist(context, track),
      onDownload: () => onDownload(track),
      onDelete: () => onDelete(track),
      downloadProgress: downloadProgress[track.id],
    );
  }

  void _showAddToPlaylist(BuildContext context, Track track) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => AddToPlaylistSheet(track: track),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
