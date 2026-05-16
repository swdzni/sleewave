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
import '../../playlists/widgets/add_to_playlist_sheet.dart';

enum HomeCollectionKind {
  recent,
  server;

  String get title => switch (this) {
    HomeCollectionKind.recent => 'Recently played',
    HomeCollectionKind.server => 'Saved on server',
  };
}

class HomeCollectionScreen extends ConsumerStatefulWidget {
  const HomeCollectionScreen({super.key, required this.kind});

  final HomeCollectionKind kind;

  @override
  ConsumerState<HomeCollectionScreen> createState() =>
      _HomeCollectionScreenState();
}

class _HomeCollectionScreenState extends ConsumerState<HomeCollectionScreen> {
  List<Track> _tracks = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
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
    final downloadProgress = ref.watch(downloadServiceProvider).progress;
    final onlineAvailable = ref
        .watch(appStartupControllerProvider)
        .status
        .isConnected;
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
                  widget.kind.title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              if (widget.kind == HomeCollectionKind.recent &&
                  _tracks.isNotEmpty)
                IconButton(
                  tooltip: 'Clear recently played',
                  onPressed: _confirmClearRecentlyPlayed,
                  icon: const Icon(Icons.delete_sweep_rounded),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tracks.isEmpty && !_loading)
            EmptyState(title: 'No tracks yet.')
          else
            for (final track in _tracks)
              SongCard(
                track: track,
                isPlaying: currentTrackId == track.id,
                sourceLabel: sourceNames[track.sourceId],
                onlineAvailable: onlineAvailable,
                onTap: () => ref
                    .read(playerViewModelProvider)
                    .play(track, queue: _tracks),
                onLongPress: () => _showTrackActions(track),
                onLike: () => _toggleLike(track),
                onAddToPlaylist: () => _showAddToPlaylist(track),
                onDownload: () => _downloadTrack(track),
                onDelete: () => _deleteLocalState(track),
                downloadProgress: downloadProgress[track.id],
              ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final next = switch (widget.kind) {
      HomeCollectionKind.recent =>
        await ref
            .read(trackRepositoryProvider)
            .recentTracks(
              limit: ref
                  .read(themeControllerProvider)
                  .settings
                  .recentHistoryLimit,
            ),
      HomeCollectionKind.server => await _serverTracks(),
    };
    if (mounted) {
      setState(() {
        _tracks = next;
        _loading = false;
      });
    }
  }

  Future<List<Track>> _serverTracks() async {
    final startup = ref.read(appStartupControllerProvider);
    await startup.refreshBackend(keepConnectedStatus: true);
    final repository = ref.read(trackRepositoryProvider);
    final hydrated = <Track>[];
    for (final track in startup.savedSongs) {
      hydrated.add(await repository.byId(track.id) ?? track);
    }
    return hydrated;
  }

  Future<void> _confirmClearRecentlyPlayed() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear recently played?'),
        content: const Text('This removes every track from your play history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear != true || !mounted) {
      return;
    }
    await ref.read(trackRepositoryProvider).clearRecentlyPlayed();
    notifyLibraryChangedFromWidget(ref);
    if (!mounted) {
      return;
    }
    setState(() {
      _tracks = const [];
    });
    _showMessage('Recently played cleared.');
  }

  Future<void> _toggleLike(Track track) async {
    final updated = await ref.read(trackRepositoryProvider).toggleLike(track);
    ref.read(playerViewModelProvider).replaceCurrentTrack(updated);
    _replaceTrack(updated);
    notifyLibraryChangedFromWidget(ref);
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
        _replaceTrack(updated);
      }
      notifyLibraryChangedFromWidget(ref);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Download failed. Try again.');
    }
  }

  Future<void> _deleteLocalState(Track track) async {
    await ref.read(trackRepositoryProvider).deleteLocalState(track);
    notifyLibraryChangedFromWidget(ref);
    await _load();
  }

  Future<void> _deleteFromServer(Track track) async {
    final backend = ref.read(backendRepositoryProvider);
    final resultId = track.resultId;
    if (backend == null || resultId == null) {
      _showMessage('Connect Online Library first.');
      return;
    }
    try {
      await backend.deleteTrack(resultId);
      final updated = await ref
          .read(trackRepositoryProvider)
          .markServerRemoved(track);
      if (updated == null) {
        setState(() {
          _tracks = [
            for (final item in _tracks)
              if (item.id != track.id) item,
          ];
        });
      } else {
        _replaceTrack(updated);
      }
      await ref
          .read(appStartupControllerProvider)
          .refreshBackend(keepConnectedStatus: true);
      notifyLibraryChangedFromWidget(ref);
      _showMessage('Deleted from server.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not delete from server.');
    }
  }

  void _replaceTrack(Track updated) {
    setState(() {
      _tracks = [
        for (final track in _tracks) track.id == updated.id ? updated : track,
      ];
    });
  }

  void _showAddToPlaylist(Track track) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => AddToPlaylistSheet(track: track),
    );
  }

  void _showTrackActions(Track track) {
    showTrackActionsSheet(
      context: context,
      track: track,
      onLike: () => _toggleLike(track),
      onAddToPlaylist: () => _showAddToPlaylist(track),
      onDownload: () => _downloadTrack(track),
      onDeleteLocal: () => _deleteLocalState(track),
      onDeleteFromServer: () => _deleteFromServer(track),
    );
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
