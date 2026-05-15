import 'package:drift/drift.dart';

import '../app_database.dart';

class PendingActionsDao {
  const PendingActionsDao(this.db);

  final AppDatabase db;

  Future<List<DbPendingAction>> oldestFirst() {
    return (db.select(
      db.pendingActions,
    )..orderBy([(table) => OrderingTerm.asc(table.createdAt)])).get();
  }
}
