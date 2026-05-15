class ApiPaths {
  const ApiPaths._();

  static const health = '/health';
  static const sources = '/sources';
  static const search = '/search';
  static const savedSongs = '/saved-songs';
  static const deviceLibrarySync = '/device-library/sync';
  static const confirmDownload = '/device-library/confirm-download';

  static String stream(String resultId) => '/stream/$resultId';
  static String download(String resultId) => '/download/$resultId';
}
