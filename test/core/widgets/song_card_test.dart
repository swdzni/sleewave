import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/app_settings.dart';
import 'package:sleewave/core/models/track.dart';
import 'package:sleewave/core/theme/app_theme.dart';
import 'package:sleewave/core/widgets/song_card.dart';

void main() {
  testWidgets('shows filled and outline heart states', (tester) async {
    await tester.pumpWidget(
      _wrap(SongCard(track: _track(isLiked: true), onLike: () {})),
    );
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.pumpWidget(
      _wrap(SongCard(track: _track(isLiked: false), onLike: () {})),
    );
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });

  testWidgets('shows availability badge and playlist action on normal rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SongCard(
          track: _track(resultId: 'result-1'),
          onAddToPlaylist: () {},
        ),
      ),
    );

    expect(find.text('Remote'), findsOneWidget);
    expect(find.text('Source A'), findsNothing);
    expect(find.byIcon(Icons.playlist_add_rounded), findsOneWidget);
  });

  testWidgets('does not overflow in a narrow row with multiple badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Center(
          child: SizedBox(
            width: 340,
            child: SongCard(
              track: _track(
                sourceId: 'source-a',
                resultId: 'result-1',
                durationSeconds: 700,
              ),
              isPlaying: true,
              onAddToPlaylist: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('hides playlist action on compact rows', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SongCard(
          track: _track(),
          mode: SongCardMode.compact,
          onAddToPlaylist: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.playlist_add_rounded), findsNothing);
  });

  testWidgets(
    'disables remote-only tracks when Online Library is unavailable',
    (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          SongCard(
            track: _track(resultId: 'result-1'),
            onlineAvailable: false,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Unavailable offline'), findsOneWidget);
      await tester.tap(find.byType(SongCard));
      expect(tapped, isFalse);
    },
  );

  testWidgets('remote rows without result IDs are unavailable', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        SongCard(
          track: _track(sourceId: 'source-a'),
          onlineAvailable: true,
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Unavailable offline'), findsOneWidget);
    await tester.tap(find.byType(SongCard));
    expect(tapped, isFalse);
  });

  testWidgets('hides inline actions when callbacks are omitted', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(SongCard(track: _track(resultId: 'r'))));

    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(find.byIcon(Icons.playlist_add_rounded), findsNothing);
    expect(find.byIcon(Icons.download_rounded), findsNothing);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.fromMode(SleewaveThemeMode.dark),
    home: Scaffold(body: child),
  );
}

Track _track({
  bool isLiked = false,
  String? sourceId,
  String? resultId,
  int? durationSeconds,
}) {
  final now = DateTime(2026);
  return Track(
    id: 'track-1',
    title: 'Track One',
    artist: 'Artist',
    sourceId: sourceId,
    resultId: resultId,
    durationSeconds: durationSeconds,
    isLiked: isLiked,
    createdAt: now,
    updatedAt: now,
  );
}
