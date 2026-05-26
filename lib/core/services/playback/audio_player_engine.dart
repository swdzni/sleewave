import 'package:just_audio/just_audio.dart';

abstract class AudioPlayerEngine {
  Stream<PlayerState> get playerStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<int?> get currentIndexStream;
  Stream<PlayerException> get errorStream;

  bool get playing;
  Duration get position;
  Duration? get duration;
  int? get currentIndex;
  ProcessingState get processingState;

  Future<void> setAudioSources(
    List<AudioSource> sources, {
    int? initialIndex,
    Duration? initialPosition,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration? position, {int? index});
  Future<void> moveAudioSource(int currentIndex, int newIndex);
  Future<void> setLoopMode(LoopMode loopMode);
  Future<void> setShuffleModeEnabled(bool enabled);
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}

class JustAudioPlayerEngine implements AudioPlayerEngine {
  JustAudioPlayerEngine([AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  @override
  Stream<PlayerException> get errorStream => _player.errorStream;

  @override
  bool get playing => _player.playing;

  @override
  Duration get position => _player.position;

  @override
  Duration? get duration => _player.duration;

  @override
  int? get currentIndex => _player.currentIndex;

  @override
  ProcessingState get processingState => _player.processingState;

  @override
  Future<void> setAudioSources(
    List<AudioSource> sources, {
    int? initialIndex,
    Duration? initialPosition,
  }) {
    return _player.setAudioSources(
      sources,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration? position, {int? index}) {
    return _player.seek(position, index: index);
  }

  @override
  Future<void> moveAudioSource(int currentIndex, int newIndex) {
    return _player.moveAudioSource(currentIndex, newIndex);
  }

  @override
  Future<void> setLoopMode(LoopMode loopMode) => _player.setLoopMode(loopMode);

  @override
  Future<void> setShuffleModeEnabled(bool enabled) {
    return _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() => _player.dispose();
}
