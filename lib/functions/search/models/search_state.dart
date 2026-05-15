import '../../../core/models/server_status.dart';
import '../../../core/models/source_info.dart';
import '../../../core/models/track.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.selectedSourceIds = const [],
    this.availableSources = const [],
    this.localMatches = const [],
    this.streamedResults = const [],
    this.warnings = const [],
    this.isSearching = false,
    this.error,
    this.status = const ServerStatus.unknown(),
  });

  final String query;
  final List<String> selectedSourceIds;
  final List<SourceInfo> availableSources;
  final List<Track> localMatches;
  final List<Track> streamedResults;
  final List<String> warnings;
  final bool isSearching;
  final String? error;
  final ServerStatus status;

  bool get hasBackend => status.isConnected;
  List<Track> get allResults => [...localMatches, ...streamedResults];

  SearchState copyWith({
    String? query,
    List<String>? selectedSourceIds,
    List<SourceInfo>? availableSources,
    List<Track>? localMatches,
    List<Track>? streamedResults,
    List<String>? warnings,
    bool? isSearching,
    Object? error = _sentinel,
    ServerStatus? status,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedSourceIds: selectedSourceIds ?? this.selectedSourceIds,
      availableSources: availableSources ?? this.availableSources,
      localMatches: localMatches ?? this.localMatches,
      streamedResults: streamedResults ?? this.streamedResults,
      warnings: warnings ?? this.warnings,
      isSearching: isSearching ?? this.isSearching,
      error: error == _sentinel ? this.error : error as String?,
      status: status ?? this.status,
    );
  }
}

const _sentinel = Object();
