import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/track.dart';
import 'package:sleewave/core/services/playback/queue_service.dart';

void main() {
  test('wraps to the start when repeat queue is active', () {
    final queue = QueueService()
      ..setQueue([_track('one'), _track('two')], startIndex: 1);

    final next = queue.next(wrap: true);

    expect(next?.id, 'one');
    expect(queue.index, 0);
  });

  test('shuffle chooses another track when possible', () {
    final queue = QueueService()
      ..setQueue([_track('one'), _track('two')], startIndex: 0);

    final next = queue.next(shuffle: true);

    expect(next?.id, 'two');
    expect(queue.index, 1);
  });

  test('shuffle changes visible queue while keeping current first', () {
    final queue = QueueService()
      ..setQueue([
        _track('one'),
        _track('two'),
        _track('three'),
      ], startIndex: 1);

    queue.shuffleKeepingCurrent();

    expect(queue.current?.id, 'two');
    expect(queue.index, 0);
    expect(queue.queue.map((track) => track.id).toSet(), {
      'one',
      'two',
      'three',
    });
  });

  test('reorders queue and keeps current track selected', () {
    final queue = QueueService()
      ..setQueue([
        _track('one'),
        _track('two'),
        _track('three'),
      ], startIndex: 1);

    queue.reorder(1, 3);

    expect(queue.queue.map((track) => track.id), ['one', 'three', 'two']);
    expect(queue.current?.id, 'two');
  });
}

Track _track(String id) {
  final now = DateTime(2026);
  return Track(id: id, title: id, createdAt: now, updatedAt: now);
}
