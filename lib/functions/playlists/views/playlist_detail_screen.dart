import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/models/track.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/song_card.dart';
import '../../../core/widgets/track_actions_sheet.dart';
import '../../player/view_models/player_view_model.dart';
import '../view_models/playlist_detail_view_model.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/playlist_editor_sheet.dart';

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
    final downloadProgress = ref.watch(downloadServiceProvider).progress;
    return AppScaffold(
      safeBottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 220),
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
              if (!state.isFavorite)
                IconButton(
                  tooltip: 'Rename',
                  onPressed: () => _showRenameSheet(vm, state.name),
                  icon: const Icon(Icons.edit_rounded),
                ),
              if (!state.isFavorite)
                IconButton(
                  tooltip: 'Delete playlist',
                  onPressed: () => _confirmDeletePlaylist(vm, state.name),
                  icon: const Icon(Icons.delete_outline_rounded),
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
                isPlaying: currentTrackId == track.id,
                onlineAvailable: onlineAvailable,
                onTap: () => vm.playFrom(track),
                onLongPress: () => _showTrackActions(track, onlineAvailable),
                onLike: () => vm.toggleLike(track),
                onAddToPlaylist: () => _showAddToPlaylist(track),
                onDownload: onlineAvailable
                    ? () => _downloadTrack(track)
                    : null,
                onDelete: () => _deleteLocalState(track),
                downloadProgress: downloadProgress[track.id],
              ),
        ],
      ),
    );
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
      onLike: () => ref
          .read(playlistDetailViewModelProvider(widget.playlistId))
          .toggleLike(track),
      onAddToPlaylist: () => _showAddToPlaylist(track),
      onRemoveFromPlaylist: () => ref
          .read(playlistDetailViewModelProvider(widget.playlistId))
          .remove(track),
      onDownload: onlineAvailable ? () => _downloadTrack(track) : null,
      onShare: () => _shareTrack(track),
      onDeleteLocal: () => _deleteLocalState(track),
      onDeleteFromServer: onlineAvailable
          ? () => _deleteFromServer(track)
          : null,
    );
  }

  Future<void> _showRenameSheet(
    PlaylistDetailViewModel vm,
    String currentName,
  ) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => PlaylistEditorSheet(
        title: 'Rename playlist',
        actionLabel: 'Rename',
        initialName: currentName,
      ),
    );
    if (name != null) {
      await vm.rename(name);
    }
  }

  Future<void> _confirmDeletePlaylist(
    PlaylistDetailViewModel vm,
    String name,
  ) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete playlist?'),
        content: Text('This removes "$name" from Playlists.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (delete == true && mounted) {
      await vm.deletePlaylist();
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<void> _downloadTrack(Track track) async {
    final backend = ref.read(backendRepositoryProvider);
    if (backend == null) {
      _showMessage('Connect Online Library to download.');
      return;
    }
    if (track.resultId == null) {
      _showMessage('Refresh this track before download.');
      return;
    }
    try {
      final updated = await ref
          .read(downloadServiceProvider)
          .download(
            track: track,
            backend: backend,
            settings: ref.read(themeControllerProvider).settings,
          );
      if (updated != null) {
        ref
            .read(playlistDetailViewModelProvider(widget.playlistId))
            .replaceTrack(updated);
      }
      notifyLibraryChangedFromWidget(ref);
    } on ApiException catch (error) {
      await _refreshBackendIfTrackExpired(error);
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Download failed. Try again.');
    }
  }

  Future<void> _deleteLocalState(Track track) async {
    await ref.read(trackRepositoryProvider).deleteLocalState(track);
    notifyLibraryChangedFromWidget(ref);
    await ref.read(playlistDetailViewModelProvider(widget.playlistId)).load();
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
      await _refreshBackendIfTrackExpired(error);
      _showMessage(error.message);
    } catch (error) {
      _showMessage(error.toString());
    }
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
      final updated = await ref
          .read(trackRepositoryProvider)
          .markServerRemoved(track);
      final vm = ref.read(playlistDetailViewModelProvider(widget.playlistId));
      if (updated == null) {
        await vm.remove(track);
      } else {
        vm.replaceTrack(updated);
      }
      await ref
          .read(appStartupControllerProvider)
          .refreshBackend(keepConnectedStatus: true);
      notifyLibraryChangedFromWidget(ref);
      _showMessage(result.message);
    } on ApiException catch (error) {
      await _refreshBackendIfTrackExpired(error);
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not delete from server.');
    }
  }

  Future<void> _refreshBackendIfTrackExpired(ApiException error) async {
    if (!error.needsTrackRefresh) {
      return;
    }
    await ref
        .read(appStartupControllerProvider)
        .refreshBackend(keepConnectedStatus: true);
    await ref.read(playlistDetailViewModelProvider(widget.playlistId)).load();
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
