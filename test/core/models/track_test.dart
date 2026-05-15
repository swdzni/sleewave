import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/constants/app_constants.dart';
import 'package:sleewave/core/models/track.dart';

void main() {
  Track makeTrack({
    int? durationSeconds,
    String? localPath,
    String origin = AppConstants.localOriginRemoteOnly,
  }) {
    final now = DateTime(2026);
    return Track(
      id: 'track',
      title: 'Long Form',
      durationSeconds: durationSeconds,
      localPath: localPath,
      localOrigin: origin,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('detects mixes above ten minutes', () {
    expect(makeTrack(durationSeconds: 601).isMix, isTrue);
    expect(makeTrack(durationSeconds: 600).isMix, isFalse);
  });

  test('detects downloaded and local playback state', () {
    final track = makeTrack(
      localPath: '/tmp/song.mp3',
      origin: AppConstants.localOriginDownloaded,
    );

    expect(track.isDownloaded, isTrue);
    expect(track.isLocalPlayable, isTrue);
    expect(track.isOnDevice, isTrue);
  });
}
