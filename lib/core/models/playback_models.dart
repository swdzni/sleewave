import 'track.dart';

enum PlaybackMode {
  normal,
  shuffle,
  repeatAll,
  repeatOne;

  PlaybackMode get next {
    final nextIndex = (index + 1) % PlaybackMode.values.length;
    return PlaybackMode.values[nextIndex];
  }
}

class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.currentTrack,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.mode = PlaybackMode.normal,
    this.queue = const [],
    this.error,
  });

  final Track? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final PlaybackMode mode;
  final List<Track> queue;
  final String? error;

  bool get hasTrack => currentTrack != null;

  PlaybackSnapshot copyWith({
    Object? currentTrack = _sentinel,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    PlaybackMode? mode,
    List<Track>? queue,
    Object? error = _sentinel,
  }) {
    return PlaybackSnapshot(
      currentTrack: currentTrack == _sentinel
          ? this.currentTrack
          : currentTrack as Track?,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      mode: mode ?? this.mode,
      queue: queue ?? this.queue,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();
