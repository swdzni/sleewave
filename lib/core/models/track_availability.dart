enum PreferredOrigin {
  device,
  server,
  remote,
  local;

  static PreferredOrigin fromJson(Object? value) {
    return PreferredOrigin.values.firstWhere(
      (origin) => origin.name == value,
      orElse: () => PreferredOrigin.local,
    );
  }
}

class TrackAvailability {
  const TrackAvailability({
    this.inServerCache = false,
    this.onDevice = false,
    this.cacheKey,
    this.preferredOrigin = PreferredOrigin.local,
  });

  factory TrackAvailability.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TrackAvailability();
    }
    return TrackAvailability(
      inServerCache: json['in_server_cache'] == true,
      onDevice: json['on_device'] == true,
      cacheKey: json['cache_key'] as String?,
      preferredOrigin: PreferredOrigin.fromJson(json['preferred_origin']),
    );
  }

  final bool inServerCache;
  final bool onDevice;
  final String? cacheKey;
  final PreferredOrigin preferredOrigin;

  Map<String, dynamic> toJson() {
    return {
      'in_server_cache': inServerCache,
      'on_device': onDevice,
      if (cacheKey != null) 'cache_key': cacheKey,
      'preferred_origin': preferredOrigin.name,
    };
  }

  TrackAvailability copyWith({
    bool? inServerCache,
    bool? onDevice,
    Object? cacheKey = _sentinel,
    PreferredOrigin? preferredOrigin,
  }) {
    return TrackAvailability(
      inServerCache: inServerCache ?? this.inServerCache,
      onDevice: onDevice ?? this.onDevice,
      cacheKey: cacheKey == _sentinel ? this.cacheKey : cacheKey as String?,
      preferredOrigin: preferredOrigin ?? this.preferredOrigin,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TrackAvailability &&
        other.inServerCache == inServerCache &&
        other.onDevice == onDevice &&
        other.cacheKey == cacheKey &&
        other.preferredOrigin == preferredOrigin;
  }

  @override
  int get hashCode =>
      Object.hash(inServerCache, onDevice, cacheKey, preferredOrigin);
}

const _sentinel = Object();
