import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';
import 'package:sleewave/core/models/source_info.dart';
import 'package:sleewave/core/theme/app_theme.dart';
import 'package:sleewave/functions/search/widgets/source_chip_bar.dart';

void main() {
  testWidgets('shows All and collapses extra sources behind More', (
    tester,
  ) async {
    var selectedAll = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.fromMode(SleewaveThemeMode.dark),
        home: Scaffold(
          body: SourceChipBar(
            sources: [
              _source('a', 'A'),
              _source('b', 'B'),
              _source('c', 'C'),
              _source('d', 'D'),
            ],
            selectedSourceIds: const [],
            onToggle: (_) {},
            onSelectAll: () => selectedAll = true,
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('All'));
    expect(selectedAll, isTrue);
  });
}

SourceInfo _source(String id, String name) {
  return SourceInfo(
    id: id,
    name: name,
    available: true,
    supportsSearch: true,
    supportsStream: true,
    supportsDownload: true,
  );
}
