import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/app_startup_controller.dart';
import 'package:sleewave/core/database/app_database.dart';
import 'package:sleewave/core/models/source_info.dart';
import 'package:sleewave/core/models/track.dart';
import 'package:sleewave/core/network/api_client.dart';
import 'package:sleewave/core/network/backend_models.dart';
import 'package:sleewave/core/repositories/backend_repository.dart';
import 'package:sleewave/core/repositories/library_repository.dart';
import 'package:sleewave/core/repositories/playlist_repository.dart';
import 'package:sleewave/core/repositories/settings_repository.dart';
import 'package:sleewave/core/repositories/track_repository.dart';
import 'package:sleewave/core/services/files/file_storage_service.dart';
import 'package:sleewave/core/services/files/metadata_service.dart';
import 'package:sleewave/core/services/sync/sync_service.dart';
import 'package:sleewave/core/theme/theme_controller.dart';
import 'package:sleewave/functions/home/view_models/home_view_model.dart';

void main() {
  late AppDatabase db;
  late ThemeController theme;
  late TrackRepository tracks;
  late PlaylistRepository playlists;
  late AppStartupController startup;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    theme = ThemeController(SettingsRepository(db));
    await theme.load();
    await theme.saveSettings(
      theme.settings.copyWith(backendBaseUrl: 'http://example.test'),
    );
    tracks = TrackRepository(db);
    playlists = PlaylistRepository(db, tracks);
  });

  tearDown(() async {
    await db.close();
  });

  test('initial home load refreshes backend saved songs', () async {
    startup = _startup(
      db,
      theme,
      tracks,
      _FakeBackend(savedSongs: [_track('server-one'), _track('server-two')]),
    );
    final vm = HomeViewModel(tracks, playlists, startup, theme);

    await vm.load(refreshStatus: true);

    expect(startup.savedSongs.map((track) => track.id), [
      'server-one',
      'server-two',
    ]);
    expect(vm.state.savedSongs.map((track) => track.id), [
      'server-one',
      'server-two',
    ]);
    expect(vm.state.loading, isFalse);
  });
}

AppStartupController _startup(
  AppDatabase db,
  ThemeController theme,
  TrackRepository tracks,
  BackendRepository backend,
) {
  final storage = FileStorageService();
  return AppStartupController(
    storage: storage,
    theme: theme,
    playlists: PlaylistRepository(db, tracks),
    library: LibraryRepository(tracks, storage, MetadataService(storage)),
    tracks: tracks,
    sync: SyncService(db, tracks),
    backendFactory: (_) => backend,
  );
}

class _FakeBackend extends BackendRepository {
  _FakeBackend({required this.savedSongs})
    : super(ApiClient(baseUrl: 'http://example.test'));

  final List<Track> savedSongs;

  @override
  Future<List<SourceInfo>> getSources() async {
    return const [];
  }

  @override
  Future<void> syncDeviceLibrary({
    required String deviceId,
    required List<String> resultIds,
  }) async {}

  @override
  Future<SavedSongsPage> getSavedSongsPage({
    int limit = 50,
    int offset = 0,
  }) async {
    return SavedSongsPage(
      songs: savedSongs,
      count: savedSongs.length,
      total: savedSongs.length,
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }
}

Track _track(String id) {
  final now = DateTime(2026);
  return Track(
    id: id,
    title: id,
    artist: 'Artist',
    sourceId: 'source',
    resultId: 'result-$id',
    createdAt: now,
    updatedAt: now,
  );
}
