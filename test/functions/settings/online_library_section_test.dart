import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';
import 'package:sleewave/core/models/server_status.dart';
import 'package:sleewave/core/models/source_info.dart';
import 'package:sleewave/core/theme/app_theme.dart';
import 'package:sleewave/functions/settings/main_settings/widgets/online_library_section.dart';

void main() {
  testWidgets('shows all-sources direct URL switch and reports changes', (
    tester,
  ) async {
    var allValue = false;
    await tester.pumpWidget(
      _wrap(
        OnlineLibrarySection(
          status: const ServerStatus.connected(),
          sources: const [
            SourceInfo(
              id: 'yt',
              name: 'YouTube',
              available: true,
              supportsSearch: true,
              supportsStream: true,
              supportsDownload: true,
            ),
          ],
          urlController: TextEditingController(),
          checking: false,
          clearingCache: false,
          clearingSongs: false,
          directUrlSourceIds: const [],
          httpWarning: false,
          onCheck: () {},
          onClear: () {},
          onClearCache: () {},
          onClearSongs: () {},
          onDirectUrlAllSourcesChanged: (next) => allValue = next,
          onDirectUrlSourceChanged: (_, _) {},
          onOpenGuide: () {},
        ),
      ),
    );

    expect(find.text('All direct URLs'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(2));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);

    expect(allValue, isTrue);
  });

  testWidgets('shows per-source direct URL switches', (tester) async {
    var sourceValue = false;
    await tester.pumpWidget(
      _wrap(
        OnlineLibrarySection(
          status: const ServerStatus.connected(),
          sources: const [
            SourceInfo(
              id: 'yt',
              name: 'YouTube',
              available: true,
              supportsSearch: true,
              supportsStream: true,
              supportsDownload: true,
            ),
          ],
          urlController: TextEditingController(),
          checking: false,
          clearingCache: false,
          clearingSongs: false,
          directUrlSourceIds: const [],
          httpWarning: false,
          onCheck: () {},
          onClear: () {},
          onClearCache: () {},
          onClearSongs: () {},
          onDirectUrlAllSourcesChanged: (_) {},
          onDirectUrlSourceChanged: (sourceId, enabled) {
            if (sourceId == 'yt') {
              sourceValue = enabled;
            }
          },
          onOpenGuide: () {},
        ),
      ),
    );

    expect(find.text('YouTube'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(2));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);

    expect(sourceValue, isTrue);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.fromMode(SleewaveThemeMode.caffeineDark),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}
