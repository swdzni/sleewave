import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

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
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        _snapshot = _snapshot.copyWith(
          isPlaying: state.playing,
          isBuffering:
              state.processingState == ProcessingState.buffering ||
              state.processingState == ProcessingState.loading,
        );
        notifyListeners();
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
        _snapshot = _snapshot.copyWith(duration: duration ?? Duration.zero);
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
  bool _handlingCompletion = false;

  PlaybackSnapshot get snapshot => _snapshot;

  Future<void> playTrack(
    Track track, {
    BackendRepository? backend,
    List<Track>? queue,
  }) async {
    _lastBackend = backend;
    if (queue != null && queue.isNotEmpty) {
      _queue.setQueue(
        queue,
        startIndex: queue.indexWhere((item) => item.id == track.id),
      );
    } else {
      _queue.setSingle(track);
    }
    await _loadAndPlay(track, backend: backend);
  }

  Future<void> jumpToQueueIndex(int index, {BackendRepository? backend}) async {
    _lastBackend = backend ?? _lastBackend;
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
    await _player.stop();
    _snapshot = _snapshot.copyWith(isPlaying: false, isBuffering: false);
    notifyListeners();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<bool> next({BackendRepository? backend}) async {
    _lastBackend = backend ?? _lastBackend;
    final nextTrack = _queue.next(
      wrap: _snapshot.mode == PlaybackMode.repeatAll,
      shuffle: _snapshot.mode == PlaybackMode.shuffle,
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
    _snapshot = _snapshot.copyWith(mode: mode);
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

  Future<void> _loadAndPlay(Track track, {BackendRepository? backend}) async {
    _snapshot = _snapshot.copyWith(
      currentTrack: track,
      isPlaying: false,
      isBuffering: true,
      position: Duration.zero,
      duration: Duration.zero,
      queue: _queue.queue,
      error: null,
    );
    notifyListeners();
    try {
      await _player.stop();
      final mediaItem = _mediaItem(track);
      final audioSource = await _audioSourceFor(
        track,
        backend: backend,
        mediaItem: mediaItem,
      );
      if (audioSource == null) {
        _setPlaybackError(
          track,
          backend == null
              ? 'Online Library is offline. Download this track or reconnect to play it.'
              : 'Track is unavailable.',
        );
        return;
      }
      await _player.setAudioSource(audioSource);
      await _player.play();
      await _tracks.recordPlayed(track);
    } on ApiException catch (error) {
      _setPlaybackError(track, error.message);
    } on PlayerException {
      _setPlaybackError(track, 'Could not start audio playback. Try again.');
    } on PlayerInterruptedException {
      _setPlaybackError(track, 'Playback was interrupted.');
    } catch (_) {
      _setPlaybackError(track, 'Could not play this track. Try again.');
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
          final nextTrack = _queue.next(shuffle: true);
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

  void _setPlaybackError(Track track, String message) {
    _snapshot = _snapshot.copyWith(
      currentTrack: track,
      isPlaying: false,
      isBuffering: false,
      queue: _queue.queue,
      error: message,
    );
    notifyListeners();
  }

  Future<AudioSource?> _audioSourceFor(
    Track track, {
    required BackendRepository? backend,
    required MediaItem mediaItem,
  }) async {
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

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
