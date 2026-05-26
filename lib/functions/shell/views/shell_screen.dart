import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/glass_tab_bar.dart';
import '../../player/view_models/player_view_model.dart';
import '../../player/widgets/mini_player.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  String? _lastPlaybackErrorKey;
  _PlaybackErrorData? _playbackError;
  Timer? _playbackErrorTimer;

  @override
  void dispose() {
    _playbackErrorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playerViewModelProvider.select((vm) => vm.state.snapshot), (
      previous,
      next,
    ) {
      final error = next.error;
      if (error == null) {
        _lastPlaybackErrorKey = null;
        return;
      }
      final track = next.currentTrack;
      final key = '${track?.id ?? 'unknown'}|$error';
      if (_lastPlaybackErrorKey == key) {
        return;
      }
      _lastPlaybackErrorKey = key;
      _showPlaybackError(
        title: _playbackErrorTitle(error, hasTrack: track != null),
        message: track == null ? error : '${track.title}\n$error',
        serious: _isSeriousPlaybackError(error),
      );
    });

    final currentIndex = widget.navigationShell.currentIndex;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: widget.navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: AppDurations.state,
                  child: _playbackError == null
                      ? const SizedBox.shrink()
                      : Padding(
                          key: ValueKey(_playbackError!.message),
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                          child: _PlaybackErrorBanner(data: _playbackError!),
                        ),
                ),
                const MiniPlayer(),
                const SizedBox(height: 8),
                GlassTabBar(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    widget.navigationShell.goBranch(
                      index,
                      initialLocation: index == currentIndex,
                    );
                    if (index == 0) {
                      ref
                          .read(appStartupControllerProvider)
                          .refreshBackend(keepConnectedStatus: true);
                    }
                  },
                  items: const [
                    GlassTabItem(
                      label: 'Home',
                      icon: Icons.home_rounded,
                      semanticLabel: 'Home tab',
                    ),
                    GlassTabItem(
                      label: 'Search',
                      icon: Icons.search_rounded,
                      semanticLabel: 'Search tab',
                    ),
                    GlassTabItem(
                      label: 'Playlists',
                      icon: Icons.queue_music_rounded,
                      semanticLabel: 'Playlists tab',
                    ),
                    GlassTabItem(
                      label: 'Library',
                      icon: Icons.library_music_rounded,
                      semanticLabel: 'Library tab',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaybackError({
    required String title,
    required String message,
    required bool serious,
  }) {
    AppHaptics.light();
    _playbackErrorTimer?.cancel();
    if (mounted) {
      setState(() {
        _playbackError = _PlaybackErrorData(
          title: title,
          message: message,
          serious: serious,
        );
      });
    }
    _playbackErrorTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) {
        return;
      }
      setState(() => _playbackError = null);
    });
  }

  String _playbackErrorTitle(String message, {required bool hasTrack}) {
    if (message.startsWith('Skipped ')) {
      return 'Skipped track';
    }
    if (message.contains('No playable')) {
      return 'Playback stopped';
    }
    return hasTrack ? 'Playback issue' : 'Playback failed';
  }

  bool _isSeriousPlaybackError(String message) {
    final lower = message.toLowerCase();
    return !lower.startsWith('skipped ') ||
        lower.contains('no playable') ||
        lower.contains('offline') ||
        lower.contains('failed');
  }
}

class _PlaybackErrorData {
  const _PlaybackErrorData({
    required this.title,
    required this.message,
    required this.serious,
  });

  final String title;
  final String message;
  final bool serious;
}

class _PlaybackErrorBanner extends StatelessWidget {
  const _PlaybackErrorBanner({required this.data});

  final _PlaybackErrorData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tokens = context.themeTokens;
    final accent = data.serious ? palette.danger : palette.warning;
    final lines = data.message.split('\n');
    final body = lines.length <= 1 ? data.message : lines.skip(1).join('\n');
    final track = lines.length <= 1 ? null : lines.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.elevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(tokens.rowRadius),
        border: Border.all(color: accent.withValues(alpha: 0.46)),
        boxShadow: palette.shadow.a == 0
            ? null
            : [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: tokens.shadowBlur,
                  offset: tokens.shadowOffset,
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              data.serious
                  ? Icons.error_outline_rounded
                  : Icons.warning_amber_rounded,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (track != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      track,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
