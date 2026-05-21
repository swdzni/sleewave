import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/models/track.dart';
import '../../../core/network/api_exception.dart';
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
  _SearchKey? _lastExecutedSearch;
  bool _lastSearchMissedBackend = false;
  int? _ignoredLibraryRevision;
  SearchState _state = const SearchState();

  SearchState get state => _state;

  void loadSources() {
    final sources = _startup.sources;
    final searchableIds = sources
        .where((source) => source.canSearch)
        .map((source) => source.id)
        .toList();
    final savedSelected = searchableIds
        .where(_theme.settings.selectedSourceIds.contains)
        .toList();
    final selected = savedSelected.length == searchableIds.length
        ? const <String>[]
        : savedSelected;
    _state = _state.copyWith(
      availableSources: sources,
      selectedSourceIds: selected,
      status: _startup.status,
    );
    notifyListeners();
  }

  Future<void> refreshFromStartup({bool rerunSearch = false}) async {
    final previousStatus = _state.status;
    loadSources();
    if (rerunSearch &&
        _state.query.trim().isNotEmpty &&
        !previousStatus.isConnected &&
        _startup.status.isConnected) {
      await searchNow(force: true);
    }
  }

  void setQuery(String query) {
    if (query == _state.query) {
      return;
    }
    _state = _state.copyWith(query: query, error: null);
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () => searchNow());
  }

  Future<void> toggleSource(String sourceId) async {
    final source = _state.availableSources
        .where((candidate) => candidate.id == sourceId)
        .firstOrNull;
    if (source == null || !source.canSearch) {
      return;
    }
    final selected = _state.selectedSourceIds.isEmpty
        ? <String>[]
        : [..._state.selectedSourceIds];
    if (selected.contains(sourceId)) {
      selected.remove(sourceId);
    } else {
      selected.add(sourceId);
    }
    final normalizedSelected = _normalizeSelectedSources(selected);
    _state = _state.copyWith(selectedSourceIds: normalizedSelected);
    await _saveSelectedSources(normalizedSelected);
    notifyListeners();
    if (_state.query.trim().isNotEmpty) {
      await searchNow(force: true);
    }
  }

  Future<void> selectAllSources() async {
    if (_state.selectedSourceIds.isEmpty) {
      return;
    }
    _state = _state.copyWith(selectedSourceIds: const []);
    await _saveSelectedSources(const []);
    notifyListeners();
    if (_state.query.trim().isNotEmpty) {
      await searchNow(force: true);
    }
  }

  Future<void> searchNow({bool force = false}) async {
    _debounce?.cancel();
    _cancelToken?.cancel();
    final query = _state.query.trim();
    if (query.isEmpty) {
      _lastExecutedSearch = null;
      _state = _state.copyWith(
        localMatches: const [],
        streamedResults: const [],
        isSearching: false,
        error: null,
      );
      notifyListeners();
      return;
    }
    final searchKey = _SearchKey(query, _state.effectiveSourceIds());
    final canRecoverBackendSearch =
        force && _lastSearchMissedBackend && _startup.status.isConnected;
    if (searchKey == _lastExecutedSearch && !canRecoverBackendSearch) {
      return;
    }
    _lastExecutedSearch = searchKey;
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
    if (backend == null || !_startup.status.isConnected) {
      _lastSearchMissedBackend = true;
      _state = _state.copyWith(isSearching: false, error: null);
      notifyListeners();
      return;
    }
    _lastSearchMissedBackend = false;
    _cancelToken = CancelToken();
    _state = _state.copyWith(isSearching: true);
    notifyListeners();
    try {
      _loadSavedSongsFirst(query);
      await for (final event in backend.search(
        query: query,
        sourceIds: searchKey.sourceIds,
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
      final message = error is ApiException
          ? error.message
          : 'Online Library search failed.';
      _lastSearchMissedBackend = true;
      _state = _state.copyWith(
        isSearching: false,
        error: _state.localMatches.isEmpty ? message : null,
        warnings: _state.localMatches.isEmpty
            ? _state.warnings
            : {..._state.warnings, 'Online Library unavailable.'}.toList(),
      );
      notifyListeners();
    }
  }

  void cancelSearch() {
    _cancelToken?.cancel();
    _state = _state.copyWith(isSearching: false);
    notifyListeners();
  }

  Future<void> playTrack(Track track) {
    return _ref
        .read(playerViewModelProvider)
        .play(track, queue: _state.allResults);
  }

  Future<void> downloadTrack(Track track) async {
    final backend = _ref.read(backendRepositoryProvider);
    if (backend == null || !_startup.status.isConnected) {
      _state = _state.copyWith(error: 'Connect Online Library to download.');
      notifyListeners();
      return;
    }
    if (track.resultId == null) {
      _state = _state.copyWith(error: 'Refresh this track before download.');
      notifyListeners();
      return;
    }
    try {
      final updated = await _downloads.download(
        track: track,
        backend: backend,
        settings: _theme.settings,
      );
      if (updated != null) {
        _state = _state.copyWith(
          localMatches: _replaceTrack(_state.localMatches, updated),
          streamedResults: _replaceTrack(_state.streamedResults, updated),
        );
      }
      _state = _state.copyWith(error: null);
      _ignoredLibraryRevision =
          _ref.read(libraryRevisionProvider.notifier).state + 1;
      notifyLibraryChanged(_ref);
      notifyListeners();
    } on ApiException catch (error) {
      await _refreshBackendIfTrackExpired(error);
      _state = _state.copyWith(error: error.message);
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(error: 'Download failed. Try again.');
      notifyListeners();
    }
  }

  Future<void> deleteTrack(Track track) async {
    await _tracks.deleteLocalState(track);
    final updated = await _tracks.byId(track.id);
    _state = updated == null
        ? _state.copyWith(
            localMatches: _removeTrack(_state.localMatches, track),
            streamedResults: _removeTrack(_state.streamedResults, track),
          )
        : _state.copyWith(
            localMatches: _replaceTrack(_state.localMatches, updated),
            streamedResults: _replaceTrack(_state.streamedResults, updated),
          );
    notifyLibraryChanged(_ref);
    notifyListeners();
  }

  Future<void> _refreshBackendIfTrackExpired(ApiException error) async {
    if (!error.needsTrackRefresh) {
      return;
    }
    await _startup.refreshBackend(keepConnectedStatus: true);
  }

  Future<void> shareTrack(Track track) async {
    try {
      await _ref
          .read(trackShareServiceProvider)
          .share(
            track: track,
            settings: _theme.settings,
            backend: _ref.read(backendRepositoryProvider),
          );
      _state = _state.copyWith(error: null);
      notifyListeners();
    } on ApiException catch (error) {
      await _refreshBackendIfTrackExpired(error);
      _state = _state.copyWith(error: error.message);
      notifyListeners();
    } catch (error) {
      _state = _state.copyWith(error: error.toString());
      notifyListeners();
    }
  }

  Future<void> deleteFromServer(Track track) async {
    final backend = _ref.read(backendRepositoryProvider);
    final resultId = track.resultId;
    if (backend == null || resultId == null || !_startup.status.isConnected) {
      _state = _state.copyWith(error: 'Connect Online Library first.');
      notifyListeners();
      return;
    }
    try {
      final result = await backend.deleteTrack(resultId);
      final updated = await _tracks.markServerRemoved(track);
      _state = updated == null
          ? _state.copyWith(
              localMatches: _removeTrack(_state.localMatches, track),
              streamedResults: _removeTrack(_state.streamedResults, track),
              error: null,
            )
          : _state.copyWith(
              localMatches: _replaceTrack(_state.localMatches, updated),
              streamedResults: _replaceTrack(_state.streamedResults, updated),
              error: null,
            );
      await _startup.refreshBackend(keepConnectedStatus: true);
      _state = _state.copyWith(error: result.message);
      notifyLibraryChanged(_ref);
      notifyListeners();
    } on ApiException catch (error) {
      await _refreshBackendIfTrackExpired(error);
      _state = _state.copyWith(error: error.message);
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(error: 'Could not delete from server.');
      notifyListeners();
    }
  }

  Future<void> toggleLike(Track track) async {
    final updated = await _tracks.toggleLike(track);
    _state = _state.copyWith(
      localMatches: _replaceTrack(_state.localMatches, updated),
      streamedResults: _replaceTrack(_state.streamedResults, updated),
    );
    _ref.read(playbackServiceProvider).replaceCurrentTrack(updated);
    notifyLibraryChanged(_ref);
    notifyListeners();
  }

  Future<void> refreshVisibleTracks() async {
    _state = _state.copyWith(
      localMatches: await _hydrateVisibleTracks(_state.localMatches),
      streamedResults: await _hydrateVisibleTracks(_state.streamedResults),
    );
    notifyListeners();
  }

  bool shouldIgnoreLibraryRevision(int? previous, int next) {
    if (_ignoredLibraryRevision == next) {
      _ignoredLibraryRevision = null;
      return true;
    }
    return false;
  }

  void _loadSavedSongsFirst(String query) {
    for (final song in _startup.savedSongs.where(
      (track) => _matchesQuery(track, query),
    )) {
      _state = _state.copyWith(
        streamedResults: _searchService.mergeResults(
          existing: _state.streamedResults,
          incoming: song,
        ),
      );
      notifyListeners();
    }
  }

  bool _matchesQuery(Track track, String query) {
    final normalized = query.toLowerCase();
    return track.title.toLowerCase().contains(normalized) ||
        track.artist.toLowerCase().contains(normalized) ||
        (track.album?.toLowerCase().contains(normalized) ?? false);
  }

  List<Track> _replaceTrack(List<Track> tracks, Track updated) {
    return [
      for (final track in tracks) track.id == updated.id ? updated : track,
    ];
  }

  List<Track> _removeTrack(List<Track> tracks, Track removed) {
    return [
      for (final track in tracks)
        if (track.id != removed.id) track,
    ];
  }

  Future<List<Track>> _hydrateVisibleTracks(List<Track> tracks) async {
    final hydrated = <Track>[];
    for (final track in tracks) {
      hydrated.add(await _tracks.byId(track.id) ?? track);
    }
    return hydrated;
  }

  Future<void> _saveSelectedSources(List<String> selected) async {
    await _theme.saveSettings(
      _theme.settings.copyWith(selectedSourceIds: selected),
    );
  }

  List<String> _normalizeSelectedSources(List<String> selected) {
    final searchableIds = _state.availableSources
        .where((source) => source.canSearch)
        .map((source) => source.id)
        .toList();
    final normalized = [
      for (final id in searchableIds)
        if (selected.contains(id)) id,
    ];
    return normalized.length == searchableIds.length ? const [] : normalized;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}

final searchViewModelProvider =
    ChangeNotifierProvider.autoDispose<SearchViewModel>((ref) {
      final vm = SearchViewModel(
        tracks: ref.read(trackRepositoryProvider),
        searchService: ref.read(searchServiceProvider),
        startup: ref.read(appStartupControllerProvider),
        theme: ref.read(themeControllerProvider),
        downloads: ref.read(downloadServiceProvider),
        ref: ref,
      );
      ref.listen<AppStartupController>(appStartupControllerProvider, (
        previous,
        next,
      ) {
        vm.refreshFromStartup(rerunSearch: next.status.isConnected);
      });
      ref.listen<int>(libraryRevisionProvider, (previous, next) {
        if (vm.shouldIgnoreLibraryRevision(previous, next)) {
          return;
        }
        if (vm.state.query.trim().isNotEmpty) {
          vm.refreshVisibleTracks();
        }
      });
      return vm;
    });

class _SearchKey {
  _SearchKey(String query, List<String> sourceIds)
    : query = query.trim(),
      sourceIds = List.unmodifiable(sourceIds);

  final String query;
  final List<String> sourceIds;

  @override
  bool operator ==(Object other) {
    return other is _SearchKey &&
        other.query == query &&
        const ListEquality<String>().equals(other.sourceIds, sourceIds);
  }

  @override
  int get hashCode =>
      Object.hash(query, const ListEquality<String>().hash(sourceIds));
}
