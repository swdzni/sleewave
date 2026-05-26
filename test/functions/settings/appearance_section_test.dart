import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';
import 'package:sleewave/core/theme/app_theme.dart';
import 'package:sleewave/functions/settings/main_settings/widgets/appearance_section.dart';

void main() {
  testWidgets('theme palette previews render visible swatches', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.fromMode(SleewaveThemeMode.caffeineDark),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppearanceSection(
              themeMode: SleewaveThemeMode.caffeineDark,
              onThemeChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Caffeine Dark'), findsNothing);
    expect(find.text('Caffeine Light'), findsNothing);
    expect(find.text('Mono Dark'), findsNothing);
    expect(find.text('Mono Light'), findsNothing);
    expect(find.text('Glue Dark'), findsNothing);
    expect(find.text('Glue Light'), findsNothing);
    expect(find.text('Dynamic'), findsNothing);
    expect(find.byKey(const ValueKey('theme-card-glueDark')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-card-glueLight')), findsOneWidget);
    expect(find.byKey(const ValueKey('caffeine-theme-icon')), findsWidgets);
    expect(find.byKey(const ValueKey('mono-theme-icon')), findsWidgets);
    expect(find.byKey(const ValueKey('glue-theme-icon')), findsWidgets);
    expect(find.byWidgetPredicate(_isVisibleSwatch), findsAtLeastNWidgets(20));
  });
}

bool _isVisibleSwatch(Widget widget) {
  if (widget is! Container) {
    return false;
  }
  final decoration = widget.decoration;
  if (decoration is! BoxDecoration) {
    return false;
  }
  final color = decoration.color;
  return color != null && color.a > 0;
}
