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
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextOffset = 0,
    this.error,
    this.errorTitle = 'Search failed',
    this.notice,
    this.noticeTitle = 'Library updated',
    this.status = const ServerStatus.unknown(),
  });

  final String query;
  final List<String> selectedSourceIds;
  final List<SourceInfo> availableSources;
  final List<Track> localMatches;
  final List<Track> streamedResults;
  final List<String> warnings;
  final bool isSearching;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextOffset;
  final String? error;
  final String errorTitle;
  final String? notice;
  final String noticeTitle;
  final ServerStatus status;

  bool get hasBackend => status.isConnected;
  List<Track> get allResults => [...localMatches, ...streamedResults];

  List<String> effectiveSourceIds() {
    final searchable = availableSources
        .where((source) => source.canSearch)
        .map((source) => source.id)
        .toList();
    if (selectedSourceIds.isEmpty) {
      if (searchable.isEmpty) {
        return const [];
      }
      return searchable;
    }
    return selectedSourceIds.where(searchable.contains).toList();
  }

  SearchState copyWith({
    String? query,
    List<String>? selectedSourceIds,
    List<SourceInfo>? availableSources,
    List<Track>? localMatches,
    List<Track>? streamedResults,
    List<String>? warnings,
    bool? isSearching,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextOffset,
    Object? error = _sentinel,
    String? errorTitle,
    Object? notice = _sentinel,
    String? noticeTitle,
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
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      error: error == _sentinel ? this.error : error as String?,
      errorTitle: errorTitle ?? this.errorTitle,
      notice: notice == _sentinel ? this.notice : notice as String?,
      noticeTitle: noticeTitle ?? this.noticeTitle,
      status: status ?? this.status,
    );
  }
}

const _sentinel = Object();
