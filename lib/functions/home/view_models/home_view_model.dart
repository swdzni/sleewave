import 'package:flutter_riverpod/legacy.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/models/track.dart';
import '../../../core/providers.dart';
import '../../../core/repositories/playlist_repository.dart';
import '../../../core/repositories/track_repository.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/safe_change_notifier.dart';
import '../models/home_state.dart';

class HomeViewModel extends SafeChangeNotifier {
  HomeViewModel(this._tracks, this._playlists, this._startup, this._theme)
    : _state = HomeState(status: _startup.status);

  final TrackRepository _tracks;
  final PlaylistRepository _playlists;
  final AppStartupController _startup;
  final ThemeController _theme;
  HomeState _state;
  int _loadGeneration = 0;
  Future<void>? _activeLoad;

  HomeState get state => _state;

  Future<void> load({bool refreshStatus = false}) async {
    if (!refreshStatus) {
      final activeLoad = _activeLoad;
      if (activeLoad != null) {
        return activeLoad;
      }
    }
    final load = _load(refreshStatus: refreshStatus);
    _activeLoad = load;
    try {
      await load;
    } finally {
      if (identical(_activeLoad, load)) {
        _activeLoad = null;
      }
    }
  }

  Future<void> _load({required bool refreshStatus}) async {
    final generation = ++_loadGeneration;
    _state = _state.copyWith(loading: true);
    notifyListeners();
    if (refreshStatus) {
      await _startup.refreshBackend(keepConnectedStatus: true);
    }
    final playlists = await _playlists.allPlaylists();
    final recent = await _tracks.recentTracks(
      limit: _theme.settings.recentHistoryLimit,
    );
    final local = await _tracks.localTracks();
    final savedSongs = await _hydrateTracks(_startup.savedSongs);
    if (generation != _loadGeneration) {
      return;
    }
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

  Future<void> clearRecentlyPlayed() async {
    await _tracks.clearRecentlyPlayed();
    _state = _state.copyWith(recentTracks: const []);
    notifyListeners();
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

  void removeTrack(Track removed) {
    _state = HomeState(
      loading: _state.loading,
      status: _state.status,
      playlists: _state.playlists,
      recentTracks: _removeTrack(_state.recentTracks, removed),
      savedSongs: _removeTrack(_state.savedSongs, removed),
      localPreview: _removeTrack(_state.localPreview, removed),
    );
    notifyListeners();
  }

  List<Track> _replaceTrack(List<Track> tracks, Track updated) {
    return [
      for (final track in tracks) track.id == updated.id ? updated : track,
    ];
  }

  List<Track> _removeTrack(List<Track> tracks, Track removed) {
    return [
      for (final track in tracks)
        if (track.id != removed.id) track,
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
      ref.watch(themeControllerProvider),
    );
    ref.listen<AppStartupController>(appStartupControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.status != next.status ||
          previous?.savedSongs != next.savedSongs) {
        vm.load();
      }
    });
    ref.listen<int>(libraryRevisionProvider, (previous, next) {
      vm.load();
    });
    return vm;
  },
);
