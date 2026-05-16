import '../../models/track.dart';

class SearchService {
  const SearchService();

  List<Track> mergeResults({
    required List<Track> existing,
    required Track incoming,
  }) {
    final next = [...existing];
    final duplicateIndex = next.indexWhere(
      (track) => _sameTrack(track, incoming),
    );
    if (duplicateIndex == -1) {
      next.add(incoming);
    } else {
      next[duplicateIndex] = _betterTrack(next[duplicateIndex], incoming);
    }
    next.sort(_priorityCompare);
    return next;
  }

  bool _sameTrack(Track a, Track b) {
    if (a.resultId != null && a.resultId == b.resultId) {
      return true;
    }
    if (a.trackKey != null && a.trackKey == b.trackKey) {
      return true;
    }
    if (a.baseTrackKey != null && a.baseTrackKey == b.baseTrackKey) {
      return true;
    }
    final durationA = a.durationSeconds;
    final durationB = b.durationSeconds;
    final sameDuration =
        durationA == null ||
        durationB == null ||
        (durationA - durationB).abs() <= 10;
    return _normalize(a.artist) == _normalize(b.artist) &&
        _normalize(a.title) == _normalize(b.title) &&
        sameDuration;
  }

  Track _betterTrack(Track current, Track incoming) {
    if (current.isLocalPlayable && !incoming.isLocalPlayable) {
      return current.copyWith(
        resultId: incoming.resultId ?? current.resultId,
        availability: incoming.availability.copyWith(onDevice: true),
        coverUrl: current.coverUrl ?? incoming.coverUrl,
      );
    }
    if (incoming.isLocalPlayable && !current.isLocalPlayable) {
      return incoming.copyWith(isLiked: current.isLiked);
    }
    final incomingRank = _rank(incoming);
    final currentRank = _rank(current);
    final preferred = incomingRank < currentRank ? incoming : current;
    final fallback = identical(preferred, incoming) ? current : incoming;
    return preferred.copyWith(
      coverUrl: preferred.coverUrl ?? fallback.coverUrl,
      durationSeconds: preferred.durationSeconds ?? fallback.durationSeconds,
      resultId: preferred.resultId ?? fallback.resultId,
      isLiked: current.isLiked || incoming.isLiked,
    );
  }

  int _priorityCompare(Track a, Track b) {
    final rank = _rank(a).compareTo(_rank(b));
    if (rank != 0) {
      return rank;
    }
    if (a.isLiked != b.isLiked) {
      return a.isLiked ? -1 : 1;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  int _rank(Track track) {
    if (track.isLocalPlayable || track.isDownloaded || track.isOnDevice) {
      return 0;
    }
    if (track.isServerCached) {
      return 1;
    }
    return 2;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
