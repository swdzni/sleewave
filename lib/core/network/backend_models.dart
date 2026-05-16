import '../models/track.dart';

sealed class SearchEvent {
  const SearchEvent();
}

class SearchStarted extends SearchEvent {
  const SearchStarted({
    required this.query,
    required this.sources,
    required this.emitted,
  });

  final String query;
  final List<String> sources;
  final int emitted;
}

class SearchTrackFound extends SearchEvent {
  SearchTrackFound({
    required this.sourceId,
    required this.track,
    required this.emitted,
  });

  factory SearchTrackFound.fromJson(Map<String, dynamic> json) {
    final trackJson = Map<String, dynamic>.from(json['track'] as Map);
    final source = json['source'] as String?;
    final resultId = trackJson['result_id'] as String?;
    return SearchTrackFound(
      sourceId: source,
      track: Track.remoteFromJson(
        trackJson,
        id: resultId ?? '',
        sourceId: source,
      ),
      emitted: (json['emitted'] as num?)?.round() ?? 0,
    );
  }

  final String? sourceId;
  final Track track;
  final int emitted;
}

class SearchWarning extends SearchEvent {
  const SearchWarning({
    required this.sourceId,
    required this.message,
    required this.emitted,
  });

  final String? sourceId;
  final String message;
  final int emitted;
}

class SearchDone extends SearchEvent {
  const SearchDone({required this.emitted});

  final int emitted;
}

class DownloadResponse {
  const DownloadResponse({required this.bytes, this.filename});

  final List<int> bytes;
  final String? filename;
}

class CacheCleanupResult {
  const CacheCleanupResult({
    required this.deletedCount,
    required this.trackCatalogCleared,
    required this.deviceLibraryCleared,
  });

  factory CacheCleanupResult.fromJson(Map<String, dynamic> json) {
    return CacheCleanupResult(
      deletedCount: (json['deleted_count'] as num?)?.round() ?? 0,
      trackCatalogCleared: json['track_catalog_cleared'] == true,
      deviceLibraryCleared: json['device_library_cleared'] == true,
    );
  }

  final int deletedCount;
  final bool trackCatalogCleared;
  final bool deviceLibraryCleared;
}
