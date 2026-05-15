import 'package:uuid/uuid.dart';

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
    return SearchTrackFound(
      sourceId: source,
      track: Track.remoteFromJson(
        trackJson,
        id: const Uuid().v4(),
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
