import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/constants/app_constants.dart';
import 'package:sleewave/core/database/app_database.dart';
import 'package:sleewave/core/models/track.dart';
import 'package:sleewave/core/repositories/playlist_repository.dart';
import 'package:sleewave/core/repositories/track_repository.dart';

void main() {
  late AppDatabase db;
  late TrackRepository tracks;
  late PlaylistRepository playlists;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    playlists = PlaylistRepository(db, tracks);
  });

  tearDown(() async {
    await db.close();
  });

  test('creates the Favorite playlist', () async {
    await playlists.ensureFavorites();
    final all = await playlists.allPlaylists();

    expect(all.first.id, AppConstants.favoritePlaylistId);
    expect(all.first.name, AppConstants.favoritePlaylistName);
  });

  test('creating Favorite is safe when called concurrently', () async {
    await Future.wait([
      for (var index = 0; index < 20; index++) playlists.ensureFavorites(),
    ]);
    final all = await playlists.allPlaylists();

    expect(
      all.where((playlist) => playlist.id == AppConstants.favoritePlaylistId),
      hasLength(1),
    );
  });

  test('adds and removes tracks from a custom playlist', () async {
    final now = DateTime(2026);
    final track = await tracks.upsert(
      Track(id: 'track-1', title: 'Local Cut', createdAt: now, updatedAt: now),
    );
    final playlist = await playlists.create('Road');

    await playlists.addTrack(playlist.id, track);
    expect(await playlists.trackCount(playlist.id), 1);

    await playlists.removeTrack(playlist.id, track);
    expect(await playlists.trackCount(playlist.id), 0);
  });

  test(
    'creates custom playlists with a cover color and supports rename',
    () async {
      final playlist = await playlists.create('Road');

      expect(playlist.coverPath, matches(RegExp(r'^#[0-9a-f]{6}$')));

      await playlists.rename(playlist, 'Night road');
      final renamed = (await playlists.allPlaylists()).firstWhere(
        (item) => item.id == playlist.id,
      );

      expect(renamed.name, 'Night road');
      expect(renamed.coverPath, playlist.coverPath);
    },
  );

  test('Favorite membership follows liked state', () async {
    final now = DateTime(2026);
    final track = await tracks.upsert(
      Track(id: 'track-1', title: 'Local Cut', createdAt: now, updatedAt: now),
    );

    final liked = await playlists.addTrack(
      AppConstants.favoritePlaylistId,
      track,
    );
    expect(liked.isLiked, isTrue);
    expect(
      await playlists.containsTrack(AppConstants.favoritePlaylistId, liked),
      isTrue,
    );

    final unliked = await playlists.removeTrack(
      AppConstants.favoritePlaylistId,
      liked,
    );
    expect(unliked.isLiked, isFalse);
  });
}
