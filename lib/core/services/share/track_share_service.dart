import 'dart:io';

import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../models/app_settings.dart';
import '../../models/track.dart';
import '../../network/api_exception.dart';
import '../../repositories/backend_repository.dart';
import '../files/file_storage_service.dart';

class TrackShareService {
  TrackShareService(this._storage);

  final FileStorageService _storage;
  final _uuid = const Uuid();

  Future<void> share({
    required Track track,
    required AppSettings settings,
    BackendRepository? backend,
  }) async {
    final localPath = track.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (await file.exists()) {
        await _shareFile(file, track);
        return;
      }
    }

    final resultId = track.resultId;
    if (backend == null || resultId == null) {
      throw const TrackShareException(
        'Download this track or connect Online Library to share it.',
      );
    }

    try {
      final response = await backend.downloadTrack(
        resultId: resultId,
        deviceId: settings.deviceId,
      );
      final filename = response.filename ?? _shareFilename(track);
      final file = await _storage.writeTempBytes(
        response.bytes,
        '${_uuid.v4()}-${_storage.sanitizeFilename(filename)}',
      );
      await _shareFile(file, track);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const TrackShareException('Could not prepare this track to share.');
    }
  }

  Future<void> _shareFile(File file, Track track) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'audio/mpeg')],
        subject: track.title,
        text: '${track.displayArtist} - ${track.title}',
      ),
    );
  }

  String _shareFilename(Track track) {
    return '${track.displayArtist} - ${track.title}.mp3';
  }
}

class TrackShareException implements Exception {
  const TrackShareException(this.message);

  final String message;

  @override
  String toString() => message;
}
