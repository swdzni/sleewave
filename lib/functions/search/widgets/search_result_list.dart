import 'package:flutter/material.dart';

import '../../../core/models/track.dart';
import '../../../core/widgets/song_card.dart';

class SearchResultList extends StatelessWidget {
  const SearchResultList({
    super.key,
    required this.localMatches,
    required this.streamedResults,
    required this.onPlay,
    required this.onLike,
    required this.onDownload,
    required this.onDelete,
  });

  final List<Track> localMatches;
  final List<Track> streamedResults;
  final ValueChanged<Track> onPlay;
  final ValueChanged<Track> onLike;
  final ValueChanged<Track> onDownload;
  final ValueChanged<Track> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (localMatches.isNotEmpty) ...[
          _GroupLabel('On this device'),
          for (final track in localMatches) _card(track),
          const SizedBox(height: 16),
        ],
        if (streamedResults.isNotEmpty) ...[
          _GroupLabel('Results'),
          for (final track in streamedResults) _card(track),
        ],
      ],
    );
  }

  Widget _card(Track track) {
    return SongCard(
      track: track,
      onTap: () => onPlay(track),
      onLike: () => onLike(track),
      onDownload: () => onDownload(track),
      onDelete: () => onDelete(track),
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
