import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';
import 'package:sleewave/core/theme/app_theme.dart';
import 'package:sleewave/core/widgets/app_alert.dart';
import 'package:sleewave/core/widgets/app_search_field.dart';
import 'package:sleewave/core/widgets/now_playing_bars.dart';

void main() {
  testWidgets('AppAlert renders variant content and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        AppAlert(
          title: 'Warning',
          message: 'Something needs attention.',
          variant: AppAlertVariant.warning,
          actionLabel: 'Fix',
          onAction: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Something needs attention.'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    await tester.tap(find.text('Fix'));
    expect(tapped, isTrue);
  });

  testWidgets('AppSearchField changes, submits, and clears', (tester) async {
    final changes = <String>[];
    String? submitted;
    await tester.pumpWidget(
      _wrap(
        AppSearchField(
          placeholder: 'Search tracks',
          onChanged: changes.add,
          onSubmitted: (value) => submitted = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'wave');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(changes, contains('wave'));
    expect(submitted, 'wave');
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(changes.last, '');
  });

  testWidgets('NowPlayingBars renders in playing and paused states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const NowPlayingBars(color: Colors.white, playing: true)),
    );
    expect(find.byType(NowPlayingBars), findsOneWidget);

    await tester.pumpWidget(
      _wrap(const NowPlayingBars(color: Colors.white, playing: false)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.fromMode(SleewaveThemeMode.dark),
    home: Scaffold(body: Center(child: child)),
  );
}
