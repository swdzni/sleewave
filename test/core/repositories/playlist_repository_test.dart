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
}
