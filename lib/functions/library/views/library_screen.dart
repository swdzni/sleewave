import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/models/track.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/song_card.dart';
import '../../home/widgets/home_section.dart';
import '../../player/view_models/player_view_model.dart';
import '../../playlists/widgets/add_to_playlist_sheet.dart';
import '../view_models/library_view_model.dart';
import '../widgets/folder_header.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(libraryViewModelProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(libraryViewModelProvider);
    final state = vm.state;
    final currentTrackId = ref
        .watch(playerViewModelProvider)
        .state
        .snapshot
        .currentTrack
        ?.id;
    final sourceNames = {
      for (final source in ref.watch(appStartupControllerProvider).sources)
        source.id: source.name,
    };
    return AppScaffold(
      safeBottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 220),
        children: [
          FolderHeader(path: state.folderPath, onImport: vm.importFiles),
          const SizedBox(height: 24),
          HomeSection(
            title: 'Downloaded',
            child: state.downloaded.isEmpty
                ? const EmptyState(title: 'No downloaded tracks yet.')
                : Column(
                    children: [
                      for (final track in state.downloaded)
                        SongCard(
                          track: track,
                          isPlaying: currentTrackId == track.id,
                          sourceLabel: sourceNames[track.sourceId],
                          onTap: () => vm.play(track, queue: state.downloaded),
                          onLike: () => _toggleLike(track),
                          onAddToPlaylist: () => _showAddToPlaylist(track),
                          onDelete: () => vm.deleteTrack(track),
                        ),
                    ],
                  ),
          ),
          HomeSection(
            title: 'Imported',
            child: state.imported.isEmpty
                ? const EmptyState(title: 'No imported tracks yet.')
                : Column(
                    children: [
                      for (final track in state.imported)
                        SongCard(
                          track: track,
                          isPlaying: currentTrackId == track.id,
                          sourceLabel: sourceNames[track.sourceId],
                          onTap: () => vm.play(track, queue: state.imported),
                          onLike: () => _toggleLike(track),
                          onAddToPlaylist: () => _showAddToPlaylist(track),
                          onDelete: () => vm.deleteTrack(track),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(Track track) async {
    final updated = await ref.read(libraryViewModelProvider).toggleLike(track);
    ref.read(playerViewModelProvider).replaceCurrentTrack(updated);
  }

  void _showAddToPlaylist(Track track) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => AddToPlaylistSheet(track: track),
    );
  }
}
