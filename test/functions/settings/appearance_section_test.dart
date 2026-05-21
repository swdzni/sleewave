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
              glowMode: GlowMode.static,
              onThemeChanged: (_) {},
              onGlowChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Caffeine Dark'), findsOneWidget);
    expect(find.text('Mono Light'), findsOneWidget);
    expect(find.byWidgetPredicate(_isVisibleSwatch), findsAtLeastNWidgets(24));
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
