import 'package:flutter_riverpod/legacy.dart';

import '../../../core/app_startup_controller.dart';
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
    _state = HomeState(
      loading: false,
      status: _startup.status,
      playlists: playlists
          .where((playlist) => !playlist.isFavorite || playlist.trackCount > 0)
          .toList(),
      recentTracks: recent,
      savedSongs: _startup.savedSongs,
      localPreview: local.take(8).toList(),
    );
    notifyListeners();
  }

  Future<void> refreshBackend() async {
    await _startup.refreshBackend();
    await load();
  }
}

final homeViewModelProvider = ChangeNotifierProvider.autoDispose<HomeViewModel>(
  (ref) {
    return HomeViewModel(
      ref.watch(trackRepositoryProvider),
      ref.watch(playlistRepositoryProvider),
      ref.read(appStartupControllerProvider),
    );
  },
);
