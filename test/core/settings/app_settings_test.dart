import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';

void main() {
  test('generates device IDs in the required format', () {
    final id = AppSettings.generateDeviceId();

    expect(id, matches(RegExp(r'^device-[a-z0-9]{6}$')));
  });

  test('normalizes backend URLs', () {
    expect(
      AppSettings.normalizeBackendUrl(' http://127.0.0.1:8000/ '),
      'http://127.0.0.1:8000',
    );
    expect(AppSettings.normalizeBackendUrl('   '), isNull);
  });

  test('detects remote plain HTTP warning', () {
    expect(AppSettings.shouldWarnForHttp('http://example.test'), isTrue);
    expect(AppSettings.shouldWarnForHttp('http://192.168.1.2:8000'), isFalse);
  });

  test('clamps recent history limit', () {
    expect(AppSettings.defaults().recentHistoryLimit, 100);
    expect(
      AppSettings(
        deviceId: 'device-one',
        recentHistoryLimit: 1,
      ).recentHistoryLimit,
      5,
    );
    expect(
      AppSettings(
        deviceId: 'device-one',
        recentHistoryLimit: 999,
      ).recentHistoryLimit,
      200,
    );
  });
}
