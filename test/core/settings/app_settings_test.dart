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

  test('share text is disabled by default and copyable', () {
    final defaults = AppSettings.defaults();
    final updated = defaults.copyWith(shareWithText: true);

    expect(defaults.shareWithText, isFalse);
    expect(updated.shareWithText, isTrue);
  });

  test('direct URLs are opt-in and copyable', () {
    final defaults = AppSettings.defaults();
    final updated = defaults.copyWith(directUrlEnabled: true);

    expect(defaults.directUrlEnabled, isFalse);
    expect(updated.directUrlEnabled, isTrue);
  });

  test('maps legacy theme names to new palette modes', () {
    expect(
      SleewaveThemeMode.fromStorage('dark'),
      SleewaveThemeMode.caffeineDark,
    );
    expect(
      SleewaveThemeMode.fromStorage('white'),
      SleewaveThemeMode.caffeineLight,
    );
    expect(
      SleewaveThemeMode.fromStorage('pureDark'),
      SleewaveThemeMode.monoDark,
    );
  });
}
