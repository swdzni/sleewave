import '../../models/track.dart';
import '../../utils/safe_change_notifier.dart';

class QueueService extends SafeChangeNotifier {
  List<Track> _queue = const [];
  int _index = 0;

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

  Track? next() {
    if (!canGoNext) {
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
}
