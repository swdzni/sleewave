import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/playlist.dart';
import '../../../core/providers.dart';
import '../../../core/repositories/playlist_repository.dart';
import '../../../core/utils/safe_change_notifier.dart';
import '../models/playlists_state.dart';

class PlaylistsViewModel extends SafeChangeNotifier {
  PlaylistsViewModel(this._playlists, this._ref);

  final PlaylistRepository _playlists;
  final Ref _ref;
  PlaylistsState _state = const PlaylistsState();

  PlaylistsState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(loading: true);
    notifyListeners();
    _state = PlaylistsState(
      loading: false,
      playlists: await _playlists.allPlaylists(),
    );
    notifyListeners();
  }

  Future<void> create(String name) async {
    if (name.trim().isEmpty) {
      return;
    }
    await _playlists.create(name);
    notifyLibraryChanged(_ref);
    await load();
  }

  Future<void> rename(Playlist playlist, String name) async {
    if (name.trim().isEmpty || playlist.isFavorite) {
      return;
    }
    await _playlists.rename(playlist, name);
    notifyLibraryChanged(_ref);
    await load();
  }

  Future<void> delete(Playlist playlist) async {
    if (playlist.isFavorite) {
      return;
    }
    await _playlists.delete(playlist);
    notifyLibraryChanged(_ref);
    await load();
  }
}

final playlistsViewModelProvider =
    ChangeNotifierProvider.autoDispose<PlaylistsViewModel>((ref) {
      final vm = PlaylistsViewModel(ref.read(playlistRepositoryProvider), ref);
      ref.listen<int>(libraryRevisionProvider, (previous, next) {
        vm.load();
      });
      return vm;
    });
