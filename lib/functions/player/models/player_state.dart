import '../../../core/models/playback_models.dart';

class PlayerState {
  const PlayerState({this.snapshot = const PlaybackSnapshot()});

  final PlaybackSnapshot snapshot;
}
