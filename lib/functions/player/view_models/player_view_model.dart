import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/track.dart';
import '../../../core/providers.dart';
import '../../../core/services/playback/playback_service.dart';
import '../../../core/utils/safe_change_notifier.dart';
import '../models/player_state.dart';

class PlayerViewModel extends SafeChangeNotifier {
  PlayerViewModel(this._playback, this._ref) {
    _playback.addListener(_sync);
    _sync();
  }

  final PlaybackService _playback;
  final Ref _ref;
  PlayerState _state = const PlayerState();

  PlayerState get state => _state;

  Future<void> play(
    Track track, {
    List<Track>? queue,
    String? activePlaylistId,
  }) async {
    final settings = _ref.read(themeControllerProvider).settings;
    await _playback.playTrack(
      track,
      backend: _ref.read(backendRepositoryProvider),
      queue: queue,
      activePlaylistId: activePlaylistId,
      recentHistoryLimit: settings.recentHistoryLimit,
      directUrlSourceIds: settings.directUrlSourceIds,
    );
  }

  Future<void> togglePlayPause() => _playback.togglePlayPause();
  Future<void> stop() => _playback.stop();
  Future<void> seek(Duration position) => _playback.seek(position);
  Future<void> restartOrPrevious() => _playback.restartOrPrevious(
    backend: _ref.read(backendRepositoryProvider),
  );
  Future<bool> next() =>
      _playback.next(backend: _ref.read(backendRepositoryProvider));
  Future<bool> previous() =>
      _playback.previous(backend: _ref.read(backendRepositoryProvider));
  void beginFastForward() => _playback.beginFastForward();
  void endFastForward() => _playback.endFastForward();
  void beginRewind() => _playback.beginRewind();
  void endRewind() => _playback.endRewind();
  Future<void> jumpToQueueIndex(int index) => _playback.jumpToQueueIndex(
    index,
    backend: _ref.read(backendRepositoryProvider),
  );
  Future<void> reorderQueue(int oldIndex, int newIndex) =>
      _playback.reorderQueue(oldIndex, newIndex);
  Future<void> rebuildPreparedQueue() => _playback.rebuildPreparedQueue();
  Future<void> cycleMode() => _playback.cycleMode();
  void replaceCurrentTrack(Track track) => _playback.replaceCurrentTrack(track);

  void _sync() {
    _state = PlayerState(snapshot: _playback.snapshot);
    notifyListeners();
  }

  @override
  void dispose() {
    _playback.removeListener(_sync);
    super.dispose();
  }
}

final playerViewModelProvider = ChangeNotifierProvider<PlayerViewModel>((ref) {
  return PlayerViewModel(ref.read(playbackServiceProvider), ref);
});
