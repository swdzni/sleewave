import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/network/api_exception.dart';

void main() {
  test('maps expired result errors as recoverable', () {
    final error = ApiException.fromResponse(404, {
      'error': {'code': 'search_result_not_found', 'message': 'Expired'},
    });

    expect(error.code, 'search_result_not_found');
    expect(error.message, 'Track needs to be refreshed from Online Library.');
    expect(error.isRecoverable, isTrue);
  });

  test('maps already-downloaded conflicts gently', () {
    final error = ApiException.fromResponse(409, {
      'error': {'code': 'track_already_on_device', 'message': 'Already saved'},
    });

    expect(error.message, 'Already downloaded');
  });

  test('maps unavailable sources as recoverable', () {
    final error = ApiException.fromResponse(503, {
      'error': {'code': 'provider_unavailable', 'message': 'Unavailable'},
    });

    expect(
      error.message,
      'Source is unavailable. Try another source or refresh Online Library.',
    );
    expect(error.isRecoverable, isTrue);
  });

  test('maps preparation gateway errors to a retryable message', () {
    final error = ApiException.fromResponse(502, {
      'error': {'code': 'track_preparation_failed'},
    });

    expect(
      error.message,
      'Track could not be prepared. Try again or choose another source.',
    );
    expect(error.isRecoverable, isTrue);
  });

  test('maps plain server errors to friendly messages', () {
    final error = ApiException.fromResponse(500, 'not json');

    expect(error.message, 'Online Library had a server problem. Try again.');
    expect(error.isRecoverable, isTrue);
  });

  test('maps generic documented HTTP errors', () {
    expect(
      ApiException.fromResponse(404, 'missing').message,
      'Requested Online Library item was not found.',
    );
    expect(
      ApiException.fromResponse(409, 'conflict').message,
      'This action conflicts with the current library state.',
    );
    expect(
      ApiException.fromResponse(422, 'bad payload').message,
      'Some request details are not valid.',
    );
  });
}
