import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as p;

import 'file_storage_service.dart';

class LocalAudioMetadata {
  const LocalAudioMetadata({
    this.title,
    this.artist,
    this.album,
    this.durationSeconds,
    this.coverPath,
  });

  final String? title;
  final String? artist;
  final String? album;
  final int? durationSeconds;
  final String? coverPath;
}

class MetadataService {
  MetadataService(this._storage);

  final FileStorageService _storage;

  Future<LocalAudioMetadata> read(File file) async {
    try {
      final metadata = readMetadata(file, getImage: true);
      String? coverPath;
      if (metadata.pictures.isNotEmpty) {
        final picture = metadata.pictures.first;
        final extension = picture.mimetype.contains('png') ? 'png' : 'jpg';
        final coverFile = File(
          p.join(
            _storage.folders.covers.path,
            '${DateTime.now().microsecondsSinceEpoch}.$extension',
          ),
        );
        await coverFile.writeAsBytes(picture.bytes, flush: true);
        coverPath = coverFile.path;
      }
      return LocalAudioMetadata(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        durationSeconds: metadata.duration?.inSeconds,
        coverPath: coverPath,
      );
    } catch (_) {
      return const LocalAudioMetadata();
    }
  }
}
