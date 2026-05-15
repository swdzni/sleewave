import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/track.dart';
import '../services/files/file_storage_service.dart';
import '../services/files/metadata_service.dart';
import 'track_repository.dart';

class LibraryRepository {
  LibraryRepository(this._tracks, this._storage, this._metadata);

  final TrackRepository _tracks;
  final FileStorageService _storage;
  final MetadataService _metadata;
  final _uuid = const Uuid();

  Future<void> scanLocalLibrary() async {
    await _tracks.removeMissingLocalPaths();
    final imported = await _storage.importedFiles();
    final existing = await _tracks.importedTracks();
    final existingPaths = existing.map((track) => track.localPath).toSet();
    for (final file in imported) {
      if (!existingPaths.contains(file.path)) {
        await _importCopiedFile(file);
      }
    }
  }

  Future<List<Track>> importFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg'],
    );
    if (result == null) {
      return const [];
    }
    final imported = <Track>[];
    for (final picked in result.files) {
      final path = picked.path;
      if (path == null) {
        continue;
      }
      final copied = await _storage.copyIntoImported(File(path));
      imported.add(await _importCopiedFile(copied));
    }
    return imported;
  }

  Future<Track> _importCopiedFile(File file) async {
    final metadata = await _metadata.read(file);
    final now = DateTime.now();
    final fallbackTitle = p.basenameWithoutExtension(file.path);
    final track = Track(
      id: _uuid.v4(),
      title: metadata.title?.trim().isNotEmpty == true
          ? metadata.title!.trim()
          : fallbackTitle,
      artist: metadata.artist?.trim().isNotEmpty == true
          ? metadata.artist!.trim()
          : AppConstants.unknownArtist,
      album: metadata.album,
      durationSeconds: metadata.durationSeconds,
      localCoverPath: metadata.coverPath,
      localPath: file.path,
      localOrigin: AppConstants.localOriginImported,
      createdAt: now,
      updatedAt: now,
    );
    return _tracks.upsert(track);
  }
}
