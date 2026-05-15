import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/constants/app_constants.dart';
import 'package:sleewave/core/database/app_database.dart';
import 'package:sleewave/core/models/track.dart';
import 'package:sleewave/core/repositories/track_repository.dart';

void main() {
  late AppDatabase db;
  late TrackRepository tracks;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('merges duplicate keyed tracks without throwing', () async {
    final now = DateTime(2026);
    await tracks.upsert(
      Track(
        id: 'remote-copy',
        title: 'Same Track',
        artist: 'Same Artist',
        durationSeconds: 200,
        trackKey: 'same-key',
        localOrigin: AppConstants.localOriginRemoteOnly,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tracks.upsert(
      Track(
        id: 'local-copy',
        title: 'Same Track',
        artist: 'Same Artist',
        durationSeconds: 202,
        trackKey: 'same-key',
        localPath: '/tmp/same.mp3',
        localOrigin: AppConstants.localOriginDownloaded,
        createdAt: now,
        updatedAt: now.add(const Duration(seconds: 1)),
      ),
    );

    final merged = await tracks.mergeRemoteTrack(
      Track(
        id: 'incoming',
        title: 'Same Track',
        artist: 'Same Artist',
        durationSeconds: 201,
        trackKey: 'same-key',
        resultId: 'result-1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(merged.id, 'local-copy');
    expect(merged.resultId, 'result-1');
    expect(merged.localPath, '/tmp/same.mp3');
  });

  test('keeps unkeyed remote tracks as separate rows', () async {
    final now = DateTime(2026);
    final first = await tracks.mergeRemoteTrack(
      Track(
        id: 'remote-1',
        title: 'Same Title',
        artist: 'Same Artist',
        durationSeconds: 200,
        resultId: 'result-1',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final second = await tracks.mergeRemoteTrack(
      Track(
        id: 'remote-2',
        title: 'Same Title',
        artist: 'Same Artist',
        durationSeconds: 200,
        resultId: 'result-2',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(first.id, isNot(second.id));
    expect(await tracks.allTracks(), hasLength(2));
  });
}
