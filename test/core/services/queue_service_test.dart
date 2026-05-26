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

  test('next playable index skips unavailable tracks', () {
    final queue = QueueService()
      ..setQueue([_track('one'), _track('two'), _track('three')]);

    final next = queue.nextPlayableIndex(
      isPlayable: (track) => track.id != 'two',
    );

    expect(next, 2);
    expect(queue.index, 0);
  });

  test('previous playable index skips unavailable tracks', () {
    final queue = QueueService()
      ..setQueue([
        _track('one'),
        _track('two'),
        _track('three'),
      ], startIndex: 2);

    final previous = queue.previousPlayableIndex(
      isPlayable: (track) => track.id != 'two',
    );

    expect(previous, 0);
    expect(queue.index, 2);
  });

  test('previous playable index wraps when repeat queue is active', () {
    final queue = QueueService()
      ..setQueue([_track('one'), _track('two'), _track('three')]);

    final previous = queue.previousPlayableIndex(
      wrap: true,
      isPlayable: (track) => track.id != 'two',
    );

    expect(previous, 2);
    expect(queue.index, 0);
  });

  test('repeat wrap skips unavailable tracks', () {
    final queue = QueueService()
      ..setQueue([
        _track('one'),
        _track('two'),
        _track('three'),
      ], startIndex: 2);

    final next = queue.nextPlayableIndex(
      wrap: true,
      isPlayable: (track) => track.id == 'two',
    );

    expect(next, 1);
    expect(queue.index, 2);
  });

  test('shuffle playable index excludes current track', () {
    final queue = QueueService()
      ..setQueue([_track('one'), _track('two')], startIndex: 0);

    final next = queue.nextPlayableIndex(
      shuffle: true,
      isPlayable: (_) => true,
    );

    expect(next, 1);
    expect(queue.index, 0);
  });

  test('nearest playable index ignores invalid jumps', () {
    final queue = QueueService()
      ..setQueue([_track('one'), _track('two')], startIndex: 0);

    final resolved = queue.nearestPlayableIndexFrom(9, isPlayable: (_) => true);

    expect(resolved, isNull);
    expect(queue.index, 0);
  });

  test('nearest playable index scans forward then backward', () {
    final queue = QueueService()
      ..setQueue([
        _track('one'),
        _track('two'),
        _track('three'),
      ], startIndex: 0);

    final resolved = queue.nearestPlayableIndexFrom(
      1,
      isPlayable: (track) => track.id == 'three',
    );

    expect(resolved, 2);
    expect(queue.index, 0);
  });
}

Track _track(String id) {
  final now = DateTime(2026);
  return Track(id: id, title: id, createdAt: now, updatedAt: now);
}
