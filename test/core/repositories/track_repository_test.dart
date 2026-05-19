import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/constants/app_constants.dart';
import 'package:sleewave/core/database/app_database.dart';
import 'package:sleewave/core/models/track.dart';
import 'package:sleewave/core/models/track_availability.dart';
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

  test('clears recently played without deleting tracks', () async {
    final now = DateTime(2026);
    final track = await tracks.upsert(
      Track(
        id: 'played-track',
        title: 'Played Track',
        artist: 'Same Artist',
        localOrigin: AppConstants.localOriginRemoteOnly,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tracks.recordPlayed(track);
    expect(await tracks.recentTracks(), hasLength(1));
    expect((await tracks.byId(track.id))!.lastPlayedAt, isNotNull);

    await tracks.clearRecentlyPlayed();

    expect(await tracks.recentTracks(), isEmpty);
    expect(await tracks.allTracks(), hasLength(1));
    expect((await tracks.byId(track.id))!.lastPlayedAt, isNull);
  });

  test('trims recently played to the configured limit', () async {
    final now = DateTime(2026);
    final inserted = <Track>[];
    for (var index = 0; index < 4; index++) {
      inserted.add(
        await tracks.upsert(
          Track(
            id: 'played-$index',
            title: 'Played $index',
            artist: 'Same Artist',
            localOrigin: AppConstants.localOriginRemoteOnly,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    }
    for (final track in inserted) {
      await tracks.recordPlayed(track);
    }
    for (var index = 0; index < inserted.length; index++) {
      await (db.update(
        db.recentTracks,
      )..where((table) => table.trackId.equals('played-$index'))).write(
        RecentTracksCompanion(
          playedAt: Value(DateTime(2026, 1, 1, 0, 0, index)),
        ),
      );
    }

    await tracks.trimRecentlyPlayed(limit: 2);

    final recent = await tracks.recentTracks();
    expect(recent, hasLength(2));
    expect(recent.map((track) => track.id).toSet(), {'played-3', 'played-2'});
    expect((await tracks.byId('played-0'))!.lastPlayedAt, isNull);
    expect((await tracks.byId('played-1'))!.lastPlayedAt, isNull);
    expect((await tracks.byId('played-2'))!.lastPlayedAt, isNotNull);
  });

  test('marks all server cached tracks removed', () async {
    final now = DateTime(2026);
    await tracks.upsert(
      Track(
        id: 'server-only',
        title: 'Server Only',
        resultId: 'server-only',
        availability: const TrackAvailability(inServerCache: true),
        localOrigin: AppConstants.localOriginServerCached,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tracks.upsert(
      Track(
        id: 'local-copy',
        title: 'Local Copy',
        resultId: 'local-copy',
        localPath: '/tmp/local-copy.mp3',
        localOrigin: AppConstants.localOriginDownloaded,
        availability: const TrackAvailability(inServerCache: true),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tracks.markAllServerRemoved();

    expect(await tracks.byId('server-only'), isNull);
    final local = await tracks.byId('local-copy');
    expect(local, isNotNull);
    expect(local!.resultId, isNull);
    expect(local.isServerCached, isFalse);
    expect(local.localPath, '/tmp/local-copy.mp3');
  });
}
