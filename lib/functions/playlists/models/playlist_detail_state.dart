import '../../../core/models/track.dart';

class PlaylistDetailState {
  const PlaylistDetailState({
    this.loading = true,
    this.name = '',
    this.isFavorite = false,
    this.tracks = const [],
  });

  final bool loading;
  final String name;
  final bool isFavorite;
  final List<Track> tracks;

  PlaylistDetailState copyWith({
    bool? loading,
    String? name,
    bool? isFavorite,
    List<Track>? tracks,
  }) {
    return PlaylistDetailState(
      loading: loading ?? this.loading,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
      tracks: tracks ?? this.tracks,
    );
  }
}
