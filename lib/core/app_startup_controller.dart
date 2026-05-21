import 'package:flutter_riverpod/legacy.dart';

import 'models/server_status.dart';
import 'models/source_info.dart';
import 'models/track.dart';
import 'providers.dart';
import 'repositories/library_repository.dart';
import 'repositories/playlist_repository.dart';
import 'repositories/track_repository.dart';
import 'services/files/file_storage_service.dart';
import 'services/sync/sync_service.dart';
import 'theme/theme_controller.dart';
import 'utils/safe_change_notifier.dart';

class AppStartupController extends SafeChangeNotifier {
  AppStartupController({
    required this.storage,
    required this.theme,
    required this.playlists,
    required this.library,
    required this.tracks,
    required this.sync,
  });

  final FileStorageService storage;
  final ThemeController theme;
  final PlaylistRepository playlists;
  final LibraryRepository library;
  final TrackRepository tracks;
  final SyncService sync;

  bool _started = false;
  bool _ready = false;
  ServerStatus _status = const ServerStatus.unknown();
  List<SourceInfo> _sources = const [];
  List<Track> _savedSongs = const [];
  Future<void>? _backendRefresh;

  bool get ready => _ready;
  ServerStatus get status => _status;
  List<SourceInfo> get sources => _sources;
  List<Track> get savedSongs => _savedSongs;

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

  Future<void> refreshBackend({bool keepConnectedStatus = false}) async {
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
    final backend = backendForSettings(settings);
    if (backend == null) {
      _status = const ServerStatus.notConfigured();
      _sources = const [];
      _savedSongs = const [];
      notifyListeners();
      return;
    }
    if (!(keepConnectedStatus && _status.isConnected)) {
      _status = const ServerStatus.checking();
      notifyListeners();
    }
    try {
      _sources = await backend.getSources();
      _status = const ServerStatus.connected();
      notifyListeners();
      await sync.syncDeviceLibrary(backend, settings);
      await sync.retryPending(backend);
      final savedSongs = <Track>[];
      final seenIds = <String>{};
      for (final song in await backend.getSavedSongs()) {
        final merged = await tracks.mergeRemoteTrack(song);
        if (seenIds.add(merged.id)) {
          savedSongs.add(merged);
        }
      }
      _savedSongs = savedSongs;
      notifyListeners();
    } catch (error) {
      _status = ServerStatus.problem('$error');
      notifyListeners();
    }
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
