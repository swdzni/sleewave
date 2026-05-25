import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/app_startup_controller.dart';
import 'package:sleewave/core/database/app_database.dart';
import 'package:sleewave/core/models/server_status.dart';
import 'package:sleewave/core/models/source_info.dart';
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

void main() {
  late AppDatabase db;
  late SettingsRepository settingsRepository;
  late ThemeController theme;
  late TrackRepository tracks;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settingsRepository = SettingsRepository(db);
    theme = ThemeController(settingsRepository);
    await theme.load();
    await theme.saveSettings(
      theme.settings.copyWith(backendBaseUrl: 'http://example.test'),
    );
    tracks = TrackRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('automatic backend refresh fails once until forced retry', () async {
    final backend = _CountingBackend(
      onGetSources: () => throw DioException.connectionError(
        requestOptions: RequestOptions(path: '/sources'),
        reason: 'offline',
      ),
    );
    final startup = _startup(db, theme, tracks, backend);

    await startup.refreshBackend();
    await startup.refreshBackend();

    expect(backend.sourceCalls, 1);
    expect(startup.status.kind, ServerStatusKind.problem);
    expect(startup.manualRetryRequired, isTrue);

    await startup.refreshBackend(force: true);

    expect(backend.sourceCalls, 2);
  });

  test(
    'forced retry can reconnect and clears manual retry requirement',
    () async {
      var fail = true;
      final backend = _CountingBackend(
        onGetSources: () {
          if (fail) {
            throw DioException.connectionError(
              requestOptions: RequestOptions(path: '/sources'),
              reason: 'offline',
            );
          }
          return const [];
        },
      );
      final startup = _startup(db, theme, tracks, backend);

      await startup.refreshBackend();
      fail = false;
      await startup.refreshBackend(force: true);

      expect(backend.sourceCalls, 2);
      expect(startup.status.isConnected, isTrue);
      expect(startup.manualRetryRequired, isFalse);
    },
  );
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

class _CountingBackend extends BackendRepository {
  _CountingBackend({required this.onGetSources})
    : super(ApiClient(baseUrl: 'http://example.test'));

  final List<SourceInfo> Function() onGetSources;
  int sourceCalls = 0;

  @override
  Future<List<SourceInfo>> getSources() async {
    sourceCalls += 1;
    return onGetSources();
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
      songs: const [],
      count: 0,
      total: 0,
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }
}
