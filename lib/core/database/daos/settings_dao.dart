import 'package:drift/drift.dart';

import '../app_database.dart';

class SettingsDao {
  const SettingsDao(this.db);

  final AppDatabase db;

  Future<String?> getValue(String key) async {
    final row = await (db.select(
      db.settings,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<Map<String, String>> all() async {
    final rows = await db.select(db.settings).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<void> setValue(String key, String value) {
    return db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(key: Value(key), value: Value(value)),
        );
  }

  Future<void> deleteValue(String key) {
    return (db.delete(
      db.settings,
    )..where((table) => table.key.equals(key))).go();
  }
}
