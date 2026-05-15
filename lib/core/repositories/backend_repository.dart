import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

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
  final _uuid = const Uuid();

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

  Future<List<Track>> getSavedSongs() async {
    final json = await _apiClient.getJson(ApiPaths.savedSongs);
    return (json['songs'] as List? ?? const [])
        .map(
          (item) => Track.remoteFromJson(
            Map<String, dynamic>.from(item as Map),
            id: _uuid.v4(),
          ),
        )
        .toList();
  }

  Uri getStreamUrl(String resultId) {
    return _apiClient.buildUri(ApiPaths.stream(resultId));
  }

  Future<void> prepareStream(String resultId) async {
    final response = await _apiClient.postStream(ApiPaths.stream(resultId));
    await response.data?.stream.listen(null).cancel();
  }

  Future<Response<ResponseBody>> openStream(String resultId) {
    return _apiClient.postStream(ApiPaths.stream(resultId));
  }

  Future<void> streamTrackPost(String resultId) async {
    await _apiClient.postBytes(ApiPaths.stream(resultId));
  }

  Future<DownloadResponse> downloadTrack({
    required String resultId,
    required String deviceId,
    ProgressCallback? onProgress,
  }) async {
    final response = await _apiClient.postBytes(
      ApiPaths.download(resultId),
      queryParameters: {'device_id': deviceId},
      onReceiveProgress: onProgress,
    );
    return DownloadResponse(
      bytes: response.data ?? const [],
      filename: _filenameFromHeader(
        response.headers.value('content-disposition'),
      ),
    );
  }

  Future<void> syncDeviceLibrary({
    required String deviceId,
    required List<Track> tracks,
  }) async {
    await _apiClient.postJson(
      ApiPaths.deviceLibrarySync,
      data: {
        'device_id': deviceId,
        'tracks': [
          for (final track in tracks)
            {'track_key': track.trackKey, 'base_track_key': track.baseTrackKey},
        ],
      },
    );
  }

  Future<void> confirmDownload({
    required String deviceId,
    String? trackKey,
    String? baseTrackKey,
    String? resultId,
  }) async {
    final payload = <String, dynamic>{'device_id': deviceId};
    if (trackKey != null && baseTrackKey != null) {
      payload['track_key'] = trackKey;
      payload['base_track_key'] = baseTrackKey;
    } else if (resultId != null) {
      payload['result_id'] = resultId;
    }
    await _apiClient.postJson(ApiPaths.confirmDownload, data: payload);
  }

  String? _filenameFromHeader(String? header) {
    if (header == null) {
      return null;
    }
    final match = RegExp('filename="([^"]+)"').firstMatch(header);
    return match?.group(1);
  }
}
