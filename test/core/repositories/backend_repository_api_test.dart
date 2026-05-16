import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/network/api_client.dart';
import 'package:sleewave/core/repositories/backend_repository.dart';

void main() {
  test('sync sends result IDs only', () async {
    late Object? sentData;
    final repository = _repository((options) {
      sentData = options.data;
      return {'device_id': 'device-one', 'track_count': 1};
    });

    await repository.syncDeviceLibrary(
      deviceId: 'device-one',
      resultIds: const ['stable-track'],
    );

    expect(sentData, {
      'device_id': 'device-one',
      'tracks': [
        {'result_id': 'stable-track'},
      ],
    });
  });

  test('confirm download sends result ID only', () async {
    late Object? sentData;
    final repository = _repository((options) {
      sentData = options.data;
      return {'registered': true};
    });

    await repository.confirmDownload(
      deviceId: 'device-one',
      resultId: 'stable-track',
    );

    expect(sentData, {'device_id': 'device-one', 'result_id': 'stable-track'});
  });

  test('saved songs use stable result ID as local identity', () async {
    final repository = _repository((options) {
      return {
        'songs': [
          {
            'title': 'Stable Song',
            'artist': 'Test Artist',
            'result_id': 'stable-track',
            'availability': {'in_server_cache': true},
          },
        ],
      };
    });

    final songs = await repository.getSavedSongs();

    expect(songs.single.id, 'stable-track');
    expect(songs.single.resultId, 'stable-track');
  });

  test('stream opens result ID with GET', () async {
    late RequestOptions sentOptions;
    final repository = _repository((options) {
      sentOptions = options;
      return ResponseBody.fromBytes(
        const [1, 2, 3],
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    await repository.openStream('stable-track');

    expect(sentOptions.method, 'GET');
    expect(sentOptions.path, '/stream/stable-track');
  });

  test('download fetches result ID with GET and device ID', () async {
    late RequestOptions sentOptions;
    final repository = _repository(
      (options) {
        sentOptions = options;
        return const [1, 2, 3];
      },
      headers: Headers.fromMap({
        'content-disposition': ['attachment; filename="Stable Song.mp3"'],
      }),
    );

    final response = await repository.downloadTrack(
      resultId: 'stable-track',
      deviceId: 'device-one',
    );

    expect(sentOptions.method, 'GET');
    expect(sentOptions.path, '/download/stable-track');
    expect(sentOptions.queryParameters, {'device_id': 'device-one'});
    expect(response.bytes, const [1, 2, 3]);
    expect(response.filename, 'Stable Song.mp3');
  });
}

BackendRepository _repository(
  Object? Function(RequestOptions) fn, {
  Headers? headers,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            data: fn(options),
            headers: headers,
          ),
        );
      },
    ),
  );
  return BackendRepository(ApiClient(baseUrl: 'http://example.test', dio: dio));
}
