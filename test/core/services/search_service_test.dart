import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/constants/app_constants.dart';
import 'package:sleewave/core/models/track.dart';
import 'package:sleewave/core/models/track_availability.dart';
import 'package:sleewave/core/services/search/search_service.dart';

void main() {
  final service = SearchService();
  final now = DateTime(2026);

  Track track({
    required String id,
    bool local = false,
    bool cached = false,
    String? trackKey,
  }) {
    return Track(
      id: id,
      title: 'Same Song',
      artist: 'Same Artist',
      durationSeconds: 200,
      trackKey: trackKey,
      localPath: local ? '/tmp/local.mp3' : null,
      localOrigin: local
          ? AppConstants.localOriginDownloaded
          : AppConstants.localOriginRemoteOnly,
      availability: TrackAvailability(inServerCache: cached),
      createdAt: now,
      updatedAt: now,
    );
  }

  test('local downloaded result beats remote duplicate', () {
    final merged = service.mergeResults(
      existing: [track(id: 'local', local: true, trackKey: 'same')],
      incoming: track(id: 'remote', trackKey: 'same'),
    );

    expect(merged, hasLength(1));
    expect(merged.first.id, 'local');
    expect(merged.first.isLocalPlayable, isTrue);
  });

  test('server cached result sorts before remote result', () {
    final merged = service.mergeResults(
      existing: [track(id: 'remote')],
      incoming: track(id: 'cached', cached: true, trackKey: 'cached'),
    );

    expect(merged.first.id, 'cached');
  });
}
