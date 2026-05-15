import 'package:drift/drift.dart';

import '../app_database.dart';

class RecentDao {
  const RecentDao(this.db);

  final AppDatabase db;

  Future<List<DbRecentTrack>> latest({int limit = 20}) {
    return (db.select(db.recentTracks)
          ..orderBy([(table) => OrderingTerm.desc(table.playedAt)])
          ..limit(limit))
        .get();
  }
}
