import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';
part 'tables.dart';

@DriftDatabase(
  tables: [
    Tracks,
    Playlists,
    PlaylistTracks,
    RecentTracks,
    Settings,
    PendingActions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'sleewave'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(onCreate: (migrator) => migrator.createAll());
  }
}
