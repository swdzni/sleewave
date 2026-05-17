import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/models/track.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/song_card.dart';
import '../../../core/widgets/track_actions_sheet.dart';
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
    final onlineAvailable = ref
        .watch(appStartupControllerProvider)
        .status
        .isConnected;
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
                          onlineAvailable: onlineAvailable,
                          onTap: () => vm.play(track, queue: state.downloaded),
                          onLongPress: () =>
                              _showTrackActions(track, onlineAvailable),
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
                          onlineAvailable: onlineAvailable,
                          onTap: () => vm.play(track, queue: state.imported),
                          onLongPress: () =>
                              _showTrackActions(track, onlineAvailable),
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

  void _showTrackActions(Track track, bool onlineAvailable) {
    final sourceNames = {
      for (final source in ref.read(appStartupControllerProvider).sources)
        source.id: source.name,
    };
    showTrackActionsSheet(
      context: context,
      track: track,
      sourceLabel: sourceNames[track.sourceId],
      onLike: () => _toggleLike(track),
      onAddToPlaylist: () => _showAddToPlaylist(track),
      onShare: () => _shareTrack(track),
      onDeleteLocal: () =>
          ref.read(libraryViewModelProvider).deleteTrack(track),
      onDeleteFromServer: onlineAvailable
          ? () => _deleteFromServer(track)
          : null,
    );
  }

  Future<void> _deleteFromServer(Track track) async {
    final backend = ref.read(backendRepositoryProvider);
    final resultId = track.resultId;
    if (backend == null || resultId == null) {
      _showMessage('Connect Online Library first.');
      return;
    }
    try {
      final result = await backend.deleteTrack(resultId);
      await ref.read(trackRepositoryProvider).markServerRemoved(track);
      await ref
          .read(appStartupControllerProvider)
          .refreshBackend(keepConnectedStatus: true);
      notifyLibraryChangedFromWidget(ref);
      await ref.read(libraryViewModelProvider).load();
      _showMessage(result.message);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not delete from server.');
    }
  }

  Future<void> _shareTrack(Track track) async {
    try {
      await ref
          .read(trackShareServiceProvider)
          .share(
            track: track,
            settings: ref.read(themeControllerProvider).settings,
            backend: ref.read(backendRepositoryProvider),
          );
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
