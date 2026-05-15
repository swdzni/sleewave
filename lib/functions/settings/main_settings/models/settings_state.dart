import '../../../../core/models/app_settings.dart';
import '../../../../core/models/server_status.dart';
import '../../../../core/models/source_info.dart';

class SettingsState {
  const SettingsState({
    required this.settings,
    this.status = const ServerStatus.unknown(),
    this.sources = const [],
    this.checking = false,
    this.message,
    this.httpWarning = false,
    this.checkedUrl,
  });

  final AppSettings settings;
  final ServerStatus status;
  final List<SourceInfo> sources;
  final bool checking;
  final String? message;
  final bool httpWarning;
  final String? checkedUrl;

  SettingsState copyWith({
    AppSettings? settings,
    ServerStatus? status,
    List<SourceInfo>? sources,
    bool? checking,
    Object? message = _sentinel,
    bool? httpWarning,
    Object? checkedUrl = _sentinel,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
      sources: sources ?? this.sources,
      checking: checking ?? this.checking,
      message: message == _sentinel ? this.message : message as String?,
      httpWarning: httpWarning ?? this.httpWarning,
      checkedUrl: checkedUrl == _sentinel
          ? this.checkedUrl
          : checkedUrl as String?,
    );
  }
}

const _sentinel = Object();
