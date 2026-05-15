import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/api_paths.dart';
import 'api_exception.dart';
import 'backend_models.dart';

class SseClient {
  const SseClient(this._dio);

  final Dio _dio;

  Stream<SearchEvent> search({
    required String query,
    required List<String> sourceIds,
    required int limit,
    required int offset,
    required String deviceId,
    CancelToken? cancelToken,
  }) async* {
    try {
      final response = await _dio.get<ResponseBody>(
        ApiPaths.search,
        queryParameters: {
          'q': query.trim(),
          if (sourceIds.isNotEmpty) 'sources': sourceIds.join(','),
          'limit': limit,
          'offset': offset,
          'device_id': deviceId,
        },
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: Duration.zero,
        ),
      );
      yield* parse(response.data!.stream);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Stream<SearchEvent> parse(Stream<List<int>> byteStream) async* {
    String? eventName;
    final dataLines = <String>[];

    await for (final line
        in utf8.decoder.bind(byteStream).transform(const LineSplitter())) {
      if (line.isEmpty) {
        final event = _decodeEvent(eventName, dataLines.join('\n'));
        if (event != null) {
          yield event;
        }
        eventName = null;
        dataLines.clear();
        continue;
      }
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    if (eventName != null || dataLines.isNotEmpty) {
      final event = _decodeEvent(eventName, dataLines.join('\n'));
      if (event != null) {
        yield event;
      }
    }
  }

  SearchEvent? _decodeEvent(String? eventName, String data) {
    if (data.isEmpty) {
      return null;
    }
    final json = jsonDecode(data) as Map<String, dynamic>;
    switch (eventName ?? json['event'] as String?) {
      case 'start':
        return SearchStarted(
          query: json['query'] as String? ?? '',
          sources: (json['sources'] as List? ?? const [])
              .map((source) => '$source')
              .toList(),
          emitted: (json['emitted'] as num?)?.round() ?? 0,
        );
      case 'track':
        return SearchTrackFound.fromJson(json);
      case 'warning':
        final warning = json['warning'];
        final warningMap = warning is Map
            ? Map<String, dynamic>.from(warning)
            : json;
        return SearchWarning(
          sourceId: (warningMap['source'] ?? json['source']) as String?,
          message: warningMap['message'] as String? ?? 'Source warning.',
          emitted: (json['emitted'] as num?)?.round() ?? 0,
        );
      case 'done':
        return SearchDone(emitted: (json['emitted'] as num?)?.round() ?? 0);
      default:
        return null;
    }
  }
}
