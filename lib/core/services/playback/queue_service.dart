import 'dart:math';

import '../../models/track.dart';
import '../../utils/safe_change_notifier.dart';

class QueueService extends SafeChangeNotifier {
  List<Track> _queue = const [];
  int _index = 0;
  final _random = Random();

  List<Track> get queue => _queue;
  int get index => _index;
  Track? get current => _queue.isEmpty || _index < 0 || _index >= _queue.length
      ? null
      : _queue[_index];
  bool get canGoNext => _index < _queue.length - 1;
  bool get canGoPrevious => _index > 0;

  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    _queue = List.unmodifiable(tracks);
    _index = startIndex.clamp(0, tracks.isEmpty ? 0 : tracks.length - 1);
    notifyListeners();
  }

  void setSingle(Track track) {
    setQueue([track]);
  }

  Track? next({bool wrap = false, bool shuffle = false}) {
    if (shuffle && _queue.length > 1) {
      var nextIndex = _random.nextInt(_queue.length);
      if (nextIndex == _index) {
        nextIndex = (nextIndex + 1) % _queue.length;
      }
      _index = nextIndex;
      notifyListeners();
      return current;
    }
    if (!canGoNext) {
      if (wrap && _queue.isNotEmpty) {
        _index = 0;
        notifyListeners();
        return current;
      }
      return null;
    }
    _index += 1;
    notifyListeners();
    return current;
  }

  Track? previous() {
    if (!canGoPrevious) {
      return null;
    }
    _index -= 1;
    notifyListeners();
    return current;
  }

  void jumpTo(int index) {
    if (index < 0 || index >= _queue.length) {
      return;
    }
    _index = index;
    notifyListeners();
  }

  void shuffleKeepingCurrent() {
    if (_queue.length < 2) {
      return;
    }
    final currentTrack = current;
    if (currentTrack == null) {
      return;
    }
    final rest = [
      for (var index = 0; index < _queue.length; index++)
        if (index != _index) _queue[index],
    ]..shuffle(_random);
    _queue = List.unmodifiable([currentTrack, ...rest]);
    _index = 0;
    notifyListeners();
  }

  void removeAt(int index) {
    if (index == _index || index < 0 || index >= _queue.length) {
      return;
    }
    final next = [..._queue]..removeAt(index);
    _queue = List.unmodifiable(next);
    if (index < _index) {
      _index -= 1;
    }
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) {
      return;
    }
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 || targetIndex >= _queue.length) {
      return;
    }
    final next = [..._queue];
    final moved = next.removeAt(oldIndex);
    next.insert(targetIndex, moved);
    _queue = List.unmodifiable(next);
    if (_index == oldIndex) {
      _index = targetIndex;
    } else if (oldIndex < _index && targetIndex >= _index) {
      _index -= 1;
    } else if (oldIndex > _index && targetIndex <= _index) {
      _index += 1;
    }
    notifyListeners();
  }
}
