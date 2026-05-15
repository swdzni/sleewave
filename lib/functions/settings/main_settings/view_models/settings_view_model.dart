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

class SettingsViewModel extends SafeChangeNotifier {
  SettingsViewModel(this._theme, this._startup);

  final ThemeController _theme;
  final AppStartupController _startup;
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
      final backend = BackendRepository(ApiClient(baseUrl: url));
      final sources = await backend.getSources();
      _state = _state.copyWith(
        checking: false,
        status: const ServerStatus.connected(),
        sources: sources,
        checkedUrl: url,
        message: 'Connected',
      );
      notifyListeners();
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

  Future<void> saveOnlineLibrary(String rawUrl) async {
    try {
      final normalized = AppSettings.normalizeBackendUrl(rawUrl);
      final wasConnected =
          _state.status.isConnected &&
          normalized != null &&
          normalized == (_state.checkedUrl ?? _state.settings.backendBaseUrl);
      final settings = _theme.settings.copyWith(
        backendBaseUrl: normalized,
        selectedSourceIds: normalized == null
            ? const []
            : _state.sources
                  .where((source) => source.canSearch)
                  .map((source) => source.id)
                  .toList(),
      );
      await _theme.saveSettings(settings);
      _state = _state.copyWith(
        settings: settings,
        checking: !wasConnected && normalized != null,
        status: normalized == null
            ? const ServerStatus.notConfigured()
            : wasConnected
            ? _state.status
            : const ServerStatus.checking(),
        checkedUrl: normalized == null ? null : _state.checkedUrl,
        message: normalized == null
            ? 'Cleared'
            : wasConnected
            ? 'Saved and connected'
            : 'Saved',
        httpWarning: AppSettings.shouldWarnForHttp(normalized),
      );
      notifyListeners();
      if (normalized == null) {
        await _startup.refreshBackend();
        load();
        return;
      }
      await _startup.refreshBackend(keepConnectedStatus: wasConnected);
      _state = _state.copyWith(
        settings: _theme.settings,
        status: _startup.status,
        sources: _startup.sources,
        checking: false,
        checkedUrl: _startup.status.isConnected ? normalized : null,
        message: _startup.status.isConnected
            ? 'Saved and connected'
            : _startup.status.label,
      );
      notifyListeners();
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
    await _startup.refreshBackend(
      keepConnectedStatus: _startup.status.isConnected,
    );
  }

  Future<void> clear() async {
    final settings = _theme.settings.copyWith(
      backendBaseUrl: null,
      selectedSourceIds: const [],
    );
    await _theme.saveSettings(settings);
    await _startup.refreshBackend();
    load();
  }
}

final settingsViewModelProvider =
    ChangeNotifierProvider.autoDispose<SettingsViewModel>((ref) {
      return SettingsViewModel(
        ref.read(themeControllerProvider),
        ref.read(appStartupControllerProvider),
      );
    });
