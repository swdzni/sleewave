import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sleewave/core/database/app_database.dart';
import 'package:sleewave/core/models/track.dart';
import 'package:sleewave/core/network/api_client.dart';
import 'package:sleewave/core/repositories/backend_repository.dart';
import 'package:sleewave/core/repositories/track_repository.dart';
import 'package:sleewave/core/services/playback/audio_player_engine.dart';
import 'package:sleewave/core/services/playback/playback_service.dart';
import 'package:sleewave/core/services/playback/queue_service.dart';

void main() {
  late AppDatabase db;
  late TrackRepository tracks;
  late QueueService queue;
  late _FakeAudioEngine engine;
  late PlaybackService playback;
  late BackendRepository backend;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    queue = QueueService();
    engine = _FakeAudioEngine();
    playback = PlaybackService(tracks, queue, engine: engine);
    backend = BackendRepository(ApiClient(baseUrl: 'http://example.test'));
  });

  tearDown(() async {
    playback.dispose();
    await db.close();
  });

  test('next and previous seek inside the prepared native playlist', () async {
    final queueTracks = [_track('one'), _track('two'), _track('three')];

    await playback.playTrack(
      queueTracks.first,
      backend: backend,
      queue: queueTracks,
      recentHistoryLimit: 20,
      directUrlSourceIds: const [],
    );

    expect(engine.setAudioSourcesCalls, 1);
    expect(engine.sources, hasLength(3));

    await playback.next(backend: backend);
    await _drain();

    expect(engine.setAudioSourcesCalls, 1);
    expect(engine.seekCalls.last.index, 1);
    expect(queue.index, 1);
    expect(playback.snapshot.currentTrack?.id, 'two');

    await playback.previous(backend: backend);
    await _drain();

    expect(engine.setAudioSourcesCalls, 1);
    expect(engine.seekCalls.last.index, 0);
    expect(queue.index, 0);
    expect(playback.snapshot.currentTrack?.id, 'one');
  });

  test(
    'jumping to a queue item seeks instead of rebuilding playback',
    () async {
      final queueTracks = [_track('one'), _track('two'), _track('three')];

      await playback.playTrack(
        queueTracks.first,
        backend: backend,
        queue: queueTracks,
        recentHistoryLimit: 20,
        directUrlSourceIds: const [],
      );

      await playback.jumpToQueueIndex(2, backend: backend);
      await _drain();

      expect(engine.setAudioSourcesCalls, 1);
      expect(engine.seekCalls.last.index, 2);
      expect(queue.index, 2);
      expect(playback.snapshot.currentTrack?.id, 'three');
    },
  );

  test(
    'native index changes update the app queue for background playback',
    () async {
      final queueTracks = [_track('one'), _track('two'), _track('three')];

      await playback.playTrack(
        queueTracks.first,
        backend: backend,
        queue: queueTracks,
        recentHistoryLimit: 20,
        directUrlSourceIds: const [],
      );

      engine.emitCurrentIndex(2);
      await _drain();

      expect(queue.index, 2);
      expect(playback.snapshot.currentTrack?.id, 'three');
    },
  );

  test('completion keeps the final track and queue visible', () async {
    final queueTracks = [_track('one'), _track('two')];

    await playback.playTrack(
      queueTracks.first,
      backend: backend,
      queue: queueTracks,
      recentHistoryLimit: 20,
      directUrlSourceIds: const [],
    );
    engine.emitCurrentIndex(1);
    await _drain();

    engine.complete();
    await _drain();

    expect(playback.snapshot.currentTrack?.id, 'two');
    expect(playback.snapshot.queue.map((track) => track.id), ['one', 'two']);
    expect(playback.snapshot.isPlaying, isFalse);
  });

  test('repeat-all completion wraps to the first visible queue item', () async {
    final queueTracks = [_track('one'), _track('two')];

    await playback.playTrack(
      queueTracks.first,
      backend: backend,
      queue: queueTracks,
      recentHistoryLimit: 20,
      directUrlSourceIds: const [],
    );
    await playback.cycleMode();
    await playback.cycleMode();
    engine.emitCurrentIndex(1);
    await _drain();

    engine.complete();
    await _drain();

    expect(engine.seekCalls.last.index, 0);
    expect(queue.index, 0);
    expect(playback.snapshot.currentTrack?.id, 'one');
    expect(playback.snapshot.isPlaying, isTrue);
  });

  test('repeat-one completion restarts the same native source', () async {
    final queueTracks = [_track('one'), _track('two')];

    await playback.playTrack(
      queueTracks.first,
      backend: backend,
      queue: queueTracks,
      recentHistoryLimit: 20,
      directUrlSourceIds: const [],
    );
    await playback.cycleMode();
    await playback.cycleMode();
    await playback.cycleMode();
    engine.emitCurrentIndex(1);
    await _drain();

    engine.complete();
    await _drain();

    expect(engine.seekCalls.last.index, isNull);
    expect(engine.seekCalls.last.position, Duration.zero);
    expect(queue.index, 1);
    expect(playback.snapshot.currentTrack?.id, 'two');
    expect(playback.snapshot.isPlaying, isTrue);
  });

  test('shuffle follows the displayed shuffled queue order', () async {
    final queueTracks = [_track('one'), _track('two'), _track('three')];

    await playback.playTrack(
      queueTracks.first,
      backend: backend,
      queue: queueTracks,
      recentHistoryLimit: 20,
      directUrlSourceIds: const [],
    );
    await playback.cycleMode();
    final expectedNextId = playback.snapshot.queue[1].id;

    await playback.next(backend: backend);
    await _drain();

    expect(queue.index, 1);
    expect(playback.snapshot.currentTrack?.id, expectedNextId);
  });

  test('queue reorder does not rebuild sources until requested', () async {
    final queueTracks = [_track('one'), _track('two'), _track('three')];

    await playback.playTrack(
      queueTracks.first,
      backend: backend,
      queue: queueTracks,
      recentHistoryLimit: 20,
      directUrlSourceIds: const [],
    );

    await playback.reorderQueue(2, 1);
    await _drain();

    expect(engine.setAudioSourcesCalls, 1);
    expect(playback.snapshot.queue.map((track) => track.id), [
      'one',
      'three',
      'two',
    ]);

    await playback.rebuildPreparedQueue();
    await _drain();

    expect(engine.setAudioSourcesCalls, 2);
  });

  test('player errors skip failed tracks and rebuild without them', () async {
    final queueTracks = [_track('one'), _track('two'), _track('three')];

    await playback.playTrack(
      queueTracks.first,
      backend: backend,
      queue: queueTracks,
      recentHistoryLimit: 20,
      directUrlSourceIds: const [],
    );

    engine.fail(PlayerException(404, 'not found', 0));
    await _drain();

    expect(engine.setAudioSourcesCalls, 2);
    expect(engine.sources, hasLength(2));
    expect(queue.index, 1);
    expect(playback.snapshot.currentTrack?.id, 'two');
  });

  test(
    'direct URL errors fall back once to the normal backend stream',
    () async {
      final track = _track('one', sourceId: 'src');

      await playback.playTrack(
        track,
        backend: backend,
        queue: [track],
        recentHistoryLimit: 20,
        directUrlSourceIds: const ['src'],
      );

      expect(
        _sourceUri(engine.sources.single).queryParameters['direct_url'],
        'true',
      );

      engine.fail(PlayerException(1, 'network', 0));
      await _drain();

      expect(engine.setAudioSourcesCalls, 2);
      expect(
        _sourceUri(engine.sources.single).queryParameters['direct_url'],
        isNull,
      );
      expect(playback.snapshot.currentTrack?.id, 'one');
    },
  );
}

Track _track(String id, {String sourceId = 'src'}) {
  final now = DateTime(2026);
  return Track(
    id: id,
    title: id,
    artist: 'Artist',
    sourceId: sourceId,
    resultId: 'result-$id',
    createdAt: now,
    updatedAt: now,
  );
}

Uri _sourceUri(AudioSource source) {
  return (source as UriAudioSource).uri;
}

Future<void> _drain() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _SeekCall {
  const _SeekCall(this.position, this.index);

  final Duration? position;
  final int? index;
}

class _FakeAudioEngine implements AudioPlayerEngine {
  final _playerState = StreamController<PlayerState>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _currentIndex = StreamController<int?>.broadcast();
  final _errors = StreamController<PlayerException>.broadcast();

  List<AudioSource> sources = const [];
  final seekCalls = <_SeekCall>[];
  int setAudioSourcesCalls = 0;

  @override
  bool playing = false;

  @override
  Duration position = Duration.zero;

  @override
  Duration? duration = const Duration(minutes: 3);

  @override
  int? currentIndex;

  @override
  ProcessingState processingState = ProcessingState.idle;

  @override
  Stream<PlayerException> get errorStream => _errors.stream;

  @override
  Stream<int?> get currentIndexStream => _currentIndex.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<PlayerState> get playerStateStream => _playerState.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Future<void> setAudioSources(
    List<AudioSource> sources, {
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    setAudioSourcesCalls += 1;
    this.sources = List.unmodifiable(sources);
    currentIndex = initialIndex ?? 0;
    position = initialPosition ?? Duration.zero;
    processingState = ProcessingState.ready;
    _currentIndex.add(currentIndex);
    _duration.add(duration);
    _position.add(position);
    _playerState.add(PlayerState(playing, processingState));
  }

  @override
  Future<void> play() async {
    playing = true;
    _playerState.add(PlayerState(playing, processingState));
  }

  @override
  Future<void> pause() async {
    playing = false;
    _playerState.add(PlayerState(playing, processingState));
  }

  @override
  Future<void> stop() async {
    playing = false;
    processingState = ProcessingState.idle;
    currentIndex = null;
    _currentIndex.add(null);
    _playerState.add(PlayerState(playing, processingState));
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    seekCalls.add(_SeekCall(position, index));
    this.position = position ?? Duration.zero;
    if (index != null) {
      currentIndex = index;
      _currentIndex.add(index);
    }
    _position.add(this.position);
  }

  @override
  Future<void> setLoopMode(LoopMode loopMode) async {}

  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {
    await _playerState.close();
    await _position.close();
    await _duration.close();
    await _currentIndex.close();
    await _errors.close();
  }

  void emitCurrentIndex(int index) {
    currentIndex = index;
    _currentIndex.add(index);
  }

  void complete() {
    playing = false;
    processingState = ProcessingState.completed;
    _playerState.add(PlayerState(playing, processingState));
  }

  void fail(PlayerException error) {
    _errors.add(error);
  }
}
