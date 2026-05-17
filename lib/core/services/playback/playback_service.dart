import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../constants/app_constants.dart';
import '../../models/playback_models.dart';
import '../../models/track.dart';
import '../../network/api_exception.dart';
import '../../repositories/backend_repository.dart';
import '../../repositories/track_repository.dart';
import '../../utils/safe_change_notifier.dart';
import 'backend_stream_audio_source.dart';
import 'queue_service.dart';

class PlaybackService extends SafeChangeNotifier {
  PlaybackService(this._tracks, this._queue) {
    if (Platform.isIOS) {
      _remoteControlsChannel.setMethodCallHandler(_handleRemoteCommand);
      _scheduleRemoteControlsRefresh();
    }
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        _snapshot = _snapshot.copyWith(
          isPlaying: state.playing,
          isBuffering:
              state.processingState == ProcessingState.buffering ||
              state.processingState == ProcessingState.loading,
        );
        notifyListeners();
        _scheduleRemoteControlsRefresh();
        if (state.processingState == ProcessingState.completed) {
          unawaited(_handleCompleted());
        }
      }),
    );
    _subscriptions.add(
      _player.positionStream.listen((position) {
        _snapshot = _snapshot.copyWith(position: position);
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        _snapshot = _snapshot.copyWith(
          duration: duration ?? _durationFor(_snapshot.currentTrack),
        );
        notifyListeners();
      }),
    );
  }

  final TrackRepository _tracks;
  final QueueService _queue;
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  PlaybackSnapshot _snapshot = const PlaybackSnapshot();
  BackendRepository? _lastBackend;
  int _recentHistoryLimit = AppConstants.defaultRecentHistoryLimit;
  bool _handlingCompletion = false;
  Timer? _rewindTimer;
  Timer? _remoteControlsTimer;
  bool _fastForwarding = false;
  int _loadGeneration = 0;

  static const _restartThreshold = Duration(seconds: 3);
  static const _remoteControlsChannel = MethodChannel(
    'sleewave/remote_controls',
  );

  PlaybackSnapshot get snapshot => _snapshot;

  Future<void> playTrack(
    Track track, {
    BackendRepository? backend,
    List<Track>? queue,
    String? activePlaylistId,
    required int recentHistoryLimit,
  }) async {
    _lastBackend = backend;
    _recentHistoryLimit = recentHistoryLimit;
    if (queue != null && queue.isNotEmpty) {
      final startIndex = queue.indexWhere((item) => item.id == track.id);
      _queue.setQueue(
        startIndex == -1 ? [...queue, track] : queue,
        startIndex: startIndex == -1 ? queue.length : startIndex,
      );
    } else {
      _queue.setSingle(track);
    }
    await _loadAndPlay(
      track,
      backend: backend,
      activePlaylistId: activePlaylistId,
    );
  }

  Future<void> jumpToQueueIndex(int index, {BackendRepository? backend}) async {
    _lastBackend = backend ?? _lastBackend;
    if (index == _queue.index) {
      return;
    }
    _queue.jumpTo(index);
    final track = _queue.current;
    if (track != null) {
      await _loadAndPlay(track, backend: backend ?? _lastBackend);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> stop() async {
    _loadGeneration++;
    await _player.stop();
    _snapshot = _snapshot.copyWith(isPlaying: false, isBuffering: false);
    notifyListeners();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> restartOrPrevious({BackendRepository? backend}) async {
    if (_snapshot.position > _restartThreshold || !_queue.canGoPrevious) {
      await _player.seek(Duration.zero);
      _snapshot = _snapshot.copyWith(position: Duration.zero);
      notifyListeners();
      return;
    }
    await previous(backend: backend);
  }

  Future<bool> next({BackendRepository? backend}) async {
    _lastBackend = backend ?? _lastBackend;
    final nextTrack = _queue.next(
      wrap: _snapshot.mode == PlaybackMode.repeatAll,
    );
    if (nextTrack == null) {
      return false;
    }
    await _loadAndPlay(nextTrack, backend: backend ?? _lastBackend);
    return true;
  }

  Future<bool> previous({BackendRepository? backend}) async {
    _lastBackend = backend ?? _lastBackend;
    final previousTrack = _queue.previous();
    if (previousTrack == null) {
      return false;
    }
    await _loadAndPlay(previousTrack, backend: backend ?? _lastBackend);
    return true;
  }

  Future<void> cycleMode() async {
    final mode = _snapshot.mode.next;
    await _player.setShuffleModeEnabled(false);
    await _player.setLoopMode(LoopMode.off);
    if (mode == PlaybackMode.shuffle) {
      _queue.shuffleKeepingCurrent();
    }
    _snapshot = _snapshot.copyWith(mode: mode, queue: _queue.queue);
    notifyListeners();
  }

  void replaceCurrentTrack(Track track) {
    if (_snapshot.currentTrack?.id != track.id) {
      return;
    }
    final queue = [
      for (final item in _snapshot.queue) item.id == track.id ? track : item,
    ];
    _snapshot = _snapshot.copyWith(currentTrack: track, queue: queue);
    notifyListeners();
  }

  Future<void> beginFastForward() async {
    if (_fastForwarding) {
      return;
    }
    _fastForwarding = true;
    await _player.setSpeed(2.6);
  }

  Future<void> endFastForward() async {
    if (!_fastForwarding) {
      return;
    }
    _fastForwarding = false;
    await _player.setSpeed(1);
  }

  void beginRewind() {
    _rewindTimer?.cancel();
    _rewindTimer = Timer.periodic(const Duration(milliseconds: 160), (_) {
      final next = _snapshot.position - const Duration(milliseconds: 1400);
      unawaited(seek(next.isNegative ? Duration.zero : next));
    });
  }

  void endRewind() {
    _rewindTimer?.cancel();
    _rewindTimer = null;
  }

  Future<void> _loadAndPlay(
    Track track, {
    BackendRepository? backend,
    Object? activePlaylistId = _activePlaylistSentinel,
  }) async {
    final generation = ++_loadGeneration;
    _snapshot = _snapshot.copyWith(
      currentTrack: track,
      isPlaying: false,
      isBuffering: true,
      position: Duration.zero,
      duration: _durationFor(track),
      queue: _queue.queue,
      activePlaylistId: activePlaylistId == _activePlaylistSentinel
          ? _snapshot.activePlaylistId
          : activePlaylistId as String?,
      error: null,
    );
    notifyListeners();
    _scheduleRemoteControlsRefresh();
    try {
      await endFastForward();
      endRewind();
      await _player.pause();
      if (_isStaleLoad(generation)) {
        return;
      }
      await _player.stop();
      if (_isStaleLoad(generation)) {
        return;
      }
      final source = await _audioSourceFor(track, backend: backend);
      if (_isStaleLoad(generation)) {
        return;
      }
      if (source == null) {
        _setPlaybackError(
          track,
          backend == null
              ? 'Online Library is offline. Download this track or reconnect to play it.'
              : 'Track is unavailable.',
        );
        return;
      }
      _snapshot = _snapshot.copyWith(queue: _queue.queue);
      notifyListeners();
      await _player.setAudioSource(source);
      if (_isStaleLoad(generation)) {
        return;
      }
      await _player.play();
      if (_isStaleLoad(generation)) {
        return;
      }
      await _tracks.recordPlayed(track);
      await _trimRecentlyPlayed();
    } on ApiException catch (error) {
      _setPlaybackError(track, error.message, generation: generation);
    } on PlayerInterruptedException {
      if (!_isStaleLoad(generation)) {
        _setPlaybackError(
          track,
          'Playback was interrupted.',
          generation: generation,
        );
      }
    } on PlayerException {
      _setPlaybackError(
        track,
        'Could not start audio playback. Try again.',
        generation: generation,
      );
    } catch (_) {
      _setPlaybackError(
        track,
        'Could not play this track. Try again.',
        generation: generation,
      );
    }
  }

  Future<void> _handleCompleted() async {
    if (_handlingCompletion) {
      return;
    }
    _handlingCompletion = true;
    try {
      switch (_snapshot.mode) {
        case PlaybackMode.repeatOne:
          await _player.seek(Duration.zero);
          await _player.play();
        case PlaybackMode.shuffle:
          final nextTrack = _queue.next();
          if (nextTrack != null) {
            await _loadAndPlay(nextTrack, backend: _lastBackend);
          }
        case PlaybackMode.repeatAll:
          final nextTrack = _queue.next(wrap: true);
          if (nextTrack != null) {
            await _loadAndPlay(nextTrack, backend: _lastBackend);
          }
        case PlaybackMode.normal:
          final nextTrack = _queue.next();
          if (nextTrack != null) {
            await _loadAndPlay(nextTrack, backend: _lastBackend);
          } else {
            _snapshot = _snapshot.copyWith(isPlaying: false);
            notifyListeners();
          }
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  void _setPlaybackError(Track track, String message, {int? generation}) {
    if (generation != null && _isStaleLoad(generation)) {
      return;
    }
    _loadGeneration++;
    unawaited(_player.stop());
    _snapshot = _snapshot.copyWith(
      currentTrack: track,
      isPlaying: false,
      isBuffering: false,
      queue: _queue.queue,
      error: message,
    );
    notifyListeners();
    _scheduleRemoteControlsRefresh();
  }

  bool _isStaleLoad(int generation) => generation != _loadGeneration;

  Future<void> _trimRecentlyPlayed() {
    return _tracks.trimRecentlyPlayed(limit: _recentHistoryLimit);
  }

  Duration _durationFor(Track? track) {
    final seconds = track?.durationSeconds;
    if (seconds == null || seconds <= 0) {
      return Duration.zero;
    }
    return Duration(seconds: seconds);
  }

  Future<AudioSource?> _audioSourceFor(
    Track track, {
    required BackendRepository? backend,
  }) async {
    final mediaItem = _mediaItem(track);
    final localPath = track.localPath;
    if (localPath != null &&
        localPath.isNotEmpty &&
        await File(localPath).exists()) {
      return AudioSource.uri(Uri.file(localPath), tag: mediaItem);
    }
    final resultId = track.resultId;
    if (resultId != null && backend != null) {
      return BackendStreamAudioSource(
        backend: backend,
        resultId: resultId,
        tag: mediaItem,
      );
    }
    return null;
  }

  MediaItem _mediaItem(Track track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.displayArtist,
      album: track.album,
      duration: track.durationSeconds == null
          ? null
          : Duration(seconds: track.durationSeconds!),
      artUri: _artUri(track),
      extras: {
        if (track.resultId != null) 'result_id': track.resultId,
        if (track.sourceId != null) 'source_id': track.sourceId,
      },
    );
  }

  Uri? _artUri(Track track) {
    if (track.localCoverPath != null) {
      return Uri.file(track.localCoverPath!);
    }
    if (track.coverUrl != null) {
      return Uri.tryParse(track.coverUrl!);
    }
    return null;
  }

  void _scheduleRemoteControlsRefresh() {
    if (!Platform.isIOS) {
      return;
    }
    _remoteControlsTimer?.cancel();
    unawaited(_configureRemoteControls());
    _remoteControlsTimer = Timer(
      const Duration(milliseconds: 160),
      _configureRemoteControls,
    );
  }

  Future<void> _configureRemoteControls() async {
    if (!Platform.isIOS || isDisposed) {
      return;
    }
    try {
      await _remoteControlsChannel.invokeMethod<void>('configure');
    } catch (_) {
      // The native side is iOS-only and may be unavailable in tests.
    }
  }

  Future<dynamic> _handleRemoteCommand(MethodCall call) async {
    switch (call.method) {
      case 'next':
        await next(backend: _lastBackend);
      case 'previous':
        await restartOrPrevious(backend: _lastBackend);
      case 'seekForwardBegin':
        await beginFastForward();
      case 'seekForwardEnd':
        await endFastForward();
      case 'seekBackwardBegin':
        beginRewind();
      case 'seekBackwardEnd':
        endRewind();
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Unknown remote command ${call.method}',
        );
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    if (Platform.isIOS) {
      _remoteControlsChannel.setMethodCallHandler(null);
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _rewindTimer?.cancel();
    _remoteControlsTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}

const _activePlaylistSentinel = Object();
