import '../constants/app_constants.dart';
import 'track_availability.dart';

class Track {
  const Track({
    required this.id,
    required this.title,
    this.artist = AppConstants.unknownArtist,
    this.album,
    this.durationSeconds,
    this.coverUrl,
    this.localCoverPath,
    this.sourceId,
    this.resultId,
    this.trackKey,
    this.baseTrackKey,
    this.availability = const TrackAvailability(),
    this.localPath,
    this.localOrigin = AppConstants.localOriginRemoteOnly,
    this.isLiked = false,
    this.lastPlayedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Track.remoteFromJson(
    Map<String, dynamic> json, {
    required String id,
    String? sourceId,
  }) {
    final availability = TrackAvailability.fromJson(
      json['availability'] as Map<String, dynamic>?,
    );
    final now = DateTime.now();
    return Track(
      id: id,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Untitled Track',
      artist: (json['artist'] as String?)?.trim().isNotEmpty == true
          ? (json['artist'] as String).trim()
          : AppConstants.unknownArtist,
      album: json['album'] as String?,
      durationSeconds: (json['duration'] as num?)?.round(),
      coverUrl: json['cover_url'] as String?,
      sourceId: sourceId ?? json['source'] as String?,
      resultId: json['result_id'] as String?,
      trackKey: json['track_key'] as String?,
      baseTrackKey: json['base_track_key'] as String?,
      availability: availability,
      localOrigin: availability.inServerCache
          ? AppConstants.localOriginServerCached
          : AppConstants.localOriginRemoteOnly,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String title;
  final String artist;
  final String? album;
  final int? durationSeconds;
  final String? coverUrl;
  final String? localCoverPath;
  final String? sourceId;
  final String? resultId;
  final String? trackKey;
  final String? baseTrackKey;
  final TrackAvailability availability;
  final String? localPath;
  final String localOrigin;
  final bool isLiked;
  final DateTime? lastPlayedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDownloaded =>
      localPath != null && localOrigin == AppConstants.localOriginDownloaded;
  bool get isImported =>
      localPath != null && localOrigin == AppConstants.localOriginImported;
  bool get isLocalPlayable => localPath != null;
  bool get isServerCached => availability.inServerCache;
  bool get isOnDevice => availability.onDevice || isDownloaded;
  bool get isMix => durationSeconds != null && durationSeconds! > 600;
  String get displayArtist =>
      artist.trim().isEmpty ? AppConstants.unknownArtist : artist;

  String get displayDuration {
    final seconds = durationSeconds;
    if (seconds == null) {
      return '--:--';
    }
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$secs';
    }
    return '${duration.inMinutes}:$secs';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      if (album != null) 'album': album,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (localCoverPath != null) 'localCoverPath': localCoverPath,
      if (sourceId != null) 'sourceId': sourceId,
      if (resultId != null) 'resultId': resultId,
      if (trackKey != null) 'trackKey': trackKey,
      if (baseTrackKey != null) 'baseTrackKey': baseTrackKey,
      'availability': availability.toJson(),
      if (localPath != null) 'localPath': localPath,
      'localOrigin': localOrigin,
      'isLiked': isLiked,
      if (lastPlayedAt != null) 'lastPlayedAt': lastPlayedAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    Object? album = _sentinel,
    Object? durationSeconds = _sentinel,
    Object? coverUrl = _sentinel,
    Object? localCoverPath = _sentinel,
    Object? sourceId = _sentinel,
    Object? resultId = _sentinel,
    Object? trackKey = _sentinel,
    Object? baseTrackKey = _sentinel,
    TrackAvailability? availability,
    Object? localPath = _sentinel,
    String? localOrigin,
    bool? isLiked,
    Object? lastPlayedAt = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album == _sentinel ? this.album : album as String?,
      durationSeconds: durationSeconds == _sentinel
          ? this.durationSeconds
          : durationSeconds as int?,
      coverUrl: coverUrl == _sentinel ? this.coverUrl : coverUrl as String?,
      localCoverPath: localCoverPath == _sentinel
          ? this.localCoverPath
          : localCoverPath as String?,
      sourceId: sourceId == _sentinel ? this.sourceId : sourceId as String?,
      resultId: resultId == _sentinel ? this.resultId : resultId as String?,
      trackKey: trackKey == _sentinel ? this.trackKey : trackKey as String?,
      baseTrackKey: baseTrackKey == _sentinel
          ? this.baseTrackKey
          : baseTrackKey as String?,
      availability: availability ?? this.availability,
      localPath: localPath == _sentinel ? this.localPath : localPath as String?,
      localOrigin: localOrigin ?? this.localOrigin,
      isLiked: isLiked ?? this.isLiked,
      lastPlayedAt: lastPlayedAt == _sentinel
          ? this.lastPlayedAt
          : lastPlayedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Track && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

const _sentinel = Object();
