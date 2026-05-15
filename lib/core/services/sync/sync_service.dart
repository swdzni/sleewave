import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../models/app_settings.dart';
import '../../network/api_exception.dart';
import '../../repositories/backend_repository.dart';
import '../../repositories/track_repository.dart';

class SyncService {
  SyncService(this._db, this._tracks);

  final AppDatabase _db;
  final TrackRepository _tracks;
  final _uuid = const Uuid();

  Future<void> syncDeviceLibrary(
    BackendRepository backend,
    AppSettings settings,
  ) async {
    final local = await _tracks.backendKeyedLocalTracks();
    try {
      await backend.syncDeviceLibrary(
        deviceId: settings.deviceId,
        tracks: local,
      );
    } on ApiException {
      await _queue(
        type: 'syncDeviceLibrary',
        payload: {
          'device_id': settings.deviceId,
          'tracks': [
            for (final track in local)
              {
                'track_key': track.trackKey,
                'base_track_key': track.baseTrackKey,
              },
          ],
        },
      );
    }
  }

  Future<void> queueConfirm({
    required String deviceId,
    String? trackKey,
    String? baseTrackKey,
    String? resultId,
  }) {
    final payload = <String, dynamic>{'device_id': deviceId};
    if (trackKey != null) {
      payload['track_key'] = trackKey;
    }
    if (baseTrackKey != null) {
      payload['base_track_key'] = baseTrackKey;
    }
    if (resultId != null) {
      payload['result_id'] = resultId;
    }
    return _queue(type: 'confirmDownload', payload: payload);
  }

  Future<void> retryPending(BackendRepository backend) async {
    final actions = await (_db.select(
      _db.pendingActions,
    )..orderBy([(table) => OrderingTerm.asc(table.createdAt)])).get();
    var attempts = 0;
    for (final action in actions) {
      if (attempts >= 3) {
        break;
      }
      attempts += 1;
      try {
        final payload = jsonDecode(action.payloadJson) as Map<String, dynamic>;
        if (action.type == 'confirmDownload') {
          await backend.confirmDownload(
            deviceId: payload['device_id'] as String,
            trackKey: payload['track_key'] as String?,
            baseTrackKey: payload['base_track_key'] as String?,
            resultId: payload['result_id'] as String?,
          );
        } else if (action.type == 'syncDeviceLibrary') {
          await backend.syncDeviceLibrary(
            deviceId: payload['device_id'] as String,
            tracks: const [],
          );
        }
        await (_db.delete(
          _db.pendingActions,
        )..where((table) => table.id.equals(action.id))).go();
      } catch (_) {
        await (_db.update(
          _db.pendingActions,
        )..where((table) => table.id.equals(action.id))).write(
          PendingActionsCompanion(
            attemptCount: Value(action.attemptCount + 1),
            lastAttemptAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  Future<void> _queue({
    required String type,
    required Map<String, dynamic> payload,
  }) {
    final now = DateTime.now();
    return _db
        .into(_db.pendingActions)
        .insert(
          PendingActionsCompanion.insert(
            id: _uuid.v4(),
            type: type,
            payloadJson: jsonEncode(payload),
            createdAt: now,
          ),
        );
  }
}
