import 'package:flutter_riverpod/legacy.dart';

import '../../../core/providers.dart';
import '../../../core/repositories/playlist_repository.dart';
import '../../../core/utils/safe_change_notifier.dart';
import '../models/playlists_state.dart';

class PlaylistsViewModel extends SafeChangeNotifier {
  PlaylistsViewModel(this._playlists);

  final PlaylistRepository _playlists;
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
    await load();
  }
}

final playlistsViewModelProvider =
    ChangeNotifierProvider.autoDispose<PlaylistsViewModel>((ref) {
      return PlaylistsViewModel(ref.read(playlistRepositoryProvider));
    });
