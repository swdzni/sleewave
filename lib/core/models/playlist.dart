import '../constants/app_constants.dart';

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.coverPath,
    this.specialType,
    required this.createdAt,
    required this.updatedAt,
    this.trackCount = 0,
  });

  final String id;
  final String name;
  final String? coverPath;
  final String? specialType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int trackCount;

  bool get isFavorite => specialType == AppConstants.favoritePlaylistId;

  Playlist copyWith({
    String? id,
    String? name,
    Object? coverPath = _sentinel,
    Object? specialType = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? trackCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPath: coverPath == _sentinel ? this.coverPath : coverPath as String?,
      specialType: specialType == _sentinel
          ? this.specialType
          : specialType as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trackCount: trackCount ?? this.trackCount,
    );
  }
}

const _sentinel = Object();
