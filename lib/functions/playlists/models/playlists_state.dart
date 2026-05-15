import '../../../core/models/playlist.dart';

class PlaylistsState {
  const PlaylistsState({this.loading = true, this.playlists = const []});

  final bool loading;
  final List<Playlist> playlists;

  PlaylistsState copyWith({bool? loading, List<Playlist>? playlists}) {
    return PlaylistsState(
      loading: loading ?? this.loading,
      playlists: playlists ?? this.playlists,
    );
  }
}
