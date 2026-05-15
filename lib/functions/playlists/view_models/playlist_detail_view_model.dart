import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/track.dart';
import '../../../core/providers.dart';
import '../../../core/repositories/playlist_repository.dart';
import '../../../core/repositories/track_repository.dart';
import '../../../core/utils/safe_change_notifier.dart';
import '../../player/view_models/player_view_model.dart';
import '../models/playlist_detail_state.dart';

class PlaylistDetailViewModel extends SafeChangeNotifier {
  PlaylistDetailViewModel(
    this._playlistId,
    this._playlists,
    this._tracks,
    this._ref,
  );

  final String _playlistId;
  final PlaylistRepository _playlists;
  final TrackRepository _tracks;
  final Ref _ref;
  PlaylistDetailState _state = const PlaylistDetailState();

  PlaylistDetailState get state => _state;

  Future<void> load() async {
    final playlists = await _playlists.allPlaylists();
    final playlist = playlists.firstWhere(
      (item) => item.id == _playlistId,
      orElse: () => playlists.first,
    );
    _state = PlaylistDetailState(
      loading: false,
      name: playlist.name,
      tracks: await _playlists.tracksForPlaylist(_playlistId),
    );
    notifyListeners();
  }

  Future<void> playAll({bool shuffle = false}) async {
    if (_state.tracks.isEmpty) {
      return;
    }
    final queue = [..._state.tracks];
    if (shuffle) {
      queue.shuffle();
    }
    await _ref.read(playerViewModelProvider).play(queue.first, queue: queue);
  }

  Future<void> remove(Track track) async {
    await _playlists.removeTrack(_playlistId, track);
    await load();
  }

  Future<void> toggleLike(Track track) async {
    await _tracks.toggleLike(track);
    await load();
  }

  bool get isFavorite => _playlistId == AppConstants.favoritePlaylistId;
}

final playlistDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<PlaylistDetailViewModel, String>((ref, playlistId) {
      return PlaylistDetailViewModel(
        playlistId,
        ref.read(playlistRepositoryProvider),
        ref.read(trackRepositoryProvider),
        ref,
      );
    });
