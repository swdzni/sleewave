import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/app_startup_controller.dart';
import '../../../../core/models/app_settings.dart';
import '../../../../core/models/server_status.dart';
import '../../../../core/models/source_info.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/repositories/backend_repository.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/safe_change_notifier.dart';
import '../models/settings_state.dart';

typedef BackendRepositoryFactory = BackendRepository Function(String baseUrl);
typedef StartupRefresh =
    Future<void> Function({bool keepConnectedStatus, bool force});

class SettingsViewModel extends SafeChangeNotifier {
  SettingsViewModel(
    this._theme,
    this._startup, {
    BackendRepositoryFactory? backendFactory,
    StartupRefresh? refreshBackend,
    Ref? ref,
  }) : _backendFactory =
           backendFactory ??
           ((baseUrl) => BackendRepository(ApiClient(baseUrl: baseUrl))),
       _refreshBackend =
           refreshBackend ??
           (({bool keepConnectedStatus = false, bool force = false}) =>
               _startup.refreshBackend(
                 keepConnectedStatus: keepConnectedStatus,
                 force: force,
               )),
       _ref = ref;

  final ThemeController _theme;
  final AppStartupController _startup;
  final BackendRepositoryFactory _backendFactory;
  final StartupRefresh _refreshBackend;
  final Ref? _ref;
  late SettingsState _state = SettingsState(
    settings: _theme.settings,
    status: _startup.status,
    sources: _startup.sources,
  );

  SettingsState get state => _state;

  void load() {
    _state = SettingsState(
      settings: _settingsWithEffectiveDirectUrlSources(
        _theme.settings,
        _startup.sources,
      ),
      status: _startup.status,
      sources: _startup.sources,
      httpWarning: AppSettings.shouldWarnForHttp(
        _theme.settings.backendBaseUrl,
      ),
      checkedUrl: _theme.settings.backendBaseUrl,
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

  Future<void> saveUrl(String rawUrl) async {
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
        directUrlEnabled: false,
        directUrlSourceIds: _effectiveDirectUrlSources(
          _theme.settings,
          sources,
        ),
      );
      await _theme.saveSettings(settings);
      _state = _state.copyWith(
        settings: settings,
        checking: false,
        status: const ServerStatus.connected(),
        sources: sources,
        checkedUrl: url,
        message: 'Saved',
      );
      notifyListeners();
      await _refreshBackend(keepConnectedStatus: true, force: true);
      _state = _state.copyWith(
        status:
            _startup.status.isConnected ||
                _startup.status.kind == ServerStatusKind.problem
            ? _startup.status
            : const ServerStatus.connected(),
        sources: _startup.sources.isEmpty ? sources : _startup.sources,
        message: 'Saved',
      );
      notifyListeners();
      _notifyLibraryChanged();
    } catch (error) {
      final message = _messageForError(error);
      _state = _state.copyWith(
        checking: false,
        status: ServerStatus.problem(message),
        checkedUrl: _theme.settings.backendBaseUrl,
        message: message,
      );
      notifyListeners();
    }
  }

  Future<void> checkUrl(String rawUrl) => saveUrl(rawUrl);

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
    _notifyLibraryChanged();
  }

  Future<void> setRecentHistoryLimit(int limit) async {
    final settings = _theme.settings.copyWith(recentHistoryLimit: limit);
    await _theme.saveSettings(settings);
    await _startup.tracks.trimRecentlyPlayed(
      limit: settings.recentHistoryLimit,
    );
    _state = _state.copyWith(settings: settings, message: 'Saved');
    notifyListeners();
    _notifyLibraryChanged();
  }

  Future<void> setShareWithText(bool enabled) async {
    final settings = _theme.settings.copyWith(shareWithText: enabled);
    await _theme.saveSettings(settings);
    _state = _state.copyWith(settings: settings, message: 'Saved');
    notifyListeners();
  }

  Future<void> setDirectUrlEnabled(bool enabled) async {
    await setDirectUrlForAllSources(enabled);
  }

  Future<void> setDirectUrlForAllSources(bool enabled) async {
    final streamableIds = _streamableSourceIds(_state.sources);
    final settings = _theme.settings.copyWith(
      directUrlEnabled: _state.sources.isEmpty ? enabled : false,
      directUrlSourceIds: enabled ? streamableIds : const [],
    );
    await _theme.saveSettings(settings);
    _state = _state.copyWith(
      settings: _settingsWithEffectiveDirectUrlSources(
        settings,
        _state.sources,
      ),
      message: 'Saved',
    );
    notifyListeners();
  }

  Future<void> setDirectUrlForSource(String sourceId, bool enabled) async {
    final source = _state.sources
        .where((candidate) => candidate.id == sourceId)
        .firstOrNull;
    if (enabled &&
        (source == null || !source.available || !source.supportsStream)) {
      return;
    }
    final selected = _effectiveDirectUrlSources(
      _theme.settings,
      _state.sources,
    ).toSet();
    if (enabled) {
      selected.add(sourceId);
    } else {
      selected.remove(sourceId);
    }
    final settings = _theme.settings.copyWith(
      directUrlEnabled: false,
      directUrlSourceIds: _normalizeDirectUrlSources(
        selected.toList(),
        _state.sources,
      ),
    );
    await _theme.saveSettings(settings);
    _state = _state.copyWith(settings: settings, message: 'Saved');
    notifyListeners();
  }

  Future<void> clear() async {
    final settings = _theme.settings.copyWith(
      backendBaseUrl: null,
      selectedSourceIds: const [],
      directUrlEnabled: false,
      directUrlSourceIds: const [],
    );
    await _theme.saveSettings(settings);
    await _refreshBackend();
    load();
    _notifyLibraryChanged();
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
        message: result.message('cached files'),
      );
      notifyListeners();
      await _refreshBackend(keepConnectedStatus: true);
      _notifyLibraryChanged();
    } catch (error) {
      final message = _messageForError(error);
      _state = _state.copyWith(
        clearingCache: false,
        message: message,
        status: ServerStatus.problem(message),
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
        message: result.message('server files'),
      );
      notifyListeners();
      await _refreshBackend(keepConnectedStatus: true);
      _notifyLibraryChanged();
    } catch (error) {
      final message = _messageForError(error);
      _state = _state.copyWith(
        clearingSongs: false,
        message: message,
        status: ServerStatus.problem(message),
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

  void _notifyLibraryChanged() {
    final ref = _ref;
    if (ref != null) {
      notifyLibraryChanged(ref);
    }
  }

  List<String> _normalizeDirectUrlSources(
    List<String> selected,
    List<SourceInfo> sources,
  ) {
    final streamableIds = _streamableSourceIds(sources);
    return [
      for (final id in streamableIds)
        if (selected.contains(id)) id,
    ];
  }

  AppSettings _settingsWithEffectiveDirectUrlSources(
    AppSettings settings,
    List<SourceInfo> sources,
  ) {
    return settings.copyWith(
      directUrlSourceIds: _effectiveDirectUrlSources(settings, sources),
    );
  }

  List<String> _effectiveDirectUrlSources(
    AppSettings settings,
    List<SourceInfo> sources,
  ) {
    if (settings.directUrlEnabled) {
      return _streamableSourceIds(sources);
    }
    return _normalizeDirectUrlSources(settings.directUrlSourceIds, sources);
  }

  List<String> _streamableSourceIds(List<SourceInfo> sources) {
    return sources
        .where((source) => source.available && source.supportsStream)
        .map((source) => source.id)
        .toList();
  }

  String _messageForError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    final message = '$error'.trim();
    return message.isEmpty ? 'Online Library request failed.' : message;
  }
}

final settingsViewModelProvider =
    ChangeNotifierProvider.autoDispose<SettingsViewModel>((ref) {
      return SettingsViewModel(
        ref.read(themeControllerProvider),
        ref.read(appStartupControllerProvider),
        ref: ref,
      );
    });
