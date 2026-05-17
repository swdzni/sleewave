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

  test('saved songs follow paginated responses', () async {
    final calls = <RequestOptions>[];
    final repository = _repository((options) {
      calls.add(options);
      final offset = options.queryParameters['offset'] as int;
      if (offset == 0) {
        return {
          'songs': [
            {'title': 'One', 'result_id': 'one'},
            {'title': 'Two', 'result_id': 'two'},
          ],
          'count': 2,
          'total': 3,
          'limit': 2,
          'offset': 0,
          'has_more': true,
        };
      }
      return {
        'songs': [
          {'title': 'Three', 'result_id': 'three'},
        ],
        'count': 1,
        'total': 3,
        'limit': 2,
        'offset': 2,
        'has_more': false,
      };
    });

    final songs = await repository.getSavedSongs(pageSize: 2);

    expect(songs.map((track) => track.id), ['one', 'two', 'three']);
    expect(calls.map((options) => options.queryParameters), [
      {'limit': 2, 'offset': 0},
      {'limit': 2, 'offset': 2},
    ]);
  });

  test('delete track parses backend response message', () async {
    late RequestOptions sentOptions;
    final repository = _repository((options) {
      sentOptions = options;
      return {'result_id': 'stable-track', 'cache_deleted': true};
    });

    final result = await repository.deleteTrack('stable-track');

    expect(sentOptions.method, 'DELETE');
    expect(sentOptions.path, '/tracks/stable-track');
    expect(result.resultId, 'stable-track');
    expect(result.cacheDeleted, isTrue);
    expect(result.message, contains('stable-track'));
  });

  test('cleanup responses parse deleted count and cleared flags', () async {
    var serverTemp = false;
    final repository = _repository((options) {
      serverTemp = options.path == '/server-temp';
      return {
        'deleted_count': serverTemp ? 7 : 3,
        'track_catalog_cleared': serverTemp,
        'device_library_cleared': serverTemp,
      };
    });

    final cache = await repository.clearCache();
    final temp = await repository.clearServerTemp();

    expect(cache.message('cached files'), contains('Deleted 3 cached files'));
    expect(cache.trackCatalogCleared, isFalse);
    expect(temp.message('server files'), contains('Deleted 7 server files'));
    expect(temp.deviceLibraryCleared, isTrue);
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
