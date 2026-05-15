
````markdown
You are Codex acting as a senior Flutter/iOS software engineer.

Build an iOS-first Flutter app named **Sleewave**. Sleewave is an offline-first local music player with an optional user-configured self-hosted “Online Library” backend. The app must feel like a polished iOS music player, but it must not advertise itself as a third-party provider downloader/streamer. The backend is only presented as the user’s own online library/VPS connection.

Do not ask follow-up questions. Do not leave architectural choices for later. Use the exact decisions in this prompt. Implement the app, create the necessary files, wire the features, and make the project analyzable/runnable.

---

# 1. Product Goal

Build **Sleewave**, a Flutter iOS music player with:

- Local/offline library playback.
- Importing local audio files.
- Downloading audio from the user’s own backend into the app’s local library.
- Streaming playable backend search results.
- Local playlists, including a built-in **Favorite** playlist.
- Recently played tracks.
- A full-screen player and animated mini-player.
- A floating animated iOS 26-inspired tab bar.
- Pure dark, dark, and white themes.
- Optional RGB glow highlights, static or dynamic.
- Backend settings page for “Online Library” connection.
- Startup sync with backend when backend is configured.

The app must be clean, structured, maintainable, and not a one-file prototype.

---

# 2. Non-Negotiable Engineering Rules

Use:

- Flutter + Dart.
- iOS-first implementation.
- Clean Architecture principles without overengineering.
- OOP, SOLID, MVVM.
- Feature-based folder structure.
- `core/` for shared project infrastructure.
- `functions/` for each feature/page/function.
- No giant files.
- No UI logic inside API clients.
- No network code inside widgets.
- No local database code inside widgets.
- No hard-coded backend provider brands in UI strings, comments, enum names, test names, or marketing text.
- Backend source IDs/names must be treated as opaque runtime data returned by `/sources`.

Do not use provider-specific wording in UI such as names of music/video/social/audio platforms. Use generic wording:

- “Online Library”
- “Source”
- “Server”
- “Cached”
- “Downloaded”
- “Remote”
- “Local”

If the backend returns a `source.name`, you may display that returned string inside the source selector because it came from the user’s configured backend, but do not hard-code those names anywhere.

---

# 3. Fixed Tech Stack

Use these packages:

Runtime dependencies:

- `flutter_riverpod` for app state and MVVM ViewModels.
- `go_router` for navigation.
- `dio` for REST requests, downloads, progress callbacks, and streamed SSE response handling.
- `just_audio` for playback.
- `just_audio_background` for background playback / lock screen / remote controls.
- `audio_session` for iOS audio session configuration.
- `drift` + `drift_flutter` + `sqlite3_flutter_libs` for local persistence.
- `path_provider` for app folders.
- `path` for path operations.
- `file_picker` for importing audio files.
- `audio_metadata_reader` for reading local audio metadata where possible.
- `cached_network_image` for remote cover art caching.
- `uuid` for local IDs.
- `intl` for formatting dates/durations if needed.
- `collection` for list helpers.

Dev dependencies:

- `drift_dev`
- `build_runner`
- `flutter_lints`
- `mocktail`
- `flutter_test`

Do not add a heavy UI kit. Build custom widgets using Flutter/Cupertino/Material primitives.

Use plain Riverpod providers manually. Do not use Riverpod generator. Use Drift generator only.

---

# 4. Backend API Contract

Base URL in local development:

```text
http://127.0.0.1:8000
````

The backend is optional. The app must work fully as an offline player without a backend URL.

## 4.1 Core Backend Concepts

### `result_id`

`result_id` is the temporary handle used for backend playback/download.

* Returned by `/search`.
* Returned by `/saved-songs`.
* Expires after backend TTL, default 1800 seconds.
* Use with:

  * `GET /stream/{result_id}` for `just_audio` URL playback.
  * `POST /download/{result_id}` for downloads.
* If a `result_id` expires, backend returns `404 search_result_not_found`.
* Recovery:

  * If the track came from `/saved-songs`, call `/saved-songs` again.
  * If the track came from search, repeat the latest search.
  * Match by `track_key`, then `base_track_key`, then normalized title/artist/duration fallback.
  * Retry the original action once with the new `result_id`.

### `track_key` and `base_track_key`

Store both values whenever the backend provides them.

* `track_key`: stable title + artist + approximate duration identity.
* `base_track_key`: stable title + artist identity.
* Use them for deduplication, local DB identity, download confirmation, sync, and result expiry recovery.
* Send them to:

  * `POST /device-library/sync`
  * `POST /device-library/confirm-download`

### Server cache

* Backend caches MP3 files server-side.
* Cached matching results appear first in search results.
* `/saved-songs` returns server-cached songs with fresh `result_id`s.
* Cache may be evicted, so client must handle missing cache entries.

### Device library

Backend device library is not the local MP3 files. It is a lightweight list of stable track keys for one device.

Use it to let backend know what this phone already has downloaded.

---

# 5. Required Backend Endpoints

Implement an API layer covering all endpoints below.

## `GET /health`

Returns:

```json
{
  "status": "ok"
}
```

Use only as a lightweight connectivity check. `/sources` is the main online library check.

## `GET /sources`

Returns:

```json
{
  "sources": [
    {
      "id": "ytm",
      "name": "YouTube Music",
      "available": true,
      "supports_search": true,
      "supports_stream": true,
      "supports_download": true
    }
  ]
}
```

Client rules:

* Do not hard-code source IDs or names.
* Store sources as runtime data.
* Search source chips come only from this endpoint.
* Disabled/unavailable sources appear disabled or hidden according to UX:

  * Show unavailable sources as disabled chips only if backend returns them.
  * Do not allow selecting unavailable sources.
* Default selected sources: all sources where `available == true` and `supports_search == true`.

## `GET /search`

Streams SSE events.

Query params:

* `q`: required, trim before sending, minimum length 1.
* `sources`: optional comma-separated source IDs.
* `source`: optional single-source alias, do not use this in the client; always use `sources`.
* `limit`: use `25` by default.
* `offset`: use `0` initially.
* `device_id`: current generated/edited device ID.

Example request:

```http
GET /search?q=daft%20punk&sources=sourceA,sourceB&limit=25&offset=0&device_id=device-a1b2c3
```

SSE events:

```sse
event: start
data: {"event":"start","query":"daft punk","sources":["ytm","yt","sc"],"emitted":0}

event: track
data: {"event":"track","source":"ytm","track":{"title":"One More Time","artist":"Daft Punk","duration":320,"cover_url":"https://...","album":"Discovery","result_id":"QvQ0S4VixjP2","track_key":"stable-exact-key","base_track_key":"stable-title-artist-key","availability":{"in_server_cache":true,"cache_key":"stable-exact-key","preferred_origin":"server"}},"emitted":1}

event: warning
data: {"event":"warning","source":"sc","warning":{"source":"sc","message":"Search failed for source 'sc' and it was skipped."},"emitted":4}

event: done
data: {"event":"done","emitted":10}
```

Client rules:

* Parse SSE manually using `dio` with `ResponseType.stream`.
* Decode UTF-8.
* Split by lines.
* Accumulate `event:` and `data:` fields.
* Emit typed events:

  * `SearchStarted`
  * `SearchTrackFound`
  * `SearchWarning`
  * `SearchDone`
* Render every `track` event as it arrives.
* Warnings are non-fatal if multiple sources were selected.
* If only one source was selected and the request fails, show a normal error.
* Cancel previous search when a new search starts.
* Debounce typing by 350ms.
* Results appear one by one, not only after the whole request finishes.

Track object fields:

```json
{
  "title": "One More Time",
  "artist": "Daft Punk",
  "duration": 320,
  "cover_url": "https://...",
  "album": "Discovery",
  "result_id": "QvQ0S4VixjP2",
  "track_key": "stable-exact-key",
  "base_track_key": "stable-title-artist-key",
  "availability": {
    "in_server_cache": true,
    "on_device": false,
    "cache_key": "stable-exact-key",
    "preferred_origin": "server"
  }
}
```

Availability meanings:

* `in_server_cache`: backend already has MP3 cached.
* `on_device`: backend thinks this device already has it.
* `cache_key`: server cache key if cached.
* `preferred_origin`: one of `device`, `server`, `remote`.

Client display priority:

1. Local downloaded matching tracks from local DB.
2. Backend results where `availability.on_device == true`.
3. Backend results where `availability.in_server_cache == true`.
4. Remote results.

Do not reorder jarringly after a card is displayed. Insert new cards into the correct group as they arrive. Deduplicate by:

1. `track_key`
2. `base_track_key`
3. normalized `artist + title + duration bucket`

## `GET /stream/{result_id}`

Use this for playback because `just_audio` consumes URL-based sources cleanly.

Rules:

* Build URL: `{baseUrl}/stream/{result_id}`.
* Use `AudioSource.uri(Uri.parse(url), tag: MediaItem(...))`.
* This endpoint returns `audio/mpeg`.
* If first play is slow, show buffering/loading.
* If `404 search_result_not_found`, refresh the `result_id` and retry once.
* If `404 cache_entry_not_found`, refresh `/saved-songs` or search and retry once.
* If still failing, show a non-scary playback error.

Also implement `POST /stream/{result_id}` in the API client for completeness, but playback service should use GET URL mode.

## `POST /download/{result_id}`

Use for downloading.

Request:

```http
POST /download/{result_id}?device_id={deviceId}
```

Response:

* `audio/mpeg`
* attachment filename in header if available.

Client rules:

* Use `dio` with `ResponseType.bytes`.
* Show download progress.
* Save to a temporary file first.
* Then atomically move/rename into app downloads folder.
* Filename format:

  * sanitize artist/title.
  * `{artist} - {title}.mp3`
  * if conflict, append ` (2)`, ` (3)`, etc.
* After file is saved successfully, call `/device-library/confirm-download`.
* Update local DB availability immediately after confirm succeeds.
* If confirm fails but file is saved, keep file and queue a pending confirm retry in local DB.

Handle `409 track_already_on_device`:

* Do not show scary error.
* Show “Already downloaded”.
* Mark local state as downloaded if a local file exists.
* If local file does not exist, run sync and keep UI consistent.

## `GET /saved-songs`

Returns server cached songs with fresh `result_id`s.

Use for:

* Home screen “Saved on server”.
* Online Library cached section.
* Result ID refresh for cached tracks.
* Startup backend refresh.

Client rules:

* Refresh whenever opening Home if backend configured.
* Refresh when online status becomes connected.
* Treat empty list as normal empty state.
* All returned songs are playable with `/stream/{result_id}` and downloadable with `/download/{result_id}`.

## `POST /device-library/sync`

Request:

```json
{
  "device_id": "device-a1b2c3",
  "tracks": [
    {
      "track_key": "stable-exact-key",
      "base_track_key": "stable-title-artist-key"
    }
  ]
}
```

Rules:

* Call on app startup after local DB/files are loaded.
* Call after local downloaded file deletion.
* Only include local tracks that have backend-provided `track_key` and `base_track_key`.
* Do not include pure imported local files without backend keys.
* This replaces the backend’s known tracks for the device.
* It does not delete server cache files.

## `POST /device-library/confirm-download`

Preferred request:

```json
{
  "device_id": "device-a1b2c3",
  "track_key": "stable-exact-key",
  "base_track_key": "stable-title-artist-key"
}
```

Fallback request while `result_id` is still valid:

```json
{
  "device_id": "device-a1b2c3",
  "result_id": "QvQ0S4VixjP2"
}
```

Rules:

* Use preferred request whenever possible.
* Use fallback only if keys are missing but result ID is still valid.
* If response `registered == false`, treat as success because backend already knew the track.

---

# 6. Backend Error Handling

Backend handled errors use:

```json
{
  "error": {
    "code": "error_code",
    "message": "Human readable message.",
    "details": {}
  }
}
```

Implement `ApiException` with:

* `statusCode`
* `code`
* `message`
* `details`
* `isRecoverable`

Map errors:

| HTTP | Code                       | Client behavior                                         |
| ---- | -------------------------- | ------------------------------------------------------- |
| 400  | `bad_request`              | Show validation message.                                |
| 404  | `provider_not_found`       | Refresh `/sources`, remove invalid selected source.     |
| 404  | `search_result_not_found`  | Refresh result ID and retry once.                       |
| 404  | `cache_entry_not_found`    | Refresh saved songs or search again.                    |
| 409  | `track_already_on_device`  | Show downloaded/local state, not scary error.           |
| 422  | `validation_error`         | Fix payload; show user-friendly message.                |
| 502  | `track_preparation_failed` | Show retry and allow trying another source/result.      |
| 503  | `provider_unavailable`     | Mark source unavailable, fallback if multiple selected. |
| 500  | `internal_server_error`    | Generic retry error.                                    |

Network errors:

* Timeout: show “Online Library did not respond.”
* Connection refused: show “Cannot reach Online Library.”
* Invalid URL: show “Check server link.”
* No backend configured: do not show error; treat as offline mode.

---

# 7. iOS Network / App Store-Safe Rules

The app supports local development with:

```text
http://127.0.0.1:8000
```

But production should prefer HTTPS.

Implement these exact rules:

* Settings allow saving any URL with scheme `http` or `https`.
* Show warning if URL is plain HTTP and not localhost/private LAN:

  * “HTTPS is recommended for remote servers.”
* In iOS config, do not enable broad unrestricted arbitrary loads for release.
* Add debug/local ATS exceptions only for localhost/local development if needed.
* Keep Online Library optional and user-configured.
* Do not claim the app includes built-in third-party provider access.
* Do not mention provider brands in app copy.
* The UI instruction copy must say:

  * “Sleewave works offline. You can optionally connect your own Online Library server.”
  * “Set up the backend on your own server, paste the server link here, then press Check.”
* Include a config constant:

  * `backendSetupRepoUrl = 'https://github.com/sleewave-app/sleewave-backend'`
* Use that constant for the setup guide link. Do not scatter URLs.

---

# 8. App Startup Flow

On launch:

1. Initialize Flutter bindings.
2. Initialize `just_audio_background`.
3. Configure `audio_session` for music playback.
4. Open Drift database.
5. Initialize app folders:

   * app documents directory
   * `Sleewave/Downloads`
   * `Sleewave/Imported`
   * `Sleewave/Covers`
6. Load settings.
7. If `deviceId` is missing, generate:

   * format: `device-xxxxxx`
   * `x` = lowercase alphanumeric
   * exactly 6 random characters
8. Ensure built-in Favorite playlist exists.
9. Scan local downloads/imported folders:

   * remove DB local paths whose files no longer exist.
   * add imported files if missing.
   * read metadata when possible.
10. If backend URL is configured:

* set Online Library status to `unknown/checking`.
* call `/sources`.
* if success:

  * set status `connected`.
  * store sources.
  * call `/device-library/sync`.
  * call `/saved-songs`.
* if failure:

  * set status `problem` with message.

11. If backend URL is not configured:

* set Online Library status `notConfigured`.

12. Show Home screen.

No blocking full-screen startup loader longer than necessary. Show a simple splash only during DB/settings initialization. Backend sync can finish while Home is visible.

---

# 9. Project Structure

Use this structure:

```text
lib/
  main.dart
  app.dart

  core/
    config/
      app_config.dart
    constants/
      app_constants.dart
      api_paths.dart
    theme/
      app_theme.dart
      app_colors.dart
      glow_theme.dart
      theme_controller.dart
    routing/
      app_router.dart
      route_names.dart
    network/
      api_client.dart
      api_exception.dart
      sse_client.dart
      backend_models.dart
    database/
      app_database.dart
      tables.dart
      daos/
        tracks_dao.dart
        playlists_dao.dart
        settings_dao.dart
        recent_dao.dart
        pending_actions_dao.dart
    models/
      track.dart
      track_availability.dart
      source_info.dart
      playlist.dart
      app_settings.dart
      server_status.dart
      playback_models.dart
    repositories/
      backend_repository.dart
      track_repository.dart
      playlist_repository.dart
      settings_repository.dart
      library_repository.dart
    services/
      playback/
        playback_service.dart
        queue_service.dart
      downloads/
        download_service.dart
      sync/
        sync_service.dart
      files/
        file_storage_service.dart
        metadata_service.dart
      search/
        search_service.dart
    widgets/
      app_scaffold.dart
      glass_tab_bar.dart
      glow_button.dart
      song_card.dart
      track_badges.dart
      cover_art.dart
      empty_state.dart
      loading_state.dart
      error_state.dart
      bottom_sheet_shell.dart

  functions/
    shell/
      models/
        shell_state.dart
      view_models/
        shell_view_model.dart
      views/
        shell_screen.dart

    home/
      models/
        home_state.dart
      view_models/
        home_view_model.dart
      views/
        home_screen.dart
      widgets/
        home_section.dart
        host_info_card.dart

    search/
      models/
        search_state.dart
      view_models/
        search_view_model.dart
      views/
        search_screen.dart
      widgets/
        source_chip_bar.dart
        search_result_list.dart

    playlists/
      models/
        playlists_state.dart
        playlist_detail_state.dart
      view_models/
        playlists_view_model.dart
        playlist_detail_view_model.dart
      views/
        playlists_screen.dart
        playlist_detail_screen.dart
      widgets/
        playlist_card.dart
        add_to_playlist_sheet.dart
        playlist_cover.dart

    library/
      models/
        library_state.dart
      view_models/
        library_view_model.dart
      views/
        library_screen.dart
      widgets/
        folder_header.dart
        import_button.dart

    settings/
      main_settings/
        models/
          settings_state.dart
        view_models/
          settings_view_model.dart
        views/
          settings_screen.dart
        widgets/
          appearance_section.dart
          online_library_section.dart
          device_section.dart

    player/
      models/
        player_state.dart
      view_models/
        player_view_model.dart
      views/
        player_screen.dart
      widgets/
        mini_player.dart
        player_controls.dart
        queue_panel.dart
        playback_mode_button.dart
        swipe_dismiss_layer.dart
```

Use feature-level MVVM folders:

* `models`
* `view_models`
* `views`
* `widgets`

Shared cross-feature code goes in `core`.

---

# 10. Local Database Schema

Use Drift.

Tables:

## `tracks`

Fields:

* `id` TEXT primary key local UUID.
* `title` TEXT not null.
* `artist` TEXT not null default `"Unknown Artist"`.
* `album` TEXT nullable.
* `durationSeconds` INTEGER nullable.
* `coverUrl` TEXT nullable.
* `localCoverPath` TEXT nullable.
* `sourceId` TEXT nullable.
* `resultId` TEXT nullable.
* `trackKey` TEXT nullable.
* `baseTrackKey` TEXT nullable.
* `cacheKey` TEXT nullable.
* `preferredOrigin` TEXT not null default `local`.
* `inServerCache` BOOL not null default false.
* `onDevice` BOOL not null default false.
* `localPath` TEXT nullable.
* `localOrigin` TEXT not null:

  * `downloaded`
  * `imported`
  * `remoteOnly`
  * `serverCached`
* `isLiked` BOOL not null default false.
* `lastPlayedAt` DATETIME nullable.
* `createdAt` DATETIME not null.
* `updatedAt` DATETIME not null.

Indexes:

* `trackKey`
* `baseTrackKey`
* `title`
* `artist`
* `lastPlayedAt`
* `isLiked`

## `playlists`

Fields:

* `id` TEXT primary key.
* `name` TEXT not null.
* `coverPath` TEXT nullable.
* `specialType` TEXT nullable:

  * null for normal playlist
  * `favorites` for Favorite playlist
* `createdAt` DATETIME not null.
* `updatedAt` DATETIME not null.

Rules:

* Built-in favorite playlist ID: `favorites`.
* Built-in favorite playlist name: `Favorite`.
* Favorite playlist cannot be deleted or renamed from UI unless specifically implemented later.

## `playlist_tracks`

Fields:

* `playlistId` TEXT not null.
* `trackId` TEXT not null.
* `position` INTEGER not null.
* `addedAt` DATETIME not null.

Primary key:

* `playlistId + trackId`

## `recent_tracks`

Fields:

* `trackId` TEXT primary key.
* `playedAt` DATETIME not null.
* `playCount` INTEGER not null default 1.

## `settings`

Use key-value table:

* `key` TEXT primary key.
* `value` TEXT not null.

Store serialized primitive strings/JSON for:

* `themeMode`
* `glowMode`
* `backendBaseUrl`
* `deviceId`
* `selectedSourceIds`
* `searchLimit`

## `pending_actions`

For retrying failed backend confirmations:

* `id` TEXT primary key.
* `type` TEXT not null:

  * `confirmDownload`
  * `syncDeviceLibrary`
* `payloadJson` TEXT not null.
* `createdAt` DATETIME not null.
* `lastAttemptAt` DATETIME nullable.
* `attemptCount` INTEGER not null default 0.

---

# 11. Domain Models

Create immutable Dart model classes manually with:

* constructor
* `copyWith`
* `fromJson`
* `toJson` where relevant
* equality if useful

Do not use Freezed.

## `Track`

Fields:

* `id`
* `title`
* `artist`
* `album`
* `durationSeconds`
* `coverUrl`
* `localCoverPath`
* `sourceId`
* `resultId`
* `trackKey`
* `baseTrackKey`
* `availability`
* `localPath`
* `localOrigin`
* `isLiked`
* `lastPlayedAt`
* `createdAt`
* `updatedAt`

Computed:

* `isDownloaded`: `localPath != null && localOrigin == downloaded`
* `isImported`: `localPath != null && localOrigin == imported`
* `isLocalPlayable`: `localPath != null`
* `isServerCached`: `availability.inServerCache == true`
* `isOnDevice`: `availability.onDevice == true || isDownloaded`
* `isMix`: `durationSeconds != null && durationSeconds! > 600`
* `displayArtist`: fallback `"Unknown Artist"`
* `displayDuration`: `m:ss` or `h:mm:ss`

## `TrackAvailability`

Fields:

* `inServerCache`
* `onDevice`
* `cacheKey`
* `preferredOrigin`

`preferredOrigin` enum:

* `device`
* `server`
* `remote`
* `local`

## `SourceInfo`

Fields:

* `id`
* `name`
* `available`
* `supportsSearch`
* `supportsStream`
* `supportsDownload`

## `Playlist`

Fields:

* `id`
* `name`
* `coverPath`
* `specialType`
* `createdAt`
* `updatedAt`

Computed:

* `isFavorite`

## `AppSettings`

Fields:

* `themeMode`: `pureDark`, `dark`, `white`
* `glowMode`: `static`, `dynamic`
* `backendBaseUrl`
* `deviceId`
* `selectedSourceIds`
* `searchLimit`

Defaults:

* `themeMode = dark`
* `glowMode = static`
* `backendBaseUrl = null`
* `searchLimit = 25`

## `ServerStatus`

Enum/state object:

* `notConfigured`
* `unknown`
* `checking`
* `connected`
* `problem(message)`

UI colors:

* Green = connected.
* Yellow = unknown/checking.
* Red = problem.
* Gray = not configured.

---

# 12. Appearance / Theme Requirements

Themes:

## Pure Dark

* Background: true black `#000000`.
* Surface: near-black `#080808`.
* Primary text: white.
* Secondary text: gray.
* Borders: subtle white opacity.

## Dark

* Background: `#0B0B0F`.
* Surface: `#141419`.
* Elevated surface: `#1D1D24`.
* Primary text: white.
* Secondary text: soft gray.

## White

* Background: `#FAFAFA`.
* Surface: `#FFFFFF`.
* Elevated surface: `#F1F1F3`.
* Primary text: near-black.
* Secondary text: gray.

Glow:

* Static glow: subtle RGB gradient accent, mostly cyan/magenta/blue, used only on focused/active elements.
* Dynamic glow: based on current track cover if available; fallback to static glow.
* Do not put gradient everywhere.
* Do not make the design look like generic AI-generated neon.
* Glow is an accent, not the main design.

Buttons:

* Different states:

  * active
  * unavailable
  * ready to press
  * loading
* Use subtle neumorphism:

  * soft shadows
  * pressed scale animation
  * inner-ish highlight via layered containers
* Active buttons can glow.
* Unavailable buttons are visually disabled and do not trigger actions.
* Button press animation:

  * scale to 0.96
  * opacity/brightness shift
  * spring back.

Animation rules:

* Use smooth 250-450ms transitions.
* Use curves similar to iOS ease-out / emphasized easing.
* Use implicit animations for simple state changes.
* Use explicit controllers for player open/close, mini-player swipe, tab bar indicator, and “cannot go next/prev” rubber-band animation.
* Respect reduce motion if accessible through platform setting where practical.

---

# 13. Navigation

Use `go_router`.

Routes:

* `/` shell with tabs.
* `/home`
* `/search`
* `/playlists`
* `/playlists/:playlistId`
* `/library`
* `/settings`
* `/player`

Rules:

* Main tab shell contains:

  * Home
  * Search
  * Playlists
  * Library
* Settings is full-screen and not inside tab bar.
* Player is full-screen overlay-style route.
* Mini-player persists above tab bar when something is loaded/playing.
* Switching tabs must keep each tab state alive.
* Use indexed stack for tab body.
* Use animated transitions between tabs.
* Use Hero/shared element where useful for cover art.

---

# 14. Tab Bar

Create custom `GlassTabBar`.

Tabs:

1. Home
2. Search
3. Playlists
4. Library

Design:

* Centered floating pill.
* Bottom safe-area aware.
* Rounded.
* Frosted/glass look using `BackdropFilter`.
* Content beneath subtly visible.
* Current page highlighted according to theme.
* Highlight is a moving pill/capsule.
* Use icons + labels or icons only with active label; choose icons + compact active label.
* Inspired by iOS 26 tab bars:

  * floating
  * translucent
  * softly animated
  * readable
* Do not make it huge.
* Do not block mini-player.

Animation:

* Indicator slides between tabs.
* Selected tab scales slightly.
* Icon/text opacity changes.
* 300ms duration.
* Smooth curve.

---

# 15. Screens

## 15.1 Home Screen

Sections:

1. Header:

   * “Sleewave”
   * settings button.
2. Host info card:

   * appears only if backend URL is configured.
   * title: “Online Library”
   * status dot:

     * green connected
     * yellow checking/unknown
     * red problem
     * gray not configured
   * short status text.
   * tap opens Settings > Online Library.
3. Playlists:

   * show only if user has playlists or Favorite has tracks.
   * Favorite playlist exists by default.
   * show horizontal cards.
4. Recently played:

   * show if there are recent tracks.
   * use compact song cards.
5. Saved on server:

   * show if backend connected and `/saved-songs` returns songs.
   * use backend docs for tracks.
   * show empty text if connected but no saved songs:

     * “No server-cached tracks yet.”
6. Offline library preview:

   * show recent downloaded/imported songs if available.

Loading:

* Home can render immediately from local DB.
* Server sections show skeleton/loading while refreshing.

Actions:

* Tap track: play it.
* Long press track: add to playlist.
* Like button toggles Favorite.
* Download button downloads if remote/server.
* Delete button deletes if downloaded/local.

## 15.2 Song Cards

Create reusable `SongCard`.

Must support:

* Normal/list mode.
* Compact mode.
* Large featured mode if needed.
* Cover art.
* Title.
* Artist.
* Album optional.
* Duration.
* Badges:

  * Downloaded
  * Online
  * Liked
  * Mix
* Source name if available, but only from backend runtime source object.
* Animated active/playing state.
* Focus glow around currently playing track.
* Visual priority:

  * downloaded/local = strongest availability badge
  * server cached = “Online”
  * remote = no availability badge or subtle “Remote”
* Long tap opens add-to-playlist sheet.
* Tap plays.
* Trailing buttons:

  * like/unlike
  * download/delete depending state
  * more menu.

Mix rule:

* Track is a mix if `durationSeconds > 600`.

Search ranking impact:

* Local downloaded matching tracks displayed first.
* Backend `on_device` displayed before server cached.
* Server cached before remote.
* Liked tracks can be slightly boosted within same group but do not break arrival rendering too much.

## 15.3 Search Screen

UI:

* Search bar at top.
* Source chips below.
* Results list below.
* Empty state:

  * “Search your Online Library sources.”
  * If no backend: “Connect Online Library in Settings or use your offline Library.”
* Loading state:

  * show current searching status.
  * tracks appear one by one.
* Warning state:

  * show small non-blocking source warning chips/snackbars.
* Error state:

  * show retry.

Behavior:

* Fetch sources from backend; never hard-code.
* Search only when:

  * backend connected.
  * query trim length > 0.
  * at least one available source selected.
* On query change:

  * debounce 350ms.
  * cancel previous search.
* Before remote SSE:

  * search local DB for downloaded/imported tracks matching title/artist/album.
  * display local matches immediately under “On this device”.
* Then append SSE results under:

  * “Downloaded”
  * “On Online Library”
  * “Results”
* Use one continuous list with group labels.
* Deduplicate local and backend results.
* User can:

  * stream/play result.
  * download result.
  * delete if downloaded.
  * like/unlike.
  * add to playlist.

Download behavior:

* If already downloaded: button state “Downloaded”; pressing opens delete confirmation or local file action.
* If server cached: show download button with “fast” subtle indicator.
* If remote: normal download progress.

## 15.4 Playlists Screen

Top-level playlist screen:

* Show Favorite playlist first.
* Show user playlists.
* Add playlist button.
* Playlist cards show:

  * name
  * track count
  * cover image:

    * custom cover if set.
    * otherwise first track cover.
    * otherwise generated gradient/neutral cover.
* Allow rename/delete for normal playlists.
* Favorite cannot be deleted.

Playlist detail screen:

* Show playlist name.
* Show playlist cover.
* Show list of song cards.
* Allow reorder if not too complex; implement simple drag reorder if feasible, otherwise provide stable ordering by `position`.
* Remove from playlist action.
* Like/unlike tracks.
* Play all.
* Shuffle play.
* Empty state.

Favorite playlist:

* Mirrors `tracks.isLiked == true`.
* Do not duplicate state separately.
* Favorite playlist detail uses liked tracks.

## 15.5 Library Screen

Purpose:

* Shows local app-managed audio library.

UI:

* Header:

  * current folder label: “Sleewave Library”
  * actual app folder path below in small text.
* Import button.
* Sections:

  * Downloaded
  * Imported
* Song cards for local files.

Import behavior:

* Use `file_picker`.
* Allow audio extensions:

  * mp3
  * m4a
  * aac
  * wav
  * flac
  * ogg if platform supports playback
* Copy selected files into `Sleewave/Imported`.
* Do not just store external file path because iOS access may not persist.
* Read metadata using `audio_metadata_reader`:

  * title
  * artist
  * album
  * duration
  * cover if available
* If metadata missing:

  * title from filename.
  * artist = “Unknown Artist”.
* Store imported tracks in DB.
* Imported tracks are local-only and not sent to backend sync unless they have backend keys, which they normally do not.
* Imported tracks can be liked and added to playlists.

Delete behavior:

* Downloaded backend track:

  * delete file.
  * keep track metadata if it has backend identity.
  * set `localPath = null`, `localOrigin = remoteOnly/serverCached` based on availability.
  * remove on-device state locally.
  * call `/device-library/sync` with remaining backend-keyed local tracks.
* Pure imported track:

  * delete file.
  * remove from playlists.
  * remove DB row.

## 15.6 Settings Screen

Settings is full-screen, no tab bar.

Sections:

### Appearance

Controls:

* Theme:

  * Pure Dark
  * Dark
  * White
* Glow:

  * Static
  * Dynamic

Apply immediately.

### Online Library

Status card:

* Gray: Not set up / not connected.
* Yellow: Unknown / checking.
* Green: Connected.
* Red: Problem. Show problem text.

Instruction block:

```text
Sleewave works offline. You can optionally connect your own Online Library server.

1. Prepare a server or VPS.
2. Clone and run the Sleewave backend on your server.
3. Paste your server link here.
4. Press Check.
```

Add button/link:

* “Open setup guide”
* uses `backendSetupRepoUrl` from config.

Fields:

* Server URL input.
* Device name input.

Buttons:

* Check:

  * normalize URL.
  * call `/sources`.
  * update status.
  * show returned sources.
* Save:

  * save URL and device name.
  * trigger source refresh and sync.
* Clear:

  * remove backend URL.
  * set status notConfigured.
  * keep local music and playlists.

Device name:

* Default generated if missing:

  * `device-xxxxxx`
* Editable.
* Validate:

  * min 3 chars
  * max 40 chars
  * allowed: letters, numbers, dash, underscore
* Use as `device_id`.

Sources list:

* Show sources returned by backend.
* Available sources have active indicator.
* Unavailable sources are disabled.
* No source names hard-coded.

### Other Settings

Create placeholder section with:

* “More settings will appear here later.”

Do not add fake features.

---

# 16. Player and Mini-Player

Use a central `PlaybackService` wrapping one `AudioPlayer`.

## Playback source decision

When user plays a track:

1. If `track.localPath` exists and file exists:

   * play local file.
2. Else if `track.resultId` exists:

   * play server stream URL `GET /stream/{result_id}` through `just_audio`.
3. Else if track has backend keys but no result ID:

   * try refresh from `/saved-songs`.
   * if found, play.
4. Else show “Track is unavailable.”

Use `availability.preferredOrigin`:

* `device`: local file first.
* `server`: backend stream.
* `remote`: backend stream, may buffer longer.
* `local`: local file.

## Mini-player

Appears when:

* a track is loaded
* playing
* paused
* buffering

UI:

* cover thumbnail.
* title.
* artist.
* play/pause or stop button.
* moving current time.
* progress bar showing remaining/progress.
* swipe left/right:

  * next/previous if possible.
  * if not possible, show rubber-band “cannot” animation.
* tap opens full player.
* swipe up opens full player.

Animation:

* slides/fades in from bottom.
* sits above tab bar.
* respects safe area.
* uses blur/glass or dark surface depending theme.
* active track glow subtle.

Stop button:

* Stops playback.
* Keeps mini-player collapsed with last track or hides it according to state:

  * Use this fixed behavior: after stop, hide mini-player after 250ms fade unless user is on full player.

## Full player

Full-screen.

Open:

* from mini-player tap/swipe up.
* from track card if already playing.

Close:

* swipe down from top/full screen.
* close button.
* route pop.

UI:

* cover art large.
* title.
* artist.
* album optional.
* progress slider.
* elapsed and remaining time.
* controls:

  * previous
  * play/pause
  * next
  * playback mode button
* secondary controls:

  * like
  * add to playlist
  * download/delete
  * queue

Playback mode button cycles exactly:

1. Normal
2. Shuffle
3. Repeat all
4. Repeat one
5. Normal

Map to `just_audio`:

* Normal:

  * shuffle off
  * loop off
* Shuffle:

  * shuffle on
  * loop off
* Repeat all:

  * shuffle off unless previous shuffle mode intentionally retained? Use fixed rule: shuffle off.
  * loop all
* Repeat one:

  * shuffle off
  * loop one

Queue:

* Show queue panel.
* Show next track in queue.
* Allow tapping queued item to jump.
* Allow remove from queue except current track.
* Preserve queue across mini/full player.

Swipe gestures:

* Swipe left = next.
* Swipe right = previous.
* If unavailable, trigger cannot animation.
* Do not accidentally conflict with seek slider.

Background playback:

* Initialize `just_audio_background`.
* Set MediaItem tags:

  * id = track id or result id
  * title
  * artist
  * album
  * artUri from cover URL or local cover if available
* Lock screen controls should work.

Recently played:

* When a track starts successfully, update `recent_tracks`.
* Increment play count.
* Set `lastPlayedAt`.

---

# 17. Backend Sync Details

Create `SyncService`.

On startup and after local library changes:

* Gather tracks with:

  * localPath exists
  * trackKey not null
  * baseTrackKey not null
* POST `/device-library/sync`.
* Store result but do not block UI.

After successful download:

* Call `/device-library/confirm-download`.
* If confirm fails:

  * create pending action.
  * retry later on app startup or when Online Library reconnects.

Pending action retry:

* On backend status connected:

  * retry pending actions oldest first.
  * max attempts per app session: 3.
  * exponential-ish delay is fine, but do not overcomplicate.
* If success, delete pending action.

---

# 18. API Client Design

Create:

* `ApiClient`

  * holds Dio
  * base URL from settings
  * timeout config
  * JSON parsing
  * error mapping
* `SseClient`

  * search stream parser
* `BackendRepository`

  * high-level backend operations:

    * `checkHealth`
    * `getSources`
    * `search`
    * `getSavedSongs`
    * `getStreamUrl`
    * `downloadTrack`
    * `syncDeviceLibrary`
    * `confirmDownload`

Timeouts:

* connect timeout: 10 seconds.
* receive timeout regular JSON: 20 seconds.
* search SSE receive timeout: no short timeout while events are active; allow long stream but cancel on user action.
* download: longer timeout; progress-based.

URL normalization:

* trim whitespace.
* remove trailing slash.
* require `http` or `https`.
* reject empty except clearing setting.

---

# 19. Search Implementation Details

`SearchViewModel` state:

* query
* selected source IDs
* available sources
* local matches
* streamed results
* warnings
* isSearching
* error
* hasBackend
* status

Methods:

* `loadSources()`
* `setQuery(String)`
* `toggleSource(String sourceId)`
* `searchNow()`
* `cancelSearch()`
* `playTrack(Track)`
* `downloadTrack(Track)`
* `deleteTrack(Track)`
* `toggleLike(Track)`
* `openAddToPlaylist(Track)`

Search flow:

1. Trim query.
2. If query empty, clear streamed results but keep suggestions maybe no.
3. Search local DB immediately.
4. Validate backend connected.
5. Build source list from selected available sources.
6. Start SSE.
7. On `start`, set searching true.
8. On each `track`, merge into local repository and UI state.
9. On `warning`, add non-blocking warning.
10. On `done`, set searching false.
11. On error, set searching false, show error.

Deduping:

* If backend track matches local downloaded track by `trackKey`, merge availability/resultId into existing local track.
* Preserve localPath.
* Update resultId if newer.
* Update cover/album if local missing.
* If duplicate remote result, keep the better one:

  * onDevice beats server beats remote.
  * with cover beats no cover.
  * with duration beats no duration.

---

# 20. Download Implementation Details

`DownloadService`:

* Keeps per-track progress map.
* Exposes stream/provider of progress.
* Prevents duplicate simultaneous downloads of same track.
* Downloads with `device_id`.
* Uses safe temp path:

  * `Downloads/.tmp/{uuid}.mp3`
* On success:

  * move to final file path.
  * update DB local path and origin downloaded.
  * call confirm-download.
  * update Favorite/playlist track references automatically because same track ID.
* On failure:

  * delete temp file.
  * update progress error.
  * show friendly message.

Download button states:

* Downloaded:

  * icon check/downloaded.
  * tap shows bottom sheet:

    * Play local
    * Delete download
* Downloading:

  * progress ring.
  * disable duplicate tap.
* Server cached:

  * normal download icon with tiny “cached/fast” badge.
* Remote:

  * normal download icon.

---

# 21. Playlists Behavior

Add-to-playlist sheet:

* Open from long press or player button.
* Shows:

  * Favorite toggle at top.
  * existing playlists with checkbox.
  * create playlist field/button.
* Toggling Favorite updates `isLiked`.
* Adding to normal playlist creates `playlist_tracks`.
* Removing from playlist possible in playlist detail.

Playlist ordering:

* Use `position`.
* New track position = max + 1.
* If duplicate add, do nothing and show small “Already in playlist.”

Playlist deletion:

* Deletes playlist row and playlist_tracks.
* Does not delete tracks/files.

---

# 22. UI Copy

Use clean English.

Examples:

* “Online Library”
* “Connected”
* “Checking…”
* “Not connected”
* “No server-cached tracks yet.”
* “Search your Online Library sources.”
* “Connect Online Library in Settings or use your offline Library.”
* “Already downloaded”
* “Download failed. Try again.”
* “Track is unavailable.”
* “Imported”
* “Downloaded”
* “Mix”
* “Favorite”

Do not use slang in app UI.

---

# 23. Accessibility

Implement:

* tappable targets at least 44x44.
* semantic labels for:

  * play/pause
  * next
  * previous
  * like
  * download
  * delete
  * add to playlist
  * tab buttons
* good contrast in all themes.
* do not rely only on glow/color for state; also use icons/text.

---

# 24. File Storage

Use `path_provider`.

Folders:

```text
<ApplicationDocumentsDirectory>/Sleewave/
<ApplicationDocumentsDirectory>/Sleewave/Downloads/
<ApplicationDocumentsDirectory>/Sleewave/Imported/
<ApplicationDocumentsDirectory>/Sleewave/Covers/
<ApplicationDocumentsDirectory>/Sleewave/.tmp/
```

Rules:

* Downloaded backend files go to Downloads.
* Imported files copied to Imported.
* Extracted covers saved to Covers if needed.
* Temporary download files go to `.tmp`.
* Clean stale temp files on startup.

---

# 25. iOS Config

Ensure:

* iOS deployment target compatible with current Flutter stable; use iOS 14+ minimum unless project defaults higher.
* Background audio capability:

  * configure for audio playback.
  * Info.plist includes background audio mode if required by packages.
* App display name:

  * Sleewave
* Local dev network:

  * support `http://127.0.0.1:8000` for simulator/debug.
  * do not add broad release unsafe network allowances if avoidable.

---

# 26. Testing Requirements

Add tests for:

1. SSE parser:

   * start event
   * track event
   * warning event
   * done event
   * multi-event stream
2. API error mapping:

   * 404 `search_result_not_found`
   * 409 `track_already_on_device`
   * 503 `provider_unavailable`
3. Track computed fields:

   * `isMix` true above 600s.
   * downloaded/local state.
4. Playlist repository:

   * Favorite playlist creation.
   * Add/remove track.
5. Search merge logic:

   * local downloaded beats remote.
   * server cached beats remote.
   * duplicate by track key merges.
6. Settings:

   * device ID generation format.
   * URL normalization.

Use `flutter_test` and `mocktail`.

---

# 27. Implementation Order

Follow this exact order:

1. Create/verify Flutter project structure.
2. Add dependencies.
3. Implement core models.
4. Implement Drift tables/DAOs.
5. Implement file storage and metadata services.
6. Implement settings repository and device ID generation.
7. Implement API client, backend repository, SSE parser.
8. Implement sync service.
9. Implement download service.
10. Implement playback service with just_audio/background setup.
11. Implement shared UI widgets:

    * SongCard
    * GlowButton
    * GlassTabBar
    * CoverArt
    * Empty/Error/Loading states
12. Implement shell/navigation.
13. Implement Home.
14. Implement Search.
15. Implement Playlists.
16. Implement Library.
17. Implement Settings.
18. Implement MiniPlayer and full Player.
19. Add tests.
20. Run:

    * `dart format .`
    * `flutter analyze`
    * `flutter test`
21. Fix all analyzer/test issues.

---

# 28. Acceptance Criteria

The task is done only when all are true:

* App launches on iOS simulator.
* Code is structured under `core/` and `functions/`.
* No major screen is implemented inside `main.dart`.
* Home tab exists.
* Search tab exists.
* Playlists tab exists.
* Library tab exists.
* Settings opens full-screen without tab bar.
* Floating animated tab bar works.
* Mini-player appears after starting playback.
* Full player opens from mini-player.
* Local imported file can be played.
* Backend URL can be set.
* `/sources` check updates Online Library status.
* `/search` streams track cards one by one.
* Server stream playback uses `/stream/{result_id}` URL.
* Download uses `/download/{result_id}?device_id=...`.
* Successful download saves MP3 locally.
* Successful download calls `/device-library/confirm-download`.
* Startup calls `/device-library/sync` when backend configured.
* `/saved-songs` is shown on Home when connected.
* Favorite playlist mirrors liked songs.
* Custom playlists are local.
* Song cards show downloaded/server/liked/mix indicators.
* `result_id` expiry recovery is implemented.
* No provider brand names are hard-coded in UI strings, comments, enum names, or marketing copy.
* `flutter analyze` passes.
* `flutter test` passes.

---

# 29. Final Response Format from Codex

When finished, respond with:

1. Short summary of what was built.
2. Files/folders created or changed.
3. Commands run.
4. Test/analyzer results.
5. Any honest limitations if something could not be completed.

Do not merely describe what should be done. Implement the code.

```
::contentReference[oaicite:3]{index=3}
```

[1]: https://docs.flutter.dev/app-architecture/guide?utm_source=chatgpt.com "Guide to app architecture"
