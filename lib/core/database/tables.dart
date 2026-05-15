part of 'app_database.dart';

@DataClassName('DbTrack')
@TableIndex(name: 'tracks_track_key_idx', columns: {#trackKey})
@TableIndex(name: 'tracks_base_track_key_idx', columns: {#baseTrackKey})
@TableIndex(name: 'tracks_title_idx', columns: {#title})
@TableIndex(name: 'tracks_artist_idx', columns: {#artist})
@TableIndex(name: 'tracks_last_played_at_idx', columns: {#lastPlayedAt})
@TableIndex(name: 'tracks_is_liked_idx', columns: {#isLiked})
class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist =>
      text().withDefault(const Constant('Unknown Artist'))();
  TextColumn get album => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get localCoverPath => text().nullable()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get resultId => text().nullable()();
  TextColumn get trackKey => text().nullable()();
  TextColumn get baseTrackKey => text().nullable()();
  TextColumn get cacheKey => text().nullable()();
  TextColumn get preferredOrigin =>
      text().withDefault(const Constant('local'))();
  BoolColumn get inServerCache =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get onDevice => boolean().withDefault(const Constant(false))();
  TextColumn get localPath => text().nullable()();
  TextColumn get localOrigin => text()();
  BoolColumn get isLiked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbPlaylist')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get specialType => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbPlaylistTrack')
class PlaylistTracks extends Table {
  TextColumn get playlistId => text().references(Playlists, #id)();
  TextColumn get trackId => text().references(Tracks, #id)();
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {playlistId, trackId};
}

@DataClassName('DbRecentTrack')
class RecentTracks extends Table {
  TextColumn get trackId => text().references(Tracks, #id)();
  DateTimeColumn get playedAt => dateTime()();
  IntColumn get playCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {trackId};
}

@DataClassName('DbSetting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('DbPendingAction')
class PendingActions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
