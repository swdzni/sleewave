import 'package:drift/drift.dart';

import '../app_database.dart';

class TracksDao {
  const TracksDao(this.db);

  final AppDatabase db;

  Future<List<DbTrack>> all() {
    return (db.select(
      db.tracks,
    )..orderBy([(table) => OrderingTerm.desc(table.updatedAt)])).get();
  }

  Stream<List<DbTrack>> watchAll() {
    return (db.select(
      db.tracks,
    )..orderBy([(table) => OrderingTerm.desc(table.updatedAt)])).watch();
  }

  Future<DbTrack?> byId(String id) {
    return (db.select(
      db.tracks,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsert(TracksCompanion companion) {
    return db.into(db.tracks).insertOnConflictUpdate(companion);
  }
}
