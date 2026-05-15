import 'package:uuid/uuid.dart';

import '../../models/app_settings.dart';
import '../../models/track.dart';
import '../../network/api_exception.dart';
import '../../repositories/backend_repository.dart';
import '../../repositories/track_repository.dart';
import '../../utils/safe_change_notifier.dart';
import '../files/file_storage_service.dart';
import '../sync/sync_service.dart';

class DownloadService extends SafeChangeNotifier {
  DownloadService(this._storage, this._tracks, this._sync);

  final FileStorageService _storage;
  final TrackRepository _tracks;
  final SyncService _sync;
  final _uuid = const Uuid();
  final Map<String, double> _progress = {};
  final Set<String> _active = {};

  Map<String, double> get progress => Map.unmodifiable(_progress);

  Future<void> download({
    required Track track,
    required BackendRepository backend,
    required AppSettings settings,
  }) async {
    if (track.resultId == null || _active.contains(track.id)) {
      return;
    }
    _active.add(track.id);
    _progress[track.id] = 0;
    notifyListeners();
    try {
      final response = await backend.downloadTrack(
        resultId: track.resultId!,
        deviceId: settings.deviceId,
        onProgress: (received, total) {
          if (total > 0) {
            _progress[track.id] = received / total;
            notifyListeners();
          }
        },
      );
      final temp = await _storage.writeTempBytes(
        response.bytes,
        '${_uuid.v4()}.mp3',
      );
      final finalFile = await _storage.moveTempToDownloads(
        tempFile: temp,
        artist: track.displayArtist,
        title: track.title,
      );
      await _tracks.markDownloaded(track: track, localPath: finalFile.path);
      try {
        await backend.confirmDownload(
          deviceId: settings.deviceId,
          trackKey: track.trackKey,
          baseTrackKey: track.baseTrackKey,
          resultId: track.resultId,
        );
      } catch (_) {
        await _sync.queueConfirm(
          deviceId: settings.deviceId,
          trackKey: track.trackKey,
          baseTrackKey: track.baseTrackKey,
          resultId: track.resultId,
        );
      }
    } on ApiException catch (error) {
      if (error.code == 'track_already_on_device') {
        await _tracks.markDownloaded(
          track: track,
          localPath: track.localPath ?? '',
        );
      } else {
        rethrow;
      }
    } finally {
      _active.remove(track.id);
      _progress.remove(track.id);
      notifyListeners();
    }
  }
}
