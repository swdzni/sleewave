import 'package:drift/drift.dart';

import '../app_database.dart';

class PlaylistsDao {
  const PlaylistsDao(this.db);

  final AppDatabase db;

  Future<List<DbPlaylist>> all() {
    return (db.select(db.playlists)..orderBy([
          (table) => OrderingTerm.asc(table.specialType),
          (table) => OrderingTerm.asc(table.createdAt),
        ]))
        .get();
  }

  Future<void> upsert(PlaylistsCompanion companion) {
    return db.into(db.playlists).insertOnConflictUpdate(companion);
  }
}
