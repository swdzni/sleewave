import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/api_paths.dart';
import '../models/source_info.dart';
import '../models/track.dart';
import '../network/api_client.dart';
import '../network/backend_models.dart';
import '../network/sse_client.dart';

class BackendRepository {
  BackendRepository(this._apiClient) : _sseClient = SseClient(_apiClient.dio);

  final ApiClient _apiClient;
  final SseClient _sseClient;

  Uri streamUri(String resultId, {bool directUrl = false}) {
    return _apiClient.uri(
      ApiPaths.stream(resultId),
      queryParameters: directUrl ? const {'direct_url': true} : null,
    );
  }

  Future<bool> checkHealth() async {
    final json = await _apiClient.getJson(ApiPaths.health);
    return json['status'] == 'ok';
  }

  Future<List<SourceInfo>> getSources() async {
    final json = await _apiClient.getJson(ApiPaths.sources);
    return (json['sources'] as List? ?? const [])
        .map(
          (item) => SourceInfo.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Stream<SearchEvent> search({
    required String query,
    required List<String> sourceIds,
    required int limit,
    int offset = 0,
    required String deviceId,
    CancelToken? cancelToken,
  }) {
    return _sseClient.search(
      query: query,
      sourceIds: sourceIds,
      limit: limit,
      offset: offset,
      deviceId: deviceId,
      cancelToken: cancelToken,
    );
  }

  Future<SavedSongsPage> getSavedSongsPage({
    int limit = 50,
    int offset = 0,
  }) async {
    return SavedSongsPage.fromJson(
      await _apiClient.getJson(
        ApiPaths.savedSongs,
        queryParameters: {'limit': limit, 'offset': offset},
      ),
    );
  }

  Future<List<Track>> getSavedSongs({int pageSize = 50}) async {
    final songs = <Track>[];
    var offset = 0;
    while (true) {
      final page = await getSavedSongsPage(limit: pageSize, offset: offset);
      songs.addAll(page.songs);
      if (!page.hasMore || page.count == 0) {
        return songs;
      }
      offset += page.count;
    }
  }

  Future<Response<ResponseBody>> openStream(
    String resultId, {
    int? start,
    int? end,
    bool directUrl = false,
  }) {
    final range = _rangeHeader(start, end);
    return _apiClient.getStream(
      ApiPaths.stream(resultId),
      queryParameters: directUrl ? const {'direct_url': true} : null,
      headers: range == null ? null : {'Range': range},
    );
  }

  Future<DownloadResponse> downloadTrack({
    required String resultId,
    required String deviceId,
    bool directUrl = false,
    ProgressCallback? onProgress,
  }) async {
    final response = await _downloadBytes(
      resultId: resultId,
      deviceId: deviceId,
      directUrl: directUrl,
      onProgress: onProgress,
    );
    final resolvedResponse = directUrl && _looksLikeHlsPlaylist(response)
        ? await _downloadBytes(
            resultId: resultId,
            deviceId: deviceId,
            onProgress: onProgress,
          )
        : response;
    return DownloadResponse(
      bytes: resolvedResponse.data ?? const [],
      filename: _filenameFromHeader(
        resolvedResponse.headers.value('content-disposition'),
      ),
    );
  }

  Future<Response<List<int>>> _downloadBytes({
    required String resultId,
    required String deviceId,
    bool directUrl = false,
    ProgressCallback? onProgress,
  }) {
    return _apiClient.getBytes(
      ApiPaths.download(resultId),
      queryParameters: {
        'device_id': deviceId,
        if (directUrl) 'direct_url': true,
      },
      onReceiveProgress: onProgress,
    );
  }

  Future<void> syncDeviceLibrary({
    required String deviceId,
    required List<String> resultIds,
  }) async {
    await _apiClient.postJson(
      ApiPaths.deviceLibrarySync,
      data: {
        'device_id': deviceId,
        'tracks': [
          for (final resultId in resultIds) {'result_id': resultId},
        ],
      },
    );
  }

  Future<void> confirmDownload({
    required String deviceId,
    required String resultId,
  }) async {
    await _apiClient.postJson(
      ApiPaths.confirmDownload,
      data: {'device_id': deviceId, 'result_id': resultId},
    );
  }

  Future<DeleteTrackResult> deleteTrack(String resultId) async {
    return DeleteTrackResult.fromJson(
      await _apiClient.deleteJson(ApiPaths.track(resultId)),
    );
  }

  Future<CacheCleanupResult> clearCache() async {
    return CacheCleanupResult.fromJson(
      await _apiClient.deleteJson(ApiPaths.cache),
    );
  }

  Future<CacheCleanupResult> clearServerTemp() async {
    return CacheCleanupResult.fromJson(
      await _apiClient.deleteJson(ApiPaths.serverTemp),
    );
  }

  String? _filenameFromHeader(String? header) {
    if (header == null) {
      return null;
    }
    final match = RegExp('filename="([^"]+)"').firstMatch(header);
    return match?.group(1);
  }

  String? _rangeHeader(int? start, int? end) {
    if (start == null && end == null) {
      return null;
    }
    final safeStart = start == null ? '' : start.clamp(0, 1 << 62);
    final inclusiveEnd = end == null ? null : end - 1;
    final safeEnd = inclusiveEnd == null ? '' : inclusiveEnd.clamp(0, 1 << 62);
    return 'bytes=$safeStart-$safeEnd';
  }

  bool _looksLikeHlsPlaylist(Response<List<int>> response) {
    final contentType = response.headers.value('content-type')?.toLowerCase();
    if (contentType != null &&
        (contentType.contains('mpegurl') ||
            contentType.contains('application/vnd.apple.mpegurl'))) {
      return true;
    }
    if (response.realUri.path.toLowerCase().endsWith('.m3u8')) {
      return true;
    }
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      return false;
    }
    final prefix = utf8.decode(bytes.take(512).toList(), allowMalformed: true);
    return prefix.trimLeft().startsWith('#EXTM3U');
  }
}
