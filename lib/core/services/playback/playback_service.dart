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
import 'audio_player_engine.dart';
import 'queue_service.dart';

class PlaybackService extends SafeChangeNotifier {
  PlaybackService(
    this._tracks,
    this._queue, {
    this.onTrackRecorded,
    AudioPlayerEngine? engine,
  }) : _player = engine ?? JustAudioPlayerEngine() {
    if (Platform.isIOS) {
      _remoteControlsChannel.setMethodCallHandler(_handleRemoteCommand);
      _scheduleRemoteControlsRefresh();
    }
    _subscriptions.add(
      _player.playerStateStream.listen(_handlePlayerStateChanged),
    );
    _subscriptions.add(
      _player.positionStream.listen((position) {
        if (_player.processingState != ProcessingState.ready) {
          return;
        }
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
    _subscriptions.add(
      _player.currentIndexStream.listen(_handleCurrentIndexChanged),
    );
    _subscriptions.add(_player.errorStream.listen(_handlePlayerError));
  }

  final TrackRepository _tracks;
  final QueueService _queue;
  final FutureOr<void> Function(Track track)? onTrackRecorded;
  final AudioPlayerEngine _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  PlaybackSnapshot _snapshot = const PlaybackSnapshot();
  BackendRepository? _lastBackend;
  int _recentHistoryLimit = AppConstants.defaultRecentHistoryLimit;
  Set<String> _directUrlSourceIds = const {};
  bool _handlingCompletion = false;
  Timer? _rewindTimer;
  Timer? _remoteControlsTimer;
  bool _fastForwarding = false;
  bool _handlingPlayerError = false;
  int _loadGeneration = 0;
  bool _playlistPrepared = false;
  List<int> _sourceQueueIndices = const [];
  final Set<String> _failedTrackIds = {};
  final Set<String> _directFallbackTrackIds = {};
  String? _lastRecordedTrackId;

  static const _restartThreshold = Duration(seconds: 3);
  static const _remoteControlsChannel = MethodChannel(
    'sleewave/remote_controls',
  );

  PlaybackSnapshot get snapshot => _snapshot;

  void _handlePlayerStateChanged(PlayerState state) {
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
  }

  Future<void> playTrack(
    Track track, {
    BackendRepository? backend,
    List<Track>? queue,
    String? activePlaylistId,
    required int recentHistoryLimit,
    required List<String> directUrlSourceIds,
  }) async {
    _lastBackend = backend;
    _recentHistoryLimit = recentHistoryLimit;
    _directUrlSourceIds = directUrlSourceIds.toSet();
    _failedTrackIds.clear();
    _directFallbackTrackIds.clear();
    _lastRecordedTrackId = null;
    _playlistPrepared = false;
    _sourceQueueIndices = const [];
    if (queue != null && queue.isNotEmpty) {
      final startIndex = queue.indexWhere((item) => item.id == track.id);
      _queue.setQueue(
        startIndex == -1 ? [...queue, track] : queue,
        startIndex: startIndex == -1 ? queue.length : startIndex,
      );
    } else {
      _queue.setSingle(track);
    }
    await _prepareAndStartQueue(
      backend: backend,
      activePlaylistId: activePlaylistId,
    );
  }

  Future<void> jumpToQueueIndex(int index, {BackendRepository? backend}) async {
    _lastBackend = backend ?? _lastBackend;
    if (index < 0 || index >= _queue.queue.length) {
      return;
    }
    _failedTrackIds.remove(_queue.queue[index].id);
    final resolvedIndex = _nearestPlayableIndex(
      index,
      backend: backend ?? _lastBackend,
    );
    if (resolvedIndex == null) {
      _setNonStoppingPlaybackError('No playable tracks in queue.');
      return;
    }
    await _jumpToResolvedIndex(resolvedIndex, backend: backend ?? _lastBackend);
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    final resolvedNewIndex = _queue.reorder(oldIndex, newIndex);
    if (resolvedNewIndex == null) {
      return;
    }
    _snapshot = _snapshot.copyWith(queue: _queue.queue);
    notifyListeners();
    await _prepareAndStartQueue(
      backend: _lastBackend,
      initialPosition: _snapshot.position,
      playAfterLoad: _player.playing,
    );
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
    _playlistPrepared = false;
    _sourceQueueIndices = const [];
    await _player.stop();
    _snapshot = _snapshot.copyWith(
      isPlaying: false,
      isBuffering: false,
      position: Duration.zero,
    );
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
    final nextIndex = _nextPlayableIndex(
      backend: backend ?? _lastBackend,
      wrap: _snapshot.mode == PlaybackMode.repeatAll,
      shuffle: _snapshot.mode == PlaybackMode.shuffle,
    );
    if (nextIndex == null) {
      _setNonStoppingPlaybackError('No playable next track.');
      return false;
    }
    await _jumpToResolvedIndex(nextIndex, backend: backend ?? _lastBackend);
    return true;
  }

  Future<bool> previous({BackendRepository? backend}) async {
    _lastBackend = backend ?? _lastBackend;
    final previousIndex = _previousPlayableIndex(
      backend: backend ?? _lastBackend,
    );
    if (previousIndex == null) {
      _setNonStoppingPlaybackError('No playable previous track.');
      return false;
    }
    await _jumpToResolvedIndex(previousIndex, backend: backend ?? _lastBackend);
    return true;
  }

  Future<void> cycleMode() async {
    final mode = _snapshot.mode.next;
    if (mode == PlaybackMode.shuffle) {
      _queue.shuffleKeepingCurrent();
      _snapshot = _snapshot.copyWith(mode: mode, queue: _queue.queue);
      notifyListeners();
      await _prepareAndStartQueue(
        backend: _lastBackend,
        initialPosition: _snapshot.position,
        playAfterLoad: _player.playing,
      );
      return;
    }
    _snapshot = _snapshot.copyWith(mode: mode, queue: _queue.queue);
    notifyListeners();
    await _configureNativePlaybackMode(mode);
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

  Future<void> _prepareAndStartQueue({
    BackendRepository? backend,
    Object? activePlaylistId = _activePlaylistSentinel,
    bool allowDirectUrl = true,
    Duration initialPosition = Duration.zero,
    bool playAfterLoad = true,
  }) async {
    final track = _queue.current;
    if (track == null) {
      _setNonStoppingPlaybackError('No playable tracks in queue.');
      return;
    }
    final generation = ++_loadGeneration;
    _snapshot = _snapshot.copyWith(
      currentTrack: track,
      isPlaying: false,
      isBuffering: true,
      position: initialPosition,
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
      final prepared = await _prepareQueueSources(
        backend: backend,
        allowDirectUrl: allowDirectUrl,
      );
      if (_isStaleLoad(generation)) {
        return;
      }
      if (prepared.sources.isEmpty) {
        _setPlaybackError(
          track,
          backend == null
              ? 'Online Library is offline. Download this track or reconnect to play it.'
              : 'Track is unavailable.',
        );
        return;
      }
      final startSourceIndex = prepared.queueIndices.indexOf(_queue.index);
      if (startSourceIndex == -1) {
        _setNonStoppingPlaybackError(
          _sourceUnavailableMessage(track, backend: backend),
        );
        return;
      }
      _sourceQueueIndices = prepared.queueIndices;
      _playlistPrepared = true;
      _snapshot = _snapshot.copyWith(queue: _queue.queue);
      notifyListeners();
      await _player.setAudioSources(
        prepared.sources,
        initialIndex: startSourceIndex,
        initialPosition: initialPosition,
      );
      if (_isStaleLoad(generation)) {
        return;
      }
      await _configureNativePlaybackMode(_snapshot.mode);
      if (_isStaleLoad(generation)) {
        return;
      }
      if (playAfterLoad) {
        await _player.play();
      }
      if (_isStaleLoad(generation)) {
        return;
      }
      if (playAfterLoad) {
        await _recordStartedTrack(track);
      }
    } on ApiException catch (error) {
      await _skipFailedTrack(track, error.message, generation: generation);
    } on PlayerInterruptedException {
      if (!_isStaleLoad(generation)) {
        _setPlaybackError(
          track,
          'Playback was interrupted.',
          generation: generation,
        );
      }
    } on PlayerException catch (error) {
      if (allowDirectUrl && _canFallbackFromDirectUrl(track, backend)) {
        _directFallbackTrackIds.add(track.id);
        await _prepareAndStartQueue(
          backend: backend,
          activePlaylistId: activePlaylistId,
          initialPosition: initialPosition,
          playAfterLoad: playAfterLoad,
        );
        return;
      }
      await _skipFailedTrack(
        track,
        _messageForPlayerException(error, track),
        generation: generation,
      );
    } catch (error) {
      await _skipFailedTrack(
        track,
        _messageForUnexpectedError(error, track),
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
      if (_snapshot.mode == PlaybackMode.repeatOne) {
        await _player.seek(Duration.zero);
        await _player.play();
        return;
      }
      _snapshot = _snapshot.copyWith(isPlaying: false, isBuffering: false);
      notifyListeners();
    } on PlayerException {
      final track = _snapshot.currentTrack;
      if (track != null) {
        _setPlaybackError(track, 'Could not start next track.');
      }
    } on PlayerInterruptedException {
      // A newer play/skip request took over.
    } finally {
      _handlingCompletion = false;
    }
  }

  void _setPlaybackError(Track track, String message, {int? generation}) {
    if (generation != null && _isStaleLoad(generation)) {
      return;
    }
    _loadGeneration++;
    _playlistPrepared = false;
    _sourceQueueIndices = const [];
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

  void _setNonStoppingPlaybackError(String message) {
    _snapshot = _snapshot.copyWith(
      isBuffering: false,
      queue: _queue.queue,
      error: message,
    );
    notifyListeners();
  }

  bool _isStaleLoad(int generation) => generation != _loadGeneration;

  Future<void> _handleCurrentIndexChanged(int? sourceIndex) async {
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= _sourceQueueIndices.length) {
      return;
    }
    final queueIndex = _sourceQueueIndices[sourceIndex];
    if (queueIndex < 0 || queueIndex >= _queue.queue.length) {
      return;
    }
    if (_queue.index != queueIndex) {
      _queue.jumpTo(queueIndex);
    }
    final track = _queue.current;
    if (track == null || _snapshot.currentTrack?.id == track.id) {
      return;
    }
    _snapshot = _snapshot.copyWith(
      currentTrack: track,
      isBuffering:
          _player.processingState == ProcessingState.loading ||
          _player.processingState == ProcessingState.buffering,
      position: _player.position,
      duration: _player.duration ?? _durationFor(track),
      queue: _queue.queue,
      error: null,
    );
    notifyListeners();
    _scheduleRemoteControlsRefresh();
    if (_player.playing) {
      await _recordStartedTrack(track);
    }
  }

  Future<void> _handlePlayerError(PlayerException error) async {
    if (_handlingPlayerError || isDisposed) {
      return;
    }
    _handlingPlayerError = true;
    try {
      final sourceIndex = error.index ?? _player.currentIndex;
      final queueIndex =
          sourceIndex == null ||
              sourceIndex < 0 ||
              sourceIndex >= _sourceQueueIndices.length
          ? _queue.index
          : _sourceQueueIndices[sourceIndex];
      if (queueIndex >= 0 && queueIndex < _queue.queue.length) {
        _queue.jumpTo(queueIndex);
      }
      final track = _queue.current ?? _snapshot.currentTrack;
      if (track == null) {
        _setNonStoppingPlaybackError(
          'Audio source failed: ${_messageForPlayerException(error)}',
        );
        return;
      }
      if (_canFallbackFromDirectUrl(track, _lastBackend) &&
          _directFallbackTrackIds.add(track.id)) {
        await _prepareAndStartQueue(
          backend: _lastBackend,
          initialPosition: _snapshot.position,
          playAfterLoad: true,
        );
        return;
      }
      await _skipFailedTrack(track, _messageForPlayerException(error, track));
    } finally {
      _handlingPlayerError = false;
    }
  }

  Future<void> _trimRecentlyPlayed() {
    return _tracks.trimRecentlyPlayed(limit: _recentHistoryLimit);
  }

  Future<void> _notifyTrackRecorded(Track track) async {
    final callback = onTrackRecorded;
    if (callback == null) {
      return;
    }
    try {
      await callback(track);
    } catch (_) {
      // Recent playback should never interrupt an already-started track.
    }
  }

  Duration _durationFor(Track? track) {
    final seconds = track?.durationSeconds;
    if (seconds == null || seconds <= 0) {
      return Duration.zero;
    }
    return Duration(seconds: seconds);
  }

  Future<void> _recordStartedTrack(Track track) async {
    if (_lastRecordedTrackId == track.id) {
      return;
    }
    _lastRecordedTrackId = track.id;
    await _tracks.recordPlayed(track);
    await _trimRecentlyPlayed();
    await _notifyTrackRecorded(track);
  }

  Future<_PreparedQueueSources> _prepareQueueSources({
    required BackendRepository? backend,
    required bool allowDirectUrl,
  }) async {
    final sources = <AudioSource>[];
    final queueIndices = <int>[];
    final queue = _queue.queue;
    for (var index = 0; index < queue.length; index++) {
      final track = queue[index];
      if (_failedTrackIds.contains(track.id)) {
        continue;
      }
      final source = await _audioSourceFor(
        track,
        backend: backend,
        allowDirectUrl: allowDirectUrl,
      );
      if (source == null) {
        continue;
      }
      sources.add(source);
      queueIndices.add(index);
    }
    return _PreparedQueueSources(sources: sources, queueIndices: queueIndices);
  }

  Future<AudioSource?> _audioSourceFor(
    Track track, {
    required BackendRepository? backend,
    required bool allowDirectUrl,
  }) async {
    final mediaItem = _mediaItem(track);
    final localPath = track.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      return AudioSource.uri(Uri.file(localPath), tag: mediaItem);
    }
    final resultId = track.resultId;
    if (resultId != null && backend != null) {
      return AudioSource.uri(
        backend.streamUri(
          resultId,
          directUrl: _shouldUseDirectUrl(track, allowDirectUrl: allowDirectUrl),
        ),
        tag: mediaItem,
      );
    }
    return null;
  }

  bool _canFallbackFromDirectUrl(Track track, BackendRepository? backend) {
    return _shouldUseDirectUrl(track, allowDirectUrl: true) &&
        backend != null &&
        track.resultId != null;
  }

  bool _shouldUseDirectUrl(Track track, {required bool allowDirectUrl}) {
    if (!allowDirectUrl) {
      return false;
    }
    if (_directFallbackTrackIds.contains(track.id)) {
      return false;
    }
    final sourceId = track.sourceId;
    return sourceId != null && _directUrlSourceIds.contains(sourceId);
  }

  Future<bool> isTrackPlayable(
    Track track, {
    BackendRepository? backend,
  }) async {
    final source = await _audioSourceFor(
      track,
      backend: backend ?? _lastBackend,
      allowDirectUrl: true,
    );
    return source != null;
  }

  int? _nextPlayableIndex({
    required BackendRepository? backend,
    bool wrap = false,
    bool shuffle = false,
  }) {
    return _queue.nextPlayableIndex(
      isPlayable: (track) => _isProbablyPlayable(track, backend: backend),
      wrap: wrap,
      shuffle: shuffle,
    );
  }

  int? _previousPlayableIndex({required BackendRepository? backend}) {
    return _queue.previousPlayableIndex(
      isPlayable: (track) => _isProbablyPlayable(track, backend: backend),
    );
  }

  int? _nearestPlayableIndex(int index, {required BackendRepository? backend}) {
    return _queue.nearestPlayableIndexFrom(
      index,
      isPlayable: (track) => _isProbablyPlayable(track, backend: backend),
    );
  }

  bool _isProbablyPlayable(Track track, {required BackendRepository? backend}) {
    if (_failedTrackIds.contains(track.id)) {
      return false;
    }
    final localPath = track.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      return true;
    }
    return track.resultId != null && backend != null;
  }

  Future<void> _jumpToResolvedIndex(
    int index, {
    required BackendRepository? backend,
  }) async {
    _lastBackend = backend ?? _lastBackend;
    _queue.jumpTo(index);
    final track = _queue.current;
    if (track == null) {
      return;
    }
    final sourceIndex = _sourceIndexForQueueIndex(index);
    if (!_playlistPrepared ||
        sourceIndex == null ||
        _player.processingState == ProcessingState.loading) {
      await _prepareAndStartQueue(backend: backend ?? _lastBackend);
      return;
    }
    _snapshot = _snapshot.copyWith(
      currentTrack: track,
      isBuffering: true,
      position: Duration.zero,
      duration: _durationFor(track),
      queue: _queue.queue,
      error: null,
    );
    notifyListeners();
    _scheduleRemoteControlsRefresh();
    await _player.seek(Duration.zero, index: sourceIndex);
    await _player.play();
    await _recordStartedTrack(track);
  }

  Future<void> _skipFailedTrack(
    Track track,
    String message, {
    int? generation,
  }) async {
    if (generation != null && _isStaleLoad(generation)) {
      return;
    }
    _failedTrackIds.add(track.id);
    final skippedMessage = 'Skipped "${track.title}": $message';
    _snapshot = _snapshot.copyWith(
      currentTrack: track,
      isPlaying: false,
      isBuffering: false,
      queue: _queue.queue,
      error: skippedMessage,
    );
    notifyListeners();
    _scheduleRemoteControlsRefresh();
    final nextIndex = _nextPlayableIndex(
      backend: _lastBackend,
      wrap: _snapshot.mode == PlaybackMode.repeatAll,
      shuffle: _snapshot.mode == PlaybackMode.shuffle,
    );
    if (nextIndex == null) {
      _setPlaybackError(track, 'No playable tracks left. $message');
      return;
    }
    _queue.jumpTo(nextIndex);
    await _prepareAndStartQueue(backend: _lastBackend);
  }

  int? _sourceIndexForQueueIndex(int queueIndex) {
    final sourceIndex = _sourceQueueIndices.indexOf(queueIndex);
    return sourceIndex == -1 ? null : sourceIndex;
  }

  Future<void> _configureNativePlaybackMode(PlaybackMode mode) async {
    await _player.setShuffleModeEnabled(false);
    final loopMode = switch (mode) {
      PlaybackMode.repeatOne => LoopMode.one,
      PlaybackMode.repeatAll => LoopMode.all,
      PlaybackMode.normal || PlaybackMode.shuffle => LoopMode.off,
    };
    await _player.setLoopMode(loopMode);
  }

  String _sourceUnavailableMessage(
    Track track, {
    required BackendRepository? backend,
  }) {
    if (track.isLocalPlayable) {
      return 'The local file is missing.';
    }
    if (track.resultId == null) {
      return 'This track has no playable Online Library ID.';
    }
    if (backend == null) {
      return 'Online Library is offline.';
    }
    return 'Track is unavailable.';
  }

  String _messageForPlayerException(PlayerException error, [Track? track]) {
    final raw = error.message?.trim();
    if (raw != null && raw.isNotEmpty) {
      final lower = raw.toLowerCase();
      if (lower.contains('404') ||
          lower.contains('not found') ||
          lower.contains('source error')) {
        return 'Track source was not found.';
      }
      if (lower.contains('timeout')) {
        return 'Track source timed out.';
      }
      if (lower.contains('format') ||
          lower.contains('decoder') ||
          lower.contains('unsupported')) {
        return 'Audio format is not supported.';
      }
      if (lower.contains('network') ||
          lower.contains('connection') ||
          lower.contains('host')) {
        return 'Network connection failed.';
      }
      return raw;
    }
    if (track?.isLocalPlayable == true) {
      return 'The local file could not be opened.';
    }
    return 'Track source could not be loaded.';
  }

  String _messageForUnexpectedError(Object error, Track track) {
    if (error is FileSystemException) {
      return 'The local file is missing or unreadable.';
    }
    if (error is FormatException) {
      return 'Track link is not valid.';
    }
    final message = '$error'.trim();
    if (message.isEmpty || message == 'Exception') {
      return _sourceUnavailableMessage(track, backend: _lastBackend);
    }
    return message;
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

class _PreparedQueueSources {
  const _PreparedQueueSources({
    required this.sources,
    required this.queueIndices,
  });

  final List<AudioSource> sources;
  final List<int> queueIndices;
}
