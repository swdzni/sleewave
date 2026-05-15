import 'package:flutter_riverpod/legacy.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/models/track.dart';
import '../../../core/providers.dart';
import '../../../core/repositories/playlist_repository.dart';
import '../../../core/repositories/track_repository.dart';
import '../../../core/utils/safe_change_notifier.dart';
import '../models/home_state.dart';

class HomeViewModel extends SafeChangeNotifier {
  HomeViewModel(this._tracks, this._playlists, this._startup);

  final TrackRepository _tracks;
  final PlaylistRepository _playlists;
  final AppStartupController _startup;
  HomeState _state = const HomeState();

  HomeState get state => _state;

  Future<void> load({bool refreshStatus = false}) async {
    _state = _state.copyWith(loading: true);
    notifyListeners();
    if (refreshStatus) {
      await _startup.refreshBackend(keepConnectedStatus: true);
    }
    final playlists = await _playlists.allPlaylists();
    final recent = await _tracks.recentTracks(limit: 8);
    final local = await _tracks.localTracks();
    final savedSongs = await _hydrateTracks(_startup.savedSongs);
    _state = HomeState(
      loading: false,
      status: _startup.status,
      playlists: playlists
          .where((playlist) => !playlist.isFavorite || playlist.trackCount > 0)
          .toList(),
      recentTracks: recent,
      savedSongs: savedSongs,
      localPreview: local.take(8).toList(),
    );
    notifyListeners();
  }

  Future<void> refreshBackend() async {
    await _startup.refreshBackend();
    await load();
  }

  Future<Track> toggleLike(Track track) async {
    final updated = await _tracks.toggleLike(track);
    replaceTrack(updated);
    return updated;
  }

  void replaceTrack(Track updated) {
    _state = HomeState(
      loading: _state.loading,
      status: _state.status,
      playlists: _state.playlists,
      recentTracks: _replaceTrack(_state.recentTracks, updated),
      savedSongs: _replaceTrack(_state.savedSongs, updated),
      localPreview: _replaceTrack(_state.localPreview, updated),
    );
    notifyListeners();
  }

  List<Track> _replaceTrack(List<Track> tracks, Track updated) {
    return [
      for (final track in tracks) track.id == updated.id ? updated : track,
    ];
  }

  Future<List<Track>> _hydrateTracks(List<Track> tracks) async {
    final hydrated = <Track>[];
    for (final track in tracks) {
      hydrated.add(await _tracks.byId(track.id) ?? track);
    }
    return hydrated;
  }
}

final homeViewModelProvider = ChangeNotifierProvider.autoDispose<HomeViewModel>(
  (ref) {
    final vm = HomeViewModel(
      ref.watch(trackRepositoryProvider),
      ref.watch(playlistRepositoryProvider),
      ref.read(appStartupControllerProvider),
    );
    ref.listen<AppStartupController>(appStartupControllerProvider, (
      previous,
      next,
    ) {
      vm.load();
    });
    ref.listen<int>(libraryRevisionProvider, (previous, next) {
      vm.load();
    });
    return vm;
  },
);
