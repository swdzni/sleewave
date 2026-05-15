import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import 'track_repository.dart';

class PlaylistRepository {
  PlaylistRepository(this._db, this._tracks);

  final AppDatabase _db;
  final TrackRepository _tracks;
  final _uuid = const Uuid();

  Future<void> ensureFavorites() async {
    final existing =
        await (_db.select(_db.playlists)..where(
              (table) => table.id.equals(AppConstants.favoritePlaylistId),
            ))
            .getSingleOrNull();
    if (existing != null) {
      return;
    }
    final now = DateTime.now();
    await _db
        .into(_db.playlists)
        .insert(
          PlaylistsCompanion.insert(
            id: AppConstants.favoritePlaylistId,
            name: AppConstants.favoritePlaylistName,
            specialType: const Value(AppConstants.favoritePlaylistId),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<List<Playlist>> allPlaylists() async {
    await ensureFavorites();
    final rows =
        await (_db.select(_db.playlists)..orderBy([
              (table) => OrderingTerm.desc(table.specialType),
              (table) => OrderingTerm.asc(table.createdAt),
            ]))
            .get();
    final playlists = <Playlist>[];
    for (final row in rows) {
      playlists.add(
        _fromRow(row).copyWith(trackCount: await trackCount(row.id)),
      );
    }
    return playlists;
  }

  Future<Playlist> create(String name) async {
    final now = DateTime.now();
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.playlists).insert(_toCompanion(playlist));
    return playlist;
  }

  Future<void> rename(Playlist playlist, String name) async {
    if (playlist.isFavorite) {
      return;
    }
    await _db
        .into(_db.playlists)
        .insertOnConflictUpdate(
          _toCompanion(
            playlist.copyWith(name: name.trim(), updatedAt: DateTime.now()),
          ),
        );
  }

  Future<void> delete(Playlist playlist) async {
    if (playlist.isFavorite) {
      return;
    }
    await (_db.delete(
      _db.playlistTracks,
    )..where((table) => table.playlistId.equals(playlist.id))).go();
    await (_db.delete(
      _db.playlists,
    )..where((table) => table.id.equals(playlist.id))).go();
  }

  Future<void> addTrack(String playlistId, Track track) async {
    if (playlistId == AppConstants.favoritePlaylistId) {
      if (!track.isLiked) {
        await _tracks.toggleLike(track);
      }
      return;
    }
    final existing =
        await (_db.select(_db.playlistTracks)..where(
              (table) =>
                  table.playlistId.equals(playlistId) &
                  table.trackId.equals(track.id),
            ))
            .getSingleOrNull();
    if (existing != null) {
      return;
    }
    final maxPosition = await trackCount(playlistId);
    await _db
        .into(_db.playlistTracks)
        .insert(
          PlaylistTracksCompanion.insert(
            playlistId: playlistId,
            trackId: track.id,
            position: maxPosition + 1,
            addedAt: DateTime.now(),
          ),
        );
  }

  Future<void> removeTrack(String playlistId, Track track) async {
    if (playlistId == AppConstants.favoritePlaylistId) {
      if (track.isLiked) {
        await _tracks.toggleLike(track);
      }
      return;
    }
    await (_db.delete(_db.playlistTracks)..where(
          (table) =>
              table.playlistId.equals(playlistId) &
              table.trackId.equals(track.id),
        ))
        .go();
  }

  Future<List<Track>> tracksForPlaylist(String playlistId) async {
    if (playlistId == AppConstants.favoritePlaylistId) {
      return _tracks.likedTracks();
    }
    final query =
        _db.select(_db.tracks).join([
            innerJoin(
              _db.playlistTracks,
              _db.playlistTracks.trackId.equalsExp(_db.tracks.id),
            ),
          ])
          ..where(_db.playlistTracks.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(_db.playlistTracks.position)]);
    final rows = await query.get();
    return rows.map((row) {
      final dbTrack = row.readTable(_db.tracks);
      return Track(
        id: dbTrack.id,
        title: dbTrack.title,
        artist: dbTrack.artist,
        album: dbTrack.album,
        durationSeconds: dbTrack.durationSeconds,
        coverUrl: dbTrack.coverUrl,
        localCoverPath: dbTrack.localCoverPath,
        sourceId: dbTrack.sourceId,
        resultId: dbTrack.resultId,
        trackKey: dbTrack.trackKey,
        baseTrackKey: dbTrack.baseTrackKey,
        localPath: dbTrack.localPath,
        localOrigin: dbTrack.localOrigin,
        isLiked: dbTrack.isLiked,
        lastPlayedAt: dbTrack.lastPlayedAt,
        createdAt: dbTrack.createdAt,
        updatedAt: dbTrack.updatedAt,
      );
    }).toList();
  }

  Future<int> trackCount(String playlistId) async {
    if (playlistId == AppConstants.favoritePlaylistId) {
      final count = _db.tracks.id.count();
      final row =
          await (_db.selectOnly(_db.tracks)
                ..addColumns([count])
                ..where(_db.tracks.isLiked.equals(true)))
              .getSingle();
      return row.read(count) ?? 0;
    }
    final count = _db.playlistTracks.trackId.count();
    final row =
        await (_db.selectOnly(_db.playlistTracks)
              ..addColumns([count])
              ..where(_db.playlistTracks.playlistId.equals(playlistId)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Playlist _fromRow(DbPlaylist row) {
    return Playlist(
      id: row.id,
      name: row.name,
      coverPath: row.coverPath,
      specialType: row.specialType,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  PlaylistsCompanion _toCompanion(Playlist playlist) {
    return PlaylistsCompanion(
      id: Value(playlist.id),
      name: Value(playlist.name),
      coverPath: Value(playlist.coverPath),
      specialType: Value(playlist.specialType),
      createdAt: Value(playlist.createdAt),
      updatedAt: Value(playlist.updatedAt),
    );
  }
}
