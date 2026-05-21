import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'database/app_database.dart';
import 'models/app_settings.dart';
import 'network/api_client.dart';
import 'repositories/backend_repository.dart';
import 'repositories/library_repository.dart';
import 'repositories/playlist_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/track_repository.dart';
import 'services/downloads/download_service.dart';
import 'services/files/file_storage_service.dart';
import 'services/files/metadata_service.dart';
import 'services/playback/playback_service.dart';
import 'services/playback/queue_service.dart';
import 'services/search/search_service.dart';
import 'services/share/track_share_service.dart';
import 'services/sync/sync_service.dart';
import 'theme/theme_controller.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final themeControllerProvider = ChangeNotifierProvider<ThemeController>((ref) {
  return ThemeController(ref.watch(settingsRepositoryProvider));
});

final fileStorageProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

final metadataServiceProvider = Provider<MetadataService>((ref) {
  return MetadataService(ref.watch(fileStorageProvider));
});

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return TrackRepository(ref.watch(databaseProvider));
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository(
    ref.watch(databaseProvider),
    ref.watch(trackRepositoryProvider),
  );
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(
    ref.watch(trackRepositoryProvider),
    ref.watch(fileStorageProvider),
    ref.watch(metadataServiceProvider),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(databaseProvider),
    ref.watch(trackRepositoryProvider),
  );
});

final searchServiceProvider = Provider<SearchService>((ref) {
  return const SearchService();
});

final libraryRevisionProvider = StateProvider<int>((ref) => 0);

void notifyLibraryChanged(Ref ref) {
  ref.read(libraryRevisionProvider.notifier).state++;
}

void notifyLibraryChangedFromWidget(WidgetRef ref) {
  ref.read(libraryRevisionProvider.notifier).state++;
}

final queueServiceProvider = ChangeNotifierProvider<QueueService>((ref) {
  return QueueService();
});

final playbackServiceProvider = ChangeNotifierProvider<PlaybackService>((ref) {
  return PlaybackService(
    ref.read(trackRepositoryProvider),
    ref.read(queueServiceProvider),
    onTrackRecorded: (_) => notifyLibraryChanged(ref),
  );
});

final downloadServiceProvider = ChangeNotifierProvider<DownloadService>((ref) {
  return DownloadService(
    ref.read(fileStorageProvider),
    ref.read(trackRepositoryProvider),
    ref.read(syncServiceProvider),
  );
});

final trackShareServiceProvider = Provider<TrackShareService>((ref) {
  return TrackShareService(ref.read(fileStorageProvider));
});

final backendRepositoryProvider = Provider<BackendRepository?>((ref) {
  final settings = ref.watch(themeControllerProvider).settings;
  final baseUrl = settings.backendBaseUrl;
  if (baseUrl == null || baseUrl.isEmpty) {
    return null;
  }
  return BackendRepository(ApiClient(baseUrl: baseUrl));
});

BackendRepository? backendForSettings(AppSettings settings) {
  final baseUrl = settings.backendBaseUrl;
  if (baseUrl == null || baseUrl.isEmpty) {
    return null;
  }
  return BackendRepository(ApiClient(baseUrl: baseUrl));
}
