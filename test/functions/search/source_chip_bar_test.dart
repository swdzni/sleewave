import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';
import 'package:sleewave/core/models/source_info.dart';
import 'package:sleewave/core/theme/app_theme.dart';
import 'package:sleewave/functions/search/widgets/source_chip_bar.dart';

void main() {
  testWidgets('starts expanded and collapses after source selection', (
    tester,
  ) async {
    var selectedAll = false;
    String? toggled;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.fromMode(SleewaveThemeMode.caffeineDark),
        home: Scaffold(
          body: SourceChipBar(
            sources: [
              _source('a', 'A'),
              _source('b', 'B'),
              _source('c', 'C'),
              _source('d', 'D'),
              _source('e', 'E', available: false),
            ],
            selectedSourceIds: const [],
            onToggle: (id) => toggled = id,
            onSelectAll: () => selectedAll = true,
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(find.text('More'), findsNothing);
    expect(find.text('Unavailable'), findsNothing);

    final availableHeight = tester.getSize(find.text('A')).height;
    final unavailableHeight = tester.getSize(find.text('E')).height;
    expect(unavailableHeight, availableHeight);

    await tester.tap(find.widgetWithText(FilterChip, 'B'));
    await tester.pumpAndSettle();
    expect(toggled, 'b');
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('Sources'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();
    expect(selectedAll, isTrue);
    expect(find.text('All'), findsNothing);
  });
}

SourceInfo _source(String id, String name, {bool available = true}) {
  return SourceInfo(
    id: id,
    name: name,
    available: available,
    supportsSearch: true,
    supportsStream: true,
    supportsDownload: true,
  );
}
