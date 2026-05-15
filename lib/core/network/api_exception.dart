import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    this.statusCode,
    required this.code,
    required this.message,
    this.details = const {},
    this.isRecoverable = false,
  });

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response != null) {
      return ApiException.fromResponse(response.statusCode, response.data);
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          code: 'timeout',
          message: 'Online Library did not respond.',
          isRecoverable: true,
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          code: 'connection_refused',
          message: 'Cannot reach Online Library.',
          isRecoverable: true,
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          code: 'bad_certificate',
          message: 'Check server link.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          code: 'cancelled',
          message: 'Request cancelled.',
          isRecoverable: true,
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return const ApiException(
          code: 'network_error',
          message: 'Cannot reach Online Library.',
          isRecoverable: true,
        );
    }
  }

  factory ApiException.fromResponse(int? statusCode, Object? data) {
    String code = 'http_error';
    String message = 'Something went wrong.';
    Map<String, dynamic> details = const {};

    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        code = error['code'] as String? ?? code;
        message = error['message'] as String? ?? message;
        final rawDetails = error['details'];
        if (rawDetails is Map) {
          details = Map<String, dynamic>.from(rawDetails);
        }
      }
    }

    return ApiException(
      statusCode: statusCode,
      code: code,
      message: _friendlyMessage(code, message),
      details: details,
      isRecoverable: _isRecoverable(code, statusCode),
    );
  }

  final int? statusCode;
  final String code;
  final String message;
  final Map<String, dynamic> details;
  final bool isRecoverable;

  static String _friendlyMessage(String code, String fallback) {
    switch (code) {
      case 'bad_request':
      case 'validation_error':
        return fallback;
      case 'provider_not_found':
        return 'Source is no longer available.';
      case 'search_result_not_found':
      case 'cache_entry_not_found':
        return 'Track needs to be refreshed.';
      case 'track_already_on_device':
        return 'Already downloaded';
      case 'track_preparation_failed':
        return 'Track could not be prepared. Try again.';
      case 'provider_unavailable':
        return 'Source is unavailable.';
      case 'internal_server_error':
        return 'Online Library had a problem. Try again.';
      default:
        return fallback;
    }
  }

  static bool _isRecoverable(String code, int? statusCode) {
    return code == 'search_result_not_found' ||
        code == 'cache_entry_not_found' ||
        code == 'provider_unavailable' ||
        code == 'track_preparation_failed' ||
        statusCode == 500 ||
        statusCode == 503;
  }

  @override
  String toString() => 'ApiException($code, $message)';
}
