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
    await load();
  }

  Future<void> deleteTrack(Track track) async {
    await _tracks.deleteLocalState(track);
    await load();
  }

  Future<void> play(Track track) =>
      _ref.read(playerViewModelProvider).play(track);
}

final libraryViewModelProvider =
    ChangeNotifierProvider.autoDispose<LibraryViewModel>((ref) {
      return LibraryViewModel(
        ref.read(trackRepositoryProvider),
        ref.read(libraryRepositoryProvider),
        ref.read(fileStorageProvider),
        ref,
      );
    });
