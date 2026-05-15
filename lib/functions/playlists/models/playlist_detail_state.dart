import '../../../core/models/track.dart';

class PlaylistDetailState {
  const PlaylistDetailState({
    this.loading = true,
    this.name = '',
    this.tracks = const [],
  });

  final bool loading;
  final String name;
  final List<Track> tracks;

  PlaylistDetailState copyWith({
    bool? loading,
    String? name,
    List<Track>? tracks,
  }) {
    return PlaylistDetailState(
      loading: loading ?? this.loading,
      name: name ?? this.name,
      tracks: tracks ?? this.tracks,
    );
  }
}
