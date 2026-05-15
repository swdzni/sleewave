import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/models/track.dart';
import '../../../core/network/backend_models.dart';
import '../../../core/providers.dart';
import '../../../core/repositories/track_repository.dart';
import '../../../core/services/downloads/download_service.dart';
import '../../../core/services/search/search_service.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/safe_change_notifier.dart';
import '../../player/view_models/player_view_model.dart';
import '../models/search_state.dart';

class SearchViewModel extends SafeChangeNotifier {
  SearchViewModel({
    required TrackRepository tracks,
    required SearchService searchService,
    required AppStartupController startup,
    required ThemeController theme,
    required DownloadService downloads,
    required Ref ref,
  }) : _tracks = tracks,
       _searchService = searchService,
       _startup = startup,
       _theme = theme,
       _downloads = downloads,
       _ref = ref {
    loadSources();
  }

  final TrackRepository _tracks;
  final SearchService _searchService;
  final AppStartupController _startup;
  final ThemeController _theme;
  final DownloadService _downloads;
  final Ref _ref;
  Timer? _debounce;
  CancelToken? _cancelToken;
  SearchState _state = const SearchState();

  SearchState get state => _state;

  void loadSources() {
    final sources = _startup.sources;
    final selected = _theme.settings.selectedSourceIds.isNotEmpty
        ? _theme.settings.selectedSourceIds
        : sources
              .where((source) => source.canSearch)
              .map((source) => source.id)
              .toList();
    _state = _state.copyWith(
      availableSources: sources,
      selectedSourceIds: selected,
      status: _startup.status,
    );
    notifyListeners();
  }

  void setQuery(String query) {
    _state = _state.copyWith(query: query, error: null);
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), searchNow);
  }

  void toggleSource(String sourceId) {
    final source = _state.availableSources
        .where((candidate) => candidate.id == sourceId)
        .firstOrNull;
    if (source == null || !source.canSearch) {
      return;
    }
    final selected = [..._state.selectedSourceIds];
    if (selected.contains(sourceId)) {
      selected.remove(sourceId);
    } else {
      selected.add(sourceId);
    }
    _state = _state.copyWith(selectedSourceIds: selected);
    notifyListeners();
    searchNow();
  }

  Future<void> searchNow() async {
    _cancelToken?.cancel();
    final query = _state.query.trim();
    if (query.isEmpty) {
      _state = _state.copyWith(
        localMatches: const [],
        streamedResults: const [],
        isSearching: false,
        error: null,
      );
      notifyListeners();
      return;
    }
    final local = await _tracks.searchLocal(query);
    _state = _state.copyWith(
      localMatches: local,
      streamedResults: const [],
      warnings: const [],
      error: null,
      status: _startup.status,
    );
    notifyListeners();

    final backend = _ref.read(backendRepositoryProvider);
    if (!_startup.status.isConnected || backend == null) {
      _state = _state.copyWith(
        isSearching: false,
        error:
            'Connect Online Library in Settings or use your offline Library.',
      );
      notifyListeners();
      return;
    }
    final sourceIds = _state.selectedSourceIds
        .where(
          (id) => _state.availableSources.any(
            (source) => source.id == id && source.canSearch,
          ),
        )
        .toList();
    if (sourceIds.isEmpty) {
      _state = _state.copyWith(error: 'Select at least one source.');
      notifyListeners();
      return;
    }
    _cancelToken = CancelToken();
    _state = _state.copyWith(isSearching: true);
    notifyListeners();
    try {
      await for (final event in backend.search(
        query: query,
        sourceIds: sourceIds,
        limit: _theme.settings.searchLimit,
        deviceId: _theme.settings.deviceId,
        cancelToken: _cancelToken,
      )) {
        switch (event) {
          case SearchStarted():
            _state = _state.copyWith(isSearching: true);
          case SearchTrackFound():
            final saved = await _tracks.mergeRemoteTrack(event.track);
            _state = _state.copyWith(
              streamedResults: _searchService.mergeResults(
                existing: _state.streamedResults,
                incoming: saved,
              ),
            );
          case SearchWarning():
            _state = _state.copyWith(
              warnings: [..._state.warnings, event.message],
            );
          case SearchDone():
            _state = _state.copyWith(isSearching: false);
        }
        notifyListeners();
      }
    } catch (error) {
      if (_cancelToken?.isCancelled == true) {
        return;
      }
      _state = _state.copyWith(isSearching: false, error: '$error');
      notifyListeners();
    }
  }

  void cancelSearch() {
    _cancelToken?.cancel();
    _state = _state.copyWith(isSearching: false);
    notifyListeners();
  }

  Future<void> playTrack(Track track) {
    return _ref.read(playerViewModelProvider).play(track);
  }

  Future<void> downloadTrack(Track track) async {
    final backend = _ref.read(backendRepositoryProvider);
    if (backend == null) {
      return;
    }
    await _downloads.download(
      track: track,
      backend: backend,
      settings: _theme.settings,
    );
  }

  Future<void> deleteTrack(Track track) => _tracks.deleteLocalState(track);
  Future<void> toggleLike(Track track) => _tracks.toggleLike(track);

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}

final searchViewModelProvider =
    ChangeNotifierProvider.autoDispose<SearchViewModel>((ref) {
      return SearchViewModel(
        tracks: ref.read(trackRepositoryProvider),
        searchService: ref.read(searchServiceProvider),
        startup: ref.read(appStartupControllerProvider),
        theme: ref.read(themeControllerProvider),
        downloads: ref.read(downloadServiceProvider),
        ref: ref,
      );
    });
