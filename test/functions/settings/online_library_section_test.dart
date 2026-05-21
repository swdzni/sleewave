import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';
import 'package:sleewave/core/models/server_status.dart';
import 'package:sleewave/core/theme/app_theme.dart';
import 'package:sleewave/functions/settings/main_settings/widgets/online_library_section.dart';

void main() {
  testWidgets('shows direct URL switch and reports changes', (tester) async {
    var value = false;
    await tester.pumpWidget(
      _wrap(
        OnlineLibrarySection(
          status: const ServerStatus.notConfigured(),
          sources: const [],
          urlController: TextEditingController(),
          checking: false,
          clearingCache: false,
          clearingSongs: false,
          directUrlEnabled: value,
          httpWarning: false,
          onCheck: () {},
          onClear: () {},
          onClearCache: () {},
          onClearSongs: () {},
          onDirectUrlChanged: (next) => value = next,
          onOpenGuide: () {},
        ),
      ),
    );

    expect(find.text('Direct URLs'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    await tester.tap(find.byType(Switch));

    expect(value, isTrue);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.fromMode(SleewaveThemeMode.caffeineDark),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}
