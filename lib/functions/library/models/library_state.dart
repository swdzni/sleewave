import '../../../core/models/track.dart';

class LibraryState {
  const LibraryState({
    this.loading = true,
    this.folderPath = '',
    this.downloaded = const [],
    this.imported = const [],
  });

  final bool loading;
  final String folderPath;
  final List<Track> downloaded;
  final List<Track> imported;

  LibraryState copyWith({
    bool? loading,
    String? folderPath,
    List<Track>? downloaded,
    List<Track>? imported,
  }) {
    return LibraryState(
      loading: loading ?? this.loading,
      folderPath: folderPath ?? this.folderPath,
      downloaded: downloaded ?? this.downloaded,
      imported: imported ?? this.imported,
    );
  }
}
