import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/app_startup_controller.dart';
import '../../../../core/models/app_settings.dart';
import '../../../../core/models/server_status.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers.dart';
import '../../../../core/repositories/backend_repository.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/safe_change_notifier.dart';
import '../models/settings_state.dart';

typedef BackendRepositoryFactory = BackendRepository Function(String baseUrl);
typedef StartupRefresh = Future<void> Function({bool keepConnectedStatus});

class SettingsViewModel extends SafeChangeNotifier {
  SettingsViewModel(
    this._theme,
    this._startup, {
    BackendRepositoryFactory? backendFactory,
    StartupRefresh? refreshBackend,
  }) : _backendFactory =
           backendFactory ??
           ((baseUrl) => BackendRepository(ApiClient(baseUrl: baseUrl))),
       _refreshBackend =
           refreshBackend ??
           (({bool keepConnectedStatus = false}) => _startup.refreshBackend(
             keepConnectedStatus: keepConnectedStatus,
           ));

  final ThemeController _theme;
  final AppStartupController _startup;
  final BackendRepositoryFactory _backendFactory;
  final StartupRefresh _refreshBackend;
  late SettingsState _state = SettingsState(
    settings: _theme.settings,
    status: _startup.status,
    sources: _startup.sources,
  );

  SettingsState get state => _state;

  void load() {
    _state = SettingsState(
      settings: _theme.settings,
      status: _startup.status,
      sources: _startup.sources,
      httpWarning: AppSettings.shouldWarnForHttp(
        _theme.settings.backendBaseUrl,
      ),
      checkedUrl: _startup.status.isConnected
          ? _theme.settings.backendBaseUrl
          : null,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(SleewaveThemeMode mode) async {
    await _theme.setThemeMode(mode);
    load();
  }

  Future<void> setGlowMode(GlowMode mode) async {
    await _theme.setGlowMode(mode);
    load();
  }

  Future<void> checkUrl(String rawUrl) async {
    try {
      final url = AppSettings.normalizeBackendUrl(rawUrl);
      if (url == null) {
        _state = _state.copyWith(
          status: const ServerStatus.notConfigured(),
          checkedUrl: null,
          message: 'Paste a server link first.',
        );
        notifyListeners();
        return;
      }
      _state = _state.copyWith(
        checking: true,
        status: const ServerStatus.checking(),
        message: null,
        httpWarning: AppSettings.shouldWarnForHttp(url),
      );
      notifyListeners();
      final backend = _backendFactory(url);
      final sources = await backend.getSources();
      final settings = _theme.settings.copyWith(
        backendBaseUrl: url,
        selectedSourceIds: const [],
      );
      await _theme.saveSettings(settings);
      _state = _state.copyWith(
        settings: settings,
        checking: false,
        status: const ServerStatus.connected(),
        sources: sources,
        checkedUrl: url,
        message: 'Connected',
      );
      notifyListeners();
      await _refreshBackend(keepConnectedStatus: true);
    } catch (error) {
      _state = _state.copyWith(
        checking: false,
        status: ServerStatus.problem('$error'),
        checkedUrl: null,
        message: '$error',
      );
      notifyListeners();
    }
  }

  Future<void> saveDevice(String deviceId) async {
    final cleanedDeviceId = deviceId.trim();
    if (!AppSettings.isValidDeviceId(cleanedDeviceId)) {
      _state = _state.copyWith(
        message:
            'Device name must be 3-40 letters, numbers, dash, or underscore.',
      );
      notifyListeners();
      return;
    }
    final settings = _theme.settings.copyWith(deviceId: cleanedDeviceId);
    await _theme.saveSettings(settings);
    _state = _state.copyWith(settings: settings, message: 'Saved');
    notifyListeners();
    await _refreshBackend(keepConnectedStatus: _startup.status.isConnected);
  }

  Future<void> setRecentHistoryLimit(int limit) async {
    final settings = _theme.settings.copyWith(recentHistoryLimit: limit);
    await _theme.saveSettings(settings);
    await _startup.tracks.trimRecentlyPlayed(
      limit: settings.recentHistoryLimit,
    );
    _state = _state.copyWith(settings: settings, message: 'Saved');
    notifyListeners();
  }

  Future<void> clear() async {
    final settings = _theme.settings.copyWith(
      backendBaseUrl: null,
      selectedSourceIds: const [],
    );
    await _theme.saveSettings(settings);
    await _refreshBackend();
    load();
  }

  Future<void> clearServerCache() async {
    final backend = _connectedBackend();
    if (backend == null) {
      return;
    }
    _state = _state.copyWith(clearingCache: true, message: null);
    notifyListeners();
    try {
      final result = await backend.clearCache();
      _state = _state.copyWith(
        clearingCache: false,
        message: 'Cleared ${result.deletedCount} cached files.',
      );
      notifyListeners();
      await _refreshBackend(keepConnectedStatus: true);
    } catch (error) {
      _state = _state.copyWith(
        clearingCache: false,
        message: '$error',
        status: ServerStatus.problem('$error'),
      );
      notifyListeners();
    }
  }

  Future<void> clearServerSongs() async {
    final backend = _connectedBackend();
    if (backend == null) {
      return;
    }
    _state = _state.copyWith(clearingSongs: true, message: null);
    notifyListeners();
    try {
      final result = await backend.clearServerTemp();
      _state = _state.copyWith(
        clearingSongs: false,
        message: 'Cleared ${result.deletedCount} server songs.',
      );
      notifyListeners();
      await _refreshBackend(keepConnectedStatus: true);
    } catch (error) {
      _state = _state.copyWith(
        clearingSongs: false,
        message: '$error',
        status: ServerStatus.problem('$error'),
      );
      notifyListeners();
    }
  }

  BackendRepository? _connectedBackend() {
    final baseUrl = _theme.settings.backendBaseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      _state = _state.copyWith(message: 'Connect Online Library first.');
      notifyListeners();
      return null;
    }
    return _backendFactory(baseUrl);
  }
}

final settingsViewModelProvider =
    ChangeNotifierProvider.autoDispose<SettingsViewModel>((ref) {
      return SettingsViewModel(
        ref.read(themeControllerProvider),
        ref.read(appStartupControllerProvider),
      );
    });
