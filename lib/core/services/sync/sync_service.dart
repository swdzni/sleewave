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
    final local = await _tracks.backendLinkedLocalTracks();
    final resultIds = [
      for (final track in local)
        if (track.resultId != null) track.resultId!,
    ];
    try {
      await backend.syncDeviceLibrary(
        deviceId: settings.deviceId,
        resultIds: resultIds,
      );
    } on ApiException {
      await _queue(
        type: 'syncDeviceLibrary',
        payload: {'device_id': settings.deviceId, 'result_ids': resultIds},
      );
    }
  }

  Future<void> queueConfirm({
    required String deviceId,
    required String resultId,
  }) {
    return _queue(
      type: 'confirmDownload',
      payload: {'device_id': deviceId, 'result_id': resultId},
    );
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
          final resultId = payload['result_id'] as String?;
          if (resultId == null || resultId.isEmpty) {
            await (_db.delete(
              _db.pendingActions,
            )..where((table) => table.id.equals(action.id))).go();
            continue;
          }
          await backend.confirmDownload(
            deviceId: payload['device_id'] as String,
            resultId: resultId,
          );
        } else if (action.type == 'syncDeviceLibrary') {
          final resultIds =
              (payload['result_ids'] as List?)
                  ?.map((value) => '$value')
                  .toList() ??
              const <String>[];
          await backend.syncDeviceLibrary(
            deviceId: payload['device_id'] as String,
            resultIds: resultIds,
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
