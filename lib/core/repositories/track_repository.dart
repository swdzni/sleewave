import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../models/track.dart';
import '../models/track_availability.dart';

class TrackRepository {
  TrackRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<List<Track>> allTracks() async {
    final rows = await (_db.select(
      _db.tracks,
    )..orderBy([(table) => OrderingTerm.desc(table.updatedAt)])).get();
    return rows.map(_fromRow).toList();
  }

  Stream<List<Track>> watchAllTracks() {
    return (_db.select(_db.tracks)
          ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_fromRow).toList());
  }

  Future<List<Track>> localTracks() async {
    final rows =
        await (_db.select(_db.tracks)
              ..where((table) => table.localPath.isNotNull())
              ..orderBy([(table) => OrderingTerm.asc(table.title)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Track>> downloadedTracks() async {
    final rows =
        await (_db.select(_db.tracks)
              ..where(
                (table) =>
                    table.localPath.isNotNull() &
                    table.localOrigin.equals(
                      AppConstants.localOriginDownloaded,
                    ),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.title)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Track>> importedTracks() async {
    final rows =
        await (_db.select(_db.tracks)
              ..where(
                (table) =>
                    table.localPath.isNotNull() &
                    table.localOrigin.equals(AppConstants.localOriginImported),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.title)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Track>> recentTracks({int limit = 20}) async {
    final query =
        _db.select(_db.tracks).join([
            innerJoin(
              _db.recentTracks,
              _db.recentTracks.trackId.equalsExp(_db.tracks.id),
            ),
          ])
          ..orderBy([OrderingTerm.desc(_db.recentTracks.playedAt)])
          ..limit(limit);
    final rows = await query.get();
    return rows.map((row) => _fromRow(row.readTable(_db.tracks))).toList();
  }

  Future<List<Track>> likedTracks() async {
    final rows =
        await (_db.select(_db.tracks)
              ..where((table) => table.isLiked.equals(true))
              ..orderBy([(table) => OrderingTerm.asc(table.title)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Track>> searchLocal(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final like = '%$trimmed%';
    final rows =
        await (_db.select(_db.tracks)
              ..where(
                (table) =>
                    table.localPath.isNotNull() &
                    (table.title.like(like) |
                        table.artist.like(like) |
                        table.album.like(like)),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.title)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  Future<Track?> byId(String id) async {
    final row = await (_db.select(
      _db.tracks,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Track> upsert(Track track) async {
    final now = DateTime.now();
    final saved = track.copyWith(updatedAt: now);
    await _db.into(_db.tracks).insertOnConflictUpdate(_toCompanion(saved));
    return saved;
  }

  Future<Track> mergeRemoteTrack(Track remote) async {
    final existing = await _findByIdentity(remote);
    if (existing == null) {
      final saved = remote.copyWith(
        id: remote.id.isEmpty ? _uuid.v4() : remote.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await upsert(saved);
      return saved;
    }

    final merged = existing.copyWith(
      title: existing.title.isNotEmpty ? existing.title : remote.title,
      artist: existing.artist.isNotEmpty ? existing.artist : remote.artist,
      album: existing.album ?? remote.album,
      durationSeconds: existing.durationSeconds ?? remote.durationSeconds,
      coverUrl: existing.coverUrl ?? remote.coverUrl,
      sourceId: remote.sourceId ?? existing.sourceId,
      resultId: remote.resultId ?? existing.resultId,
      trackKey: remote.trackKey ?? existing.trackKey,
      baseTrackKey: remote.baseTrackKey ?? existing.baseTrackKey,
      availability: remote.availability.copyWith(
        onDevice: remote.availability.onDevice || existing.isDownloaded,
      ),
      localPath: existing.localPath,
      localOrigin: existing.localPath != null
          ? existing.localOrigin
          : remote.localOrigin,
      updatedAt: DateTime.now(),
    );
    await upsert(merged);
    return merged;
  }

  Future<Track> markDownloaded({
    required Track track,
    required String localPath,
  }) async {
    return upsert(
      track.copyWith(
        localPath: localPath,
        localOrigin: AppConstants.localOriginDownloaded,
        availability: track.availability.copyWith(onDevice: true),
      ),
    );
  }

  Future<Track> toggleLike(Track track) {
    return upsert(track.copyWith(isLiked: !track.isLiked));
  }

  Future<void> recordPlayed(Track track) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(
        _db.tracks,
      )..where((table) => table.id.equals(track.id))).write(
        TracksCompanion(lastPlayedAt: Value(now), updatedAt: Value(now)),
      );
      final existing = await (_db.select(
        _db.recentTracks,
      )..where((table) => table.trackId.equals(track.id))).getSingleOrNull();
      await _db
          .into(_db.recentTracks)
          .insertOnConflictUpdate(
            RecentTracksCompanion(
              trackId: Value(track.id),
              playedAt: Value(now),
              playCount: Value((existing?.playCount ?? 0) + 1),
            ),
          );
    });
  }

  Future<void> deleteLocalState(Track track) async {
    if (track.localPath != null) {
      final file = File(track.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    if (track.isImported && track.trackKey == null) {
      await (_db.delete(
        _db.playlistTracks,
      )..where((table) => table.trackId.equals(track.id))).go();
      await (_db.delete(
        _db.recentTracks,
      )..where((table) => table.trackId.equals(track.id))).go();
      await (_db.delete(
        _db.tracks,
      )..where((table) => table.id.equals(track.id))).go();
      return;
    }

    final origin = track.isServerCached
        ? AppConstants.localOriginServerCached
        : AppConstants.localOriginRemoteOnly;
    await upsert(
      track.copyWith(
        localPath: null,
        localOrigin: origin,
        availability: track.availability.copyWith(onDevice: false),
      ),
    );
  }

  Future<List<Track>> backendKeyedLocalTracks() async {
    final rows =
        await (_db.select(_db.tracks)..where(
              (table) =>
                  table.localPath.isNotNull() &
                  table.trackKey.isNotNull() &
                  table.baseTrackKey.isNotNull(),
            ))
            .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> removeMissingLocalPaths() async {
    final rows = await (_db.select(
      _db.tracks,
    )..where((table) => table.localPath.isNotNull())).get();
    for (final row in rows) {
      final path = row.localPath;
      if (path != null && !File(path).existsSync()) {
        await (_db.update(
          _db.tracks,
        )..where((table) => table.id.equals(row.id))).write(
          TracksCompanion(
            localPath: const Value(null),
            onDevice: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  Future<Track?> _findByIdentity(Track track) async {
    DbTrack? row;
    if (track.trackKey != null) {
      final rows = await (_db.select(
        _db.tracks,
      )..where((table) => table.trackKey.equals(track.trackKey!))).get();
      row = _bestIdentityMatch(rows, track);
    }
    if (row == null && track.baseTrackKey != null) {
      final rows =
          await (_db.select(_db.tracks)..where(
                (table) => table.baseTrackKey.equals(track.baseTrackKey!),
              ))
              .get();
      row = _bestIdentityMatch(rows, track);
    }
    if (row == null) {
      final title = _normalize(track.title);
      final artist = _normalize(track.artist);
      final rows = await (_db.select(
        _db.tracks,
      )..where((table) => table.localPath.isNotNull())).get();
      for (final candidate in rows) {
        final sameTitle = _normalize(candidate.title) == title;
        final sameArtist = _normalize(candidate.artist) == artist;
        final sameDuration =
            candidate.durationSeconds == null ||
            track.durationSeconds == null ||
            (candidate.durationSeconds! - track.durationSeconds!).abs() <= 5;
        if (sameTitle && sameArtist && sameDuration) {
          row = candidate;
          break;
        }
      }
    }
    return row == null ? null : _fromRow(row);
  }

  DbTrack? _bestIdentityMatch(List<DbTrack> rows, Track incoming) {
    if (rows.isEmpty) {
      return null;
    }
    final sorted = [...rows]
      ..sort((a, b) {
        final localCompare = _boolScore(
          b.localPath != null,
        ).compareTo(_boolScore(a.localPath != null));
        if (localCompare != 0) {
          return localCompare;
        }
        final durationCompare = _durationScore(
          b,
          incoming,
        ).compareTo(_durationScore(a, incoming));
        if (durationCompare != 0) {
          return durationCompare;
        }
        final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
        if (updatedCompare != 0) {
          return updatedCompare;
        }
        return a.id.compareTo(b.id);
      });
    return sorted.first;
  }

  int _boolScore(bool value) => value ? 1 : 0;

  int _durationScore(DbTrack row, Track incoming) {
    if (row.durationSeconds == null || incoming.durationSeconds == null) {
      return 0;
    }
    return (row.durationSeconds! - incoming.durationSeconds!).abs() <= 5
        ? 1
        : 0;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Track _fromRow(DbTrack row) {
    return Track(
      id: row.id,
      title: row.title,
      artist: row.artist,
      album: row.album,
      durationSeconds: row.durationSeconds,
      coverUrl: row.coverUrl,
      localCoverPath: row.localCoverPath,
      sourceId: row.sourceId,
      resultId: row.resultId,
      trackKey: row.trackKey,
      baseTrackKey: row.baseTrackKey,
      availability: TrackAvailability(
        inServerCache: row.inServerCache,
        onDevice: row.onDevice,
        cacheKey: row.cacheKey,
        preferredOrigin: PreferredOrigin.fromJson(row.preferredOrigin),
      ),
      localPath: row.localPath,
      localOrigin: row.localOrigin,
      isLiked: row.isLiked,
      lastPlayedAt: row.lastPlayedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TracksCompanion _toCompanion(Track track) {
    return TracksCompanion(
      id: Value(track.id),
      title: Value(track.title),
      artist: Value(track.artist),
      album: Value(track.album),
      durationSeconds: Value(track.durationSeconds),
      coverUrl: Value(track.coverUrl),
      localCoverPath: Value(track.localCoverPath),
      sourceId: Value(track.sourceId),
      resultId: Value(track.resultId),
      trackKey: Value(track.trackKey),
      baseTrackKey: Value(track.baseTrackKey),
      cacheKey: Value(track.availability.cacheKey),
      preferredOrigin: Value(track.availability.preferredOrigin.name),
      inServerCache: Value(track.availability.inServerCache),
      onDevice: Value(track.availability.onDevice),
      localPath: Value(track.localPath),
      localOrigin: Value(track.localOrigin),
      isLiked: Value(track.isLiked),
      lastPlayedAt: Value(track.lastPlayedAt),
      createdAt: Value(track.createdAt),
      updatedAt: Value(track.updatedAt),
    );
  }
}
