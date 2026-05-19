import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/models/track.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/track_actions_sheet.dart';
import '../../playlists/widgets/add_to_playlist_sheet.dart';
import '../view_models/player_view_model.dart';

Future<void> showPlayerTrackActions({
  required BuildContext context,
  required WidgetRef ref,
  required Track track,
}) {
  final onlineAvailable = ref
      .read(appStartupControllerProvider)
      .status
      .isConnected;
  final sourceNames = {
    for (final source in ref.read(appStartupControllerProvider).sources)
      source.id: source.name,
  };
  return showTrackActionsSheet(
    context: context,
    track: track,
    sourceLabel: sourceNames[track.sourceId],
    onLike: () => _toggleLike(ref, track),
    onAddToPlaylist: () => _showAddToPlaylist(context, track),
    onDownload: onlineAvailable
        ? () => _downloadTrack(context, ref, track)
        : null,
    onShare: () => _shareTrack(context, ref, track),
    onDeleteLocal: () => _deleteLocalState(context, ref, track),
    onDeleteFromServer: onlineAvailable
        ? () => _deleteFromServer(context, ref, track)
        : null,
  );
}

Future<void> _toggleLike(WidgetRef ref, Track track) async {
  final updated = await ref.read(trackRepositoryProvider).toggleLike(track);
  ref.read(playerViewModelProvider).replaceCurrentTrack(updated);
  notifyLibraryChangedFromWidget(ref);
}

void _showAddToPlaylist(BuildContext context, Track track) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => AddToPlaylistSheet(track: track),
  );
}

Future<void> _downloadTrack(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final backend = ref.read(backendRepositoryProvider);
  if (backend == null) {
    _showMessage(context, 'Connect Online Library to download.');
    return;
  }
  if (track.resultId == null) {
    _showMessage(context, 'Refresh this track before download.');
    return;
  }
  try {
    final updated = await ref
        .read(downloadServiceProvider)
        .download(
          track: track,
          backend: backend,
          settings: ref.read(themeControllerProvider).settings,
        );
    if (updated != null) {
      ref.read(playerViewModelProvider).replaceCurrentTrack(updated);
      notifyLibraryChangedFromWidget(ref);
    }
  } on ApiException catch (error) {
    if (!context.mounted) {
      return;
    }
    _showMessage(context, error.message);
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    _showMessage(context, 'Download failed. Try again.');
  }
}

Future<void> _deleteLocalState(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  await ref.read(trackRepositoryProvider).deleteLocalState(track);
  final updated = await ref.read(trackRepositoryProvider).byId(track.id);
  if (updated != null) {
    ref.read(playerViewModelProvider).replaceCurrentTrack(updated);
  }
  notifyLibraryChangedFromWidget(ref);
}

Future<void> _shareTrack(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  try {
    await ref
        .read(trackShareServiceProvider)
        .share(
          track: track,
          settings: ref.read(themeControllerProvider).settings,
          backend: ref.read(backendRepositoryProvider),
        );
  } on ApiException catch (error) {
    if (!context.mounted) {
      return;
    }
    _showMessage(context, error.message);
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    _showMessage(context, error.toString());
  }
}

Future<void> _deleteFromServer(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final backend = ref.read(backendRepositoryProvider);
  final resultId = track.resultId;
  if (backend == null || resultId == null) {
    _showMessage(context, 'Connect Online Library first.');
    return;
  }
  try {
    final result = await backend.deleteTrack(resultId);
    final updated = await ref
        .read(trackRepositoryProvider)
        .markServerRemoved(track);
    if (updated != null) {
      ref.read(playerViewModelProvider).replaceCurrentTrack(updated);
    }
    await ref
        .read(appStartupControllerProvider)
        .refreshBackend(keepConnectedStatus: true);
    notifyLibraryChangedFromWidget(ref);
    if (!context.mounted) {
      return;
    }
    _showMessage(context, result.message);
  } on ApiException catch (error) {
    if (!context.mounted) {
      return;
    }
    _showMessage(context, error.message);
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    _showMessage(context, 'Could not delete from server.');
  }
}

void _showMessage(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
