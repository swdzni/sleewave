import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/song_card.dart';
import '../view_models/playlist_detail_view_model.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(playlistDetailViewModelProvider(widget.playlistId)).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(playlistDetailViewModelProvider(widget.playlistId));
    final state = vm.state;
    return AppScaffold(
      safeBottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 170),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: context.pop,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              Expanded(
                child: Text(
                  state.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: state.tracks.isEmpty ? null : () => vm.playAll(),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play all'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: state.tracks.isEmpty
                    ? null
                    : () => vm.playAll(shuffle: true),
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text('Shuffle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.tracks.isEmpty && !state.loading)
            const EmptyState(title: 'This playlist is empty.')
          else
            for (final track in state.tracks)
              SongCard(
                track: track,
                onTap: () => vm.playAll(),
                onLike: () => vm.toggleLike(track),
                onDelete: () => vm.remove(track),
              ),
        ],
      ),
    );
  }
}
