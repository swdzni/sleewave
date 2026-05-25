import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';
import 'package:sleewave/core/models/server_status.dart';
import 'package:sleewave/core/theme/app_theme.dart';
import 'package:sleewave/functions/home/widgets/host_info_card.dart';

void main() {
  testWidgets('opens settings area and exposes manual retry on problem', (
    tester,
  ) async {
    var opened = false;
    var retried = false;
    await tester.pumpWidget(
      _wrap(
        HostInfoCard(
          status: const ServerStatus.problem('Cannot reach Online Library.'),
          onTap: () => opened = true,
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Cannot reach Online Library.'), findsOneWidget);
    expect(find.byTooltip('Retry Online Library'), findsOneWidget);

    await tester.tap(find.byTooltip('Retry Online Library'));

    expect(retried, isTrue);
    expect(opened, isFalse);

    await tester.tap(find.text('Online Library'));

    expect(opened, isTrue);
  });

  testWidgets('does not show retry while checking', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HostInfoCard(
          status: const ServerStatus.checking(),
          onTap: () {},
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Checking...'), findsOneWidget);
    expect(find.byTooltip('Retry Online Library'), findsNothing);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.fromMode(SleewaveThemeMode.caffeineDark),
    home: Scaffold(body: Center(child: child)),
  );
}
