import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../models/playback_models.dart';
import '../../models/track.dart';
import '../../repositories/backend_repository.dart';
import '../../repositories/track_repository.dart';
import '../../utils/safe_change_notifier.dart';
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

  PlaybackSnapshot get snapshot => _snapshot;

  Future<void> playTrack(
    Track track, {
    BackendRepository? backend,
    List<Track>? queue,
  }) async {
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
    final nextTrack = _queue.next();
    if (nextTrack == null) {
      return false;
    }
    await _loadAndPlay(nextTrack, backend: backend);
    return true;
  }

  Future<bool> previous({BackendRepository? backend}) async {
    final previousTrack = _queue.previous();
    if (previousTrack == null) {
      return false;
    }
    await _loadAndPlay(previousTrack, backend: backend);
    return true;
  }

  Future<void> cycleMode() async {
    final mode = _snapshot.mode.next;
    switch (mode) {
      case PlaybackMode.normal:
        await _player.setShuffleModeEnabled(false);
        await _player.setLoopMode(LoopMode.off);
      case PlaybackMode.shuffle:
        await _player.setShuffleModeEnabled(true);
        await _player.setLoopMode(LoopMode.off);
      case PlaybackMode.repeatAll:
        await _player.setShuffleModeEnabled(false);
        await _player.setLoopMode(LoopMode.all);
      case PlaybackMode.repeatOne:
        await _player.setShuffleModeEnabled(false);
        await _player.setLoopMode(LoopMode.one);
    }
    _snapshot = _snapshot.copyWith(mode: mode);
    notifyListeners();
  }

  Future<void> _loadAndPlay(Track track, {BackendRepository? backend}) async {
    final uri = await _resolveUri(track, backend);
    if (uri == null) {
      throw StateError('Track is unavailable.');
    }
    final mediaItem = MediaItem(
      id: track.resultId ?? track.id,
      title: track.title,
      artist: track.displayArtist,
      album: track.album,
      duration: track.durationSeconds == null
          ? null
          : Duration(seconds: track.durationSeconds!),
      artUri: _artUri(track),
    );
    _snapshot = _snapshot.copyWith(
      currentTrack: track,
      isBuffering: true,
      queue: _queue.queue,
    );
    notifyListeners();
    await _player.setAudioSource(AudioSource.uri(uri, tag: mediaItem));
    await _player.play();
    await _tracks.recordPlayed(track);
  }

  Future<Uri?> _resolveUri(Track track, BackendRepository? backend) async {
    final localPath = track.localPath;
    if (localPath != null &&
        localPath.isNotEmpty &&
        await File(localPath).exists()) {
      return Uri.file(localPath);
    }
    final resultId = track.resultId;
    if (resultId != null && backend != null) {
      return backend.getStreamUrl(resultId);
    }
    return null;
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
