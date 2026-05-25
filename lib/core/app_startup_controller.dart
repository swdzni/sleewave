import 'package:flutter_riverpod/legacy.dart';

import 'models/server_status.dart';
import 'models/source_info.dart';
import 'models/track.dart';
import 'models/app_settings.dart';
import 'constants/app_constants.dart';
import 'network/api_exception.dart';
import 'providers.dart';
import 'repositories/backend_repository.dart';
import 'repositories/library_repository.dart';
import 'repositories/playlist_repository.dart';
import 'repositories/track_repository.dart';
import 'services/files/file_storage_service.dart';
import 'services/sync/sync_service.dart';
import 'theme/theme_controller.dart';
import 'utils/safe_change_notifier.dart';

typedef StartupBackendFactory =
    BackendRepository? Function(AppSettings settings);

class AppStartupController extends SafeChangeNotifier {
  AppStartupController({
    required this.storage,
    required this.theme,
    required this.playlists,
    required this.library,
    required this.tracks,
    required this.sync,
    StartupBackendFactory? backendFactory,
  }) : _backendFactory = backendFactory ?? backendForSettings;

  final FileStorageService storage;
  final ThemeController theme;
  final PlaylistRepository playlists;
  final LibraryRepository library;
  final TrackRepository tracks;
  final SyncService sync;
  final StartupBackendFactory _backendFactory;

  bool _started = false;
  bool _ready = false;
  ServerStatus _status = const ServerStatus.unknown();
  List<SourceInfo> _sources = const [];
  List<Track> _savedSongs = const [];
  Future<void>? _backendRefresh;
  bool _manualRetryRequired = false;
  String? _failedBaseUrl;

  bool get ready => _ready;
  ServerStatus get status => _status;
  List<SourceInfo> get sources => _sources;
  List<Track> get savedSongs => _savedSongs;
  bool get manualRetryRequired => _manualRetryRequired;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    await storage.initialize();
    await theme.load();
    await playlists.ensureFavorites();
    await library.scanLocalLibrary();
    _ready = true;
    notifyListeners();
    await refreshBackend();
  }

  Future<void> refreshBackend({
    bool keepConnectedStatus = false,
    bool force = false,
  }) async {
    if (!force &&
        _manualRetryRequired &&
        _status.kind == ServerStatusKind.problem &&
        theme.settings.backendBaseUrl == _failedBaseUrl) {
      return;
    }
    final activeRefresh = _backendRefresh;
    if (activeRefresh != null) {
      return activeRefresh;
    }
    final refresh = _refreshBackend(keepConnectedStatus: keepConnectedStatus);
    _backendRefresh = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_backendRefresh, refresh)) {
        _backendRefresh = null;
      }
    }
  }

  Future<void> _refreshBackend({required bool keepConnectedStatus}) async {
    final settings = theme.settings;
    final backend = _backendFactory(settings);
    if (backend == null) {
      _manualRetryRequired = false;
      _failedBaseUrl = null;
      _status = const ServerStatus.notConfigured();
      _sources = const [];
      _savedSongs = const [];
      notifyListeners();
      return;
    }
    if (!(keepConnectedStatus && _status.isConnected)) {
      _manualRetryRequired = false;
      _status = const ServerStatus.checking();
      notifyListeners();
    }
    try {
      _sources = await backend.getSources();
      _manualRetryRequired = false;
      _failedBaseUrl = null;
      _status = const ServerStatus.connected();
      notifyListeners();
      await sync.syncDeviceLibrary(backend, settings);
      await sync.retryPending(backend);
      final savedSongs = <Track>[];
      final seenIds = <String>{};
      final page = await backend.getSavedSongsPage(
        limit: AppConstants.homeServerPreviewLimit,
      );
      for (final song in page.songs) {
        final merged = await tracks.mergeRemoteTrack(song);
        if (seenIds.add(merged.id)) {
          savedSongs.add(merged);
        }
      }
      _savedSongs = savedSongs;
      notifyListeners();
    } catch (error) {
      _manualRetryRequired = true;
      _failedBaseUrl = settings.backendBaseUrl;
      _status = ServerStatus.problem(_backendErrorMessage(error));
      notifyListeners();
    }
  }

  String _backendErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '$error';
  }
}

final appStartupControllerProvider =
    ChangeNotifierProvider<AppStartupController>((ref) {
      return AppStartupController(
        storage: ref.read(fileStorageProvider),
        theme: ref.read(themeControllerProvider),
        playlists: ref.read(playlistRepositoryProvider),
        library: ref.read(libraryRepositoryProvider),
        tracks: ref.read(trackRepositoryProvider),
        sync: ref.read(syncServiceProvider),
      );
    });
