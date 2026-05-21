import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/models/track.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/app_action_button.dart';
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
  bool _deletingAllFromServer = false;
  bool _downloadingAllFromServer = false;

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
          if (widget.kind == HomeCollectionKind.server) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppActionButton(
                  onPressed:
                      _loading ||
                          !onlineAvailable ||
                          _tracks.isEmpty ||
                          _deletingAllFromServer ||
                          _downloadingAllFromServer
                      ? null
                      : _confirmDeleteAllFromServer,
                  icon: Icons.delete_sweep_rounded,
                  label: 'Delete all from server',
                  danger: true,
                  loading: _deletingAllFromServer,
                ),
                AppActionButton(
                  onPressed:
                      _loading ||
                          !onlineAvailable ||
                          _tracks.isEmpty ||
                          _deletingAllFromServer ||
                          _downloadingAllFromServer
                      ? null
                      : _downloadAllFromServer,
                  icon: Icons.download_rounded,
                  label: 'Download all from server',
                  filled: true,
                  loading: _downloadingAllFromServer,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (_tracks.isEmpty && !_loading)
            EmptyState(title: 'No tracks yet.')
          else
            for (final track in _tracks)
              SongCard(
                track: track,
                isPlaying: currentTrackId == track.id,
                onlineAvailable: onlineAvailable,
                onTap: () => ref
                    .read(playerViewModelProvider)
                    .play(track, queue: _tracks),
                onLongPress: () => _showTrackActions(track, onlineAvailable),
                onLike: () => _toggleLike(track),
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
      await _refreshServerIfTrackExpired(error);
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
      final result = await backend.deleteTrack(resultId);
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
      _showMessage(result.message);
    } on ApiException catch (error) {
      await _refreshServerIfTrackExpired(error);
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not delete from server.');
    }
  }

  Future<void> _confirmDeleteAllFromServer() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all from server?'),
        content: const Text(
          'This clears server cached MP3s, the track catalog, and device-library records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (clear == true) {
      await _deleteAllFromServer();
    }
  }

  Future<void> _deleteAllFromServer() async {
    final backend = ref.read(backendRepositoryProvider);
    if (backend == null) {
      _showMessage('Connect Online Library first.');
      return;
    }
    setState(() => _deletingAllFromServer = true);
    try {
      final result = await backend.clearServerTemp();
      await ref.read(trackRepositoryProvider).markAllServerRemoved();
      await ref
          .read(appStartupControllerProvider)
          .refreshBackend(keepConnectedStatus: true);
      notifyLibraryChangedFromWidget(ref);
      if (!mounted) {
        return;
      }
      setState(() {
        _tracks = const [];
        _deletingAllFromServer = false;
      });
      _showMessage(result.message('server files'));
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _deletingAllFromServer = false);
      }
      _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _deletingAllFromServer = false);
      }
      _showMessage('Could not delete server songs.');
    }
  }

  Future<void> _downloadAllFromServer() async {
    final backend = ref.read(backendRepositoryProvider);
    if (backend == null) {
      _showMessage('Connect Online Library to download.');
      return;
    }
    setState(() => _downloadingAllFromServer = true);
    var downloaded = 0;
    var skipped = 0;
    var failed = 0;
    try {
      final settings = ref.read(themeControllerProvider).settings;
      final downloadService = ref.read(downloadServiceProvider);
      for (final track in List<Track>.of(_tracks)) {
        if (!mounted) {
          return;
        }
        if (track.isLocalPlayable) {
          skipped++;
          continue;
        }
        try {
          final updated = await downloadService.download(
            track: track,
            backend: backend,
            settings: settings,
          );
          if (updated == null) {
            skipped++;
          } else {
            downloaded++;
            _replaceTrack(updated);
          }
        } on ApiException catch (error) {
          await _refreshServerIfTrackExpired(error);
          failed++;
        } catch (_) {
          failed++;
        }
      }
      notifyLibraryChangedFromWidget(ref);
      await ref
          .read(appStartupControllerProvider)
          .refreshBackend(keepConnectedStatus: true);
      if (!mounted) {
        return;
      }
      setState(() => _downloadingAllFromServer = false);
      _showMessage(_downloadAllMessage(downloaded, skipped, failed));
    } catch (_) {
      if (mounted) {
        setState(() => _downloadingAllFromServer = false);
      }
      _showMessage('Could not download all server songs.');
    }
  }

  String _downloadAllMessage(int downloaded, int skipped, int failed) {
    final parts = <String>[];
    if (downloaded > 0) {
      parts.add('Downloaded $downloaded');
    }
    if (skipped > 0) {
      parts.add('Skipped $skipped');
    }
    if (failed > 0) {
      parts.add('Failed $failed');
    }
    if (parts.isEmpty) {
      return 'No server songs to download.';
    }
    return '${parts.join(', ')}.';
  }

  void _replaceTrack(Track updated) {
    setState(() {
      _tracks = [
        for (final track in _tracks) track.id == updated.id ? updated : track,
      ];
    });
  }

  Future<void> _refreshServerIfTrackExpired(ApiException error) async {
    if (!_isRefreshNeeded(error)) {
      return;
    }
    await ref
        .read(appStartupControllerProvider)
        .refreshBackend(keepConnectedStatus: true);
    if (mounted && widget.kind == HomeCollectionKind.server) {
      await _load();
    }
  }

  bool _isRefreshNeeded(ApiException error) {
    return error.needsTrackRefresh;
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
      onDownload: onlineAvailable ? () => _downloadTrack(track) : null,
      onShare: () => _shareTrack(track),
      onDeleteLocal: () => _deleteLocalState(track),
      onDeleteFromServer: onlineAvailable
          ? () => _deleteFromServer(track)
          : null,
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
