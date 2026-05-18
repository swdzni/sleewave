import 'dart:math';

import '../constants/app_constants.dart';

enum SleewaveThemeMode {
  pureDark,
  dark,
  white;

  static SleewaveThemeMode fromStorage(String? value) {
    return SleewaveThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => SleewaveThemeMode.dark,
    );
  }
}

enum GlowMode {
  static,
  dynamic;

  static GlowMode fromStorage(String? value) {
    return GlowMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => GlowMode.static,
    );
  }
}

class AppSettings {
  AppSettings({
    this.themeMode = SleewaveThemeMode.dark,
    this.glowMode = GlowMode.static,
    this.backendBaseUrl,
    required this.deviceId,
    this.selectedSourceIds = const [],
    this.searchLimit = AppConstants.defaultSearchLimit,
    int recentHistoryLimit = AppConstants.defaultRecentHistoryLimit,
    this.shareWithText = false,
  }) : recentHistoryLimit = recentHistoryLimit.clamp(
         AppConstants.minRecentHistoryLimit,
         AppConstants.maxRecentHistoryLimit,
       );

  factory AppSettings.defaults({String? deviceId}) {
    return AppSettings(deviceId: deviceId ?? generateDeviceId());
  }

  final SleewaveThemeMode themeMode;
  final GlowMode glowMode;
  final String? backendBaseUrl;
  final String deviceId;
  final List<String> selectedSourceIds;
  final int searchLimit;
  final int recentHistoryLimit;
  final bool shareWithText;

  static String generateDeviceId({Random? random}) {
    final source = random ?? Random.secure();
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final suffix = List.generate(
      6,
      (_) => alphabet[source.nextInt(alphabet.length)],
    ).join();
    return 'device-$suffix';
  }

  static bool isValidDeviceId(String value) {
    return RegExp(r'^[A-Za-z0-9_-]{3,40}$').hasMatch(value);
  }

  static String? normalizeBackendUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('Check server link.');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const FormatException('Check server link.');
    }
    var normalized = trimmed;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static bool shouldWarnForHttp(String? normalizedUrl) {
    if (normalizedUrl == null) {
      return false;
    }
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || uri.scheme != 'http') {
      return false;
    }
    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
      return false;
    }
    if (host.startsWith('10.') || host.startsWith('192.168.')) {
      return false;
    }
    final privateLan = RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.');
    return !privateLan.hasMatch(host);
  }

  AppSettings copyWith({
    SleewaveThemeMode? themeMode,
    GlowMode? glowMode,
    Object? backendBaseUrl = _sentinel,
    String? deviceId,
    List<String>? selectedSourceIds,
    int? searchLimit,
    int? recentHistoryLimit,
    bool? shareWithText,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      glowMode: glowMode ?? this.glowMode,
      backendBaseUrl: backendBaseUrl == _sentinel
          ? this.backendBaseUrl
          : backendBaseUrl as String?,
      deviceId: deviceId ?? this.deviceId,
      selectedSourceIds: selectedSourceIds ?? this.selectedSourceIds,
      searchLimit: searchLimit ?? this.searchLimit,
      recentHistoryLimit: recentHistoryLimit ?? this.recentHistoryLimit,
      shareWithText: shareWithText ?? this.shareWithText,
    );
  }
}

const _sentinel = Object();
