import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/models/playlist.dart';
import '../../../core/models/track.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/song_card.dart';
import '../../../core/widgets/track_actions_sheet.dart';
import '../../player/view_models/player_view_model.dart';
import '../../playlists/widgets/add_to_playlist_sheet.dart';
import '../../playlists/widgets/playlist_cover.dart';
import '../view_models/home_view_model.dart';
import '../widgets/home_section.dart';
import '../widgets/host_info_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(homeViewModelProvider).load(refreshStatus: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(homeViewModelProvider);
    final state = vm.state;
    final startup = ref.watch(appStartupControllerProvider);
    final player = ref.watch(playerViewModelProvider);
    final playbackSnapshot = player.state.snapshot;
    final currentTrackId = playbackSnapshot.currentTrack?.id;
    final onlineAvailable = startup.status.isConnected;
    final downloadProgress = ref.watch(downloadServiceProvider).progress;
    final tokens = context.themeTokens;
    return AppScaffold(
      safeBottom: false,
      child: RefreshIndicator(
        onRefresh: () => vm.refreshBackend(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 220),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sleewave',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (ref.watch(themeControllerProvider).settings.backendBaseUrl !=
                null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: HostInfoCard(
                  status: startup.status,
                  onTap: () => context.push('/settings/online-library'),
                  onRetry: () => vm.refreshBackend(force: true),
                ),
              ),
            if (state.playlists.isNotEmpty)
              HomeSection(
                title: 'Playlists',
                trailing: TextButton(
                  onPressed: () => context.go('/playlists'),
                  child: const Text('More'),
                ),
                child: SizedBox(
                  height: 102,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final playlist = state.playlists.take(4).toList()[index];
                      final active =
                          playbackSnapshot.activePlaylistId == playlist.id;
                      return InkWell(
                        onTap: () => context.push('/playlists/${playlist.id}'),
                        borderRadius: BorderRadius.circular(tokens.rowRadius),
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: active
                                ? context.palette.accentSoft
                                : context.palette.surface,
                            borderRadius: BorderRadius.circular(
                              tokens.rowRadius,
                            ),
                            border: Border.all(
                              color: active
                                  ? context.palette.strongBorder
                                  : context.palette.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  PlaylistCover(
                                    size: 34,
                                    colorHex: playlist.coverPath ?? playlist.id,
                                    isFavorite: playlist.isFavorite,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Play playlist',
                                    constraints: const BoxConstraints.tightFor(
                                      width: 36,
                                      height: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                    iconSize: 20,
                                    onPressed: playlist.trackCount == 0
                                        ? null
                                        : () {
                                            AppHaptics.light();
                                            _playPlaylist(playlist);
                                          },
                                    icon: Icon(
                                      active
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                playlist.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                active
                                    ? 'Playing now'
                                    : '${playlist.trackCount} tracks',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemCount: state.playlists.take(4).length,
                  ),
                ),
              ),
            if (state.recentTracks.isNotEmpty)
              HomeSection(
                title: 'Recently played',
                trailing: TextButton(
                  onPressed: () => context.push('/home/recent'),
                  child: const Text('More'),
                ),
                child: Column(
                  children: [
                    for (final track in state.recentTracks.take(3))
                      SongCard(
                        track: track,
                        isPlaying: currentTrackId == track.id,
                        onlineAvailable: onlineAvailable,
                        onTap: () =>
                            player.play(track, queue: state.recentTracks),
                        onLongPress: () =>
                            _showTrackActions(track, onlineAvailable),
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
              ),
            if (startup.status.isConnected)
              HomeSection(
                title: 'Saved on server',
                trailing: state.savedSongs.isEmpty
                    ? null
                    : TextButton(
                        onPressed: () => context.push('/home/server'),
                        child: const Text('More'),
                      ),
                child: state.savedSongs.isEmpty
                    ? const EmptyState(title: 'No server-cached tracks yet.')
                    : Column(
                        children: [
                          for (final track in state.savedSongs.take(3))
                            SongCard(
                              track: track,
                              isPlaying: currentTrackId == track.id,
                              onlineAvailable: onlineAvailable,
                              onTap: () =>
                                  player.play(track, queue: state.savedSongs),
                              onLongPress: () =>
                                  _showTrackActions(track, onlineAvailable),
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
              ),
            HomeSection(
              title: 'Offline library',
              child: state.localPreview.isEmpty
                  ? const EmptyState(
                      title: 'No local tracks yet.',
                      subtitle: 'Import audio files from Library.',
                    )
                  : Column(
                      children: [
                        for (final track in state.localPreview)
                          SongCard(
                            track: track,
                            isPlaying: currentTrackId == track.id,
                            onlineAvailable: onlineAvailable,
                            onTap: () =>
                                player.play(track, queue: state.localPreview),
                            onLongPress: () =>
                                _showTrackActions(track, onlineAvailable),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(Track track) async {
    final updated = await ref.read(homeViewModelProvider).toggleLike(track);
    ref.read(playerViewModelProvider).replaceCurrentTrack(updated);
    notifyLibraryChangedFromWidget(ref);
  }

  void _showAddToPlaylist(Track track) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => AddToPlaylistSheet(track: track),
    );
  }

  Future<void> _playPlaylist(Playlist playlist) async {
    final tracks = await ref
        .read(playlistRepositoryProvider)
        .tracksForPlaylist(playlist.id);
    if (!mounted || tracks.isEmpty) {
      return;
    }
    await ref
        .read(playerViewModelProvider)
        .play(tracks.first, queue: tracks, activePlaylistId: playlist.id);
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
        ref.read(homeViewModelProvider).replaceTrack(updated);
      }
      notifyLibraryChangedFromWidget(ref);
    } on ApiException catch (error) {
      await _refreshHomeIfTrackExpired(error);
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Download failed.');
    }
  }

  Future<void> _deleteLocalState(Track track) async {
    await ref.read(trackRepositoryProvider).deleteLocalState(track);
    notifyLibraryChangedFromWidget(ref);
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
      await _refreshHomeIfTrackExpired(error);
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
      if (updated == null) {
        ref.read(homeViewModelProvider).removeTrack(track);
      } else {
        ref.read(homeViewModelProvider).replaceTrack(updated);
      }
      await ref
          .read(appStartupControllerProvider)
          .refreshBackend(keepConnectedStatus: true);
      notifyLibraryChangedFromWidget(ref);
      _showMessage(result.message);
    } on ApiException catch (error) {
      await _refreshHomeIfTrackExpired(error);
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not delete from server.');
    }
  }

  Future<void> _refreshHomeIfTrackExpired(ApiException error) async {
    if (!error.needsTrackRefresh) {
      return;
    }
    await ref
        .read(appStartupControllerProvider)
        .refreshBackend(keepConnectedStatus: true);
    await ref.read(homeViewModelProvider).load();
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
