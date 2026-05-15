import '../../../core/models/playlist.dart';
import '../../../core/models/server_status.dart';
import '../../../core/models/track.dart';

class HomeState {
  const HomeState({
    this.loading = true,
    this.status = const ServerStatus.unknown(),
    this.playlists = const [],
    this.recentTracks = const [],
    this.savedSongs = const [],
    this.localPreview = const [],
  });

  final bool loading;
  final ServerStatus status;
  final List<Playlist> playlists;
  final List<Track> recentTracks;
  final List<Track> savedSongs;
  final List<Track> localPreview;

  HomeState copyWith({
    bool? loading,
    ServerStatus? status,
    List<Playlist>? playlists,
    List<Track>? recentTracks,
    List<Track>? savedSongs,
    List<Track>? localPreview,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      status: status ?? this.status,
      playlists: playlists ?? this.playlists,
      recentTracks: recentTracks ?? this.recentTracks,
      savedSongs: savedSongs ?? this.savedSongs,
      localPreview: localPreview ?? this.localPreview,
    );
  }
}
