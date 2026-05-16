import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  const SettingsRepository(this._db);

  final AppDatabase _db;

  static const _themeMode = 'themeMode';
  static const _glowMode = 'glowMode';
  static const _backendBaseUrl = 'backendBaseUrl';
  static const _deviceId = 'deviceId';
  static const _selectedSourceIds = 'selectedSourceIds';
  static const _searchLimit = 'searchLimit';
  static const _recentHistoryLimit = 'recentHistoryLimit';

  Future<AppSettings> load() async {
    final rows = await _db.select(_db.settings).get();
    final values = {for (final row in rows) row.key: row.value};
    final deviceId = values[_deviceId];
    final resolvedDeviceId = AppSettings.isValidDeviceId(deviceId ?? '')
        ? deviceId!
        : null;
    final selectedSourceIds = _decodeStringList(values[_selectedSourceIds]);
    final settings = AppSettings(
      themeMode: SleewaveThemeMode.fromStorage(values[_themeMode]),
      glowMode: GlowMode.fromStorage(values[_glowMode]),
      backendBaseUrl: values[_backendBaseUrl],
      deviceId: resolvedDeviceId ?? AppSettings.generateDeviceId(),
      selectedSourceIds: selectedSourceIds,
      searchLimit:
          int.tryParse(values[_searchLimit] ?? '') ??
          AppSettings.defaults().searchLimit,
      recentHistoryLimit:
          int.tryParse(values[_recentHistoryLimit] ?? '') ??
          AppSettings.defaults().recentHistoryLimit,
    );
    if (resolvedDeviceId == null) {
      await save(settings);
    }
    return settings;
  }

  Future<void> save(AppSettings settings) async {
    await _set(_themeMode, settings.themeMode.name);
    await _set(_glowMode, settings.glowMode.name);
    if (settings.backendBaseUrl == null) {
      await (_db.delete(
        _db.settings,
      )..where((table) => table.key.equals(_backendBaseUrl))).go();
    } else {
      await _set(_backendBaseUrl, settings.backendBaseUrl!);
    }
    await _set(_deviceId, settings.deviceId);
    await _set(_selectedSourceIds, jsonEncode(settings.selectedSourceIds));
    await _set(_searchLimit, '${settings.searchLimit}');
    await _set(_recentHistoryLimit, '${settings.recentHistoryLimit}');
  }

  Future<void> clearBackendUrl() async {
    await (_db.delete(
      _db.settings,
    )..where((table) => table.key.equals(_backendBaseUrl))).go();
  }

  Future<void> _set(String key, String value) {
    return _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(key: Value(key), value: Value(value)),
        );
  }

  List<String> _decodeStringList(String? value) {
    if (value == null) {
      return const [];
    }
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      return const [];
    }
    return decoded.map((item) => '$item').toList();
  }
}
