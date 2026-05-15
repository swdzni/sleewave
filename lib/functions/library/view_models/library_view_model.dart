import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/track.dart';
import '../../../core/providers.dart';
import '../../../core/repositories/library_repository.dart';
import '../../../core/repositories/track_repository.dart';
import '../../../core/services/files/file_storage_service.dart';
import '../../../core/utils/safe_change_notifier.dart';
import '../../player/view_models/player_view_model.dart';
import '../models/library_state.dart';

class LibraryViewModel extends SafeChangeNotifier {
  LibraryViewModel(this._tracks, this._library, this._storage, this._ref);

  final TrackRepository _tracks;
  final LibraryRepository _library;
  final FileStorageService _storage;
  final Ref _ref;
  LibraryState _state = const LibraryState();

  LibraryState get state => _state;

  Future<void> load() async {
    await _library.scanLocalLibrary();
    _state = LibraryState(
      loading: false,
      folderPath: _storage.folders.root.path,
      downloaded: await _tracks.downloadedTracks(),
      imported: await _tracks.importedTracks(),
    );
    notifyListeners();
  }

  Future<void> importFiles() async {
    await _library.importFiles();
    notifyLibraryChanged(_ref);
    await load();
  }

  Future<void> deleteTrack(Track track) async {
    await _tracks.deleteLocalState(track);
    notifyLibraryChanged(_ref);
    await load();
  }

  Future<Track> toggleLike(Track track) async {
    final updated = await _tracks.toggleLike(track);
    _state = LibraryState(
      loading: _state.loading,
      folderPath: _state.folderPath,
      downloaded: _replaceTrack(_state.downloaded, updated),
      imported: _replaceTrack(_state.imported, updated),
    );
    notifyListeners();
    notifyLibraryChanged(_ref);
    return updated;
  }

  Future<void> play(Track track) =>
      _ref.read(playerViewModelProvider).play(track);

  List<Track> _replaceTrack(List<Track> tracks, Track updated) {
    return [
      for (final track in tracks) track.id == updated.id ? updated : track,
    ];
  }
}

final libraryViewModelProvider =
    ChangeNotifierProvider.autoDispose<LibraryViewModel>((ref) {
      final vm = LibraryViewModel(
        ref.read(trackRepositoryProvider),
        ref.read(libraryRepositoryProvider),
        ref.read(fileStorageProvider),
        ref,
      );
      ref.listen<int>(libraryRevisionProvider, (previous, next) {
        vm.load();
      });
      return vm;
    });
