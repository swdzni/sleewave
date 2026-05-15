import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiClient {
  ApiClient({required String baseUrl, Dio? dio})
    : _baseUrl = baseUrl,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );

  final String _baseUrl;
  final Dio _dio;

  Dio get dio => _dio;

  Uri buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = Uri.parse(_baseUrl);
    final joined = base.resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );
    return joined.replace(
      queryParameters: {
        ...joined.queryParameters,
        ...?queryParameters?.map((key, value) => MapEntry(key, '$value')),
      },
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return Map<String, dynamic>.from(response.data! as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return Map<String, dynamic>.from(response.data! as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Response<List<int>>> postBytes(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onReceiveProgress,
    Duration? receiveTimeout,
  }) async {
    try {
      return await _dio.post<List<int>>(
        path,
        data: data,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: receiveTimeout ?? const Duration(minutes: 5),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Response<ResponseBody>> postStream(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Duration? receiveTimeout,
  }) async {
    try {
      return await _dio.post<ResponseBody>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: receiveTimeout ?? const Duration(minutes: 5),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
