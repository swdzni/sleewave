import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/app_startup_controller.dart';
import 'package:sleewave/core/database/app_database.dart';
import 'package:sleewave/core/models/source_info.dart';
import 'package:sleewave/core/network/api_client.dart';
import 'package:sleewave/core/repositories/backend_repository.dart';
import 'package:sleewave/core/repositories/library_repository.dart';
import 'package:sleewave/core/repositories/playlist_repository.dart';
import 'package:sleewave/core/repositories/settings_repository.dart';
import 'package:sleewave/core/repositories/track_repository.dart';
import 'package:sleewave/core/services/files/file_storage_service.dart';
import 'package:sleewave/core/services/files/metadata_service.dart';
import 'package:sleewave/core/services/sync/sync_service.dart';
import 'package:sleewave/core/theme/theme_controller.dart';
import 'package:sleewave/functions/settings/main_settings/view_models/settings_view_model.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settingsRepository;
  late ThemeController theme;
  late AppStartupController startup;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settingsRepository = SettingsRepository(db);
    theme = ThemeController(settingsRepository);
    await theme.load();
    final tracks = TrackRepository(db);
    final storage = FileStorageService();
    startup = AppStartupController(
      storage: storage,
      theme: theme,
      playlists: PlaylistRepository(db, tracks),
      library: LibraryRepository(tracks, storage, MetadataService(storage)),
      tracks: tracks,
      sync: SyncService(db, tracks),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('successful save stores the Online Library URL', () async {
    final vm = SettingsViewModel(
      theme,
      startup,
      backendFactory: (_) => _FakeBackendRepository([
        const SourceInfo(
          id: 'source-a',
          name: 'Source A',
          available: true,
          supportsSearch: true,
          supportsStream: true,
          supportsDownload: true,
        ),
      ]),
      refreshBackend: ({bool keepConnectedStatus = false}) async {},
    );

    await vm.saveUrl(' http://127.0.0.1:8000/ ');
    final saved = await settingsRepository.load();

    expect(saved.backendBaseUrl, 'http://127.0.0.1:8000');
    expect(saved.selectedSourceIds, isEmpty);
    expect(vm.state.status.isConnected, isTrue);
  });

  test('failed save leaves the stored Online Library URL unchanged', () async {
    await theme.saveSettings(
      theme.settings.copyWith(backendBaseUrl: 'http://old.test'),
    );
    final vm = SettingsViewModel(
      theme,
      startup,
      backendFactory: (_) =>
          _FakeBackendRepository(const [], error: StateError('No connection')),
      refreshBackend: ({bool keepConnectedStatus = false}) async {},
    );

    await vm.saveUrl('http://new.test');
    final saved = await settingsRepository.load();

    expect(saved.backendBaseUrl, 'http://old.test');
    expect(vm.state.status.isConnected, isFalse);
  });

  test('saves recent history limit', () async {
    final vm = SettingsViewModel(
      theme,
      startup,
      refreshBackend: ({bool keepConnectedStatus = false}) async {},
    );

    await vm.setRecentHistoryLimit(35);
    final saved = await settingsRepository.load();

    expect(saved.recentHistoryLimit, 35);
    expect(vm.state.settings.recentHistoryLimit, 35);
  });

  test('saves share text preference', () async {
    final vm = SettingsViewModel(
      theme,
      startup,
      refreshBackend: ({bool keepConnectedStatus = false}) async {},
    );

    await vm.setShareWithText(true);
    final saved = await settingsRepository.load();

    expect(saved.shareWithText, isTrue);
    expect(vm.state.settings.shareWithText, isTrue);
  });

  test('saves direct URL preference', () async {
    final vm = SettingsViewModel(
      theme,
      startup,
      refreshBackend: ({bool keepConnectedStatus = false}) async {},
    );

    await vm.setDirectUrlEnabled(true);
    final saved = await settingsRepository.load();

    expect(saved.directUrlEnabled, isTrue);
    expect(vm.state.settings.directUrlEnabled, isTrue);
  });
}

class _FakeBackendRepository extends BackendRepository {
  _FakeBackendRepository(this.sources, {this.error})
    : super(ApiClient(baseUrl: 'http://fake.test'));

  final List<SourceInfo> sources;
  final Object? error;

  @override
  Future<List<SourceInfo>> getSources() async {
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return sources;
  }
}
