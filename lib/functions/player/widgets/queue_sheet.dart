import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list_tile.dart';
import '../../../core/widgets/cover_art.dart';
import '../../../core/widgets/now_playing_bars.dart';
import '../view_models/player_view_model.dart';

Future<void> showQueueSheet(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Queue',
    barrierColor: Colors.transparent,
    transitionDuration: AppDurations.sheet,
    pageBuilder: (context, animation, secondaryAnimation) {
      return _QueueDialog(animation: animation);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppCurves.standard,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

class _QueueDialog extends ConsumerWidget {
  const _QueueDialog({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(animation.value);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12 * value, sigmaY: 12 * value),
          child: ColoredBox(
            color: context.palette.background.withValues(alpha: 0.42 * value),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.58,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 220),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: _QueueSheetBody(),
    );
  }
}

class _QueueSheetBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;
    final queueService = ref.watch(queueServiceProvider);
    final queue = queueService.queue;
    final playbackSnapshot = ref.watch(playerViewModelProvider).state.snapshot;
    final currentTrackId = playbackSnapshot.currentTrack?.id;
    final onlineAvailable = ref.watch(backendRepositoryProvider) != null;
    return Dismissible(
      key: const ValueKey('queue-sheet'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.pop(context),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: context.palette.elevated,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(tokens.sheetRadius),
            ),
            border: Border(top: BorderSide(color: context.palette.border)),
            boxShadow: context.palette.shadow.a == 0
                ? null
                : [
                    BoxShadow(
                      color: context.palette.shadow,
                      blurRadius: tokens.shadowBlur + 14,
                      offset: -tokens.shadowOffset,
                    ),
                  ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.palette.secondaryText.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 10, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Queue',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: queue.isEmpty
                      ? Center(
                          child: Text(
                            'Queue is empty.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.compactScreen,
                            0,
                            AppSpacing.compactScreen,
                            AppSpacing.screen,
                          ),
                          itemCount: queue.length,
                          onReorder: ref.read(queueServiceProvider).reorder,
                          itemBuilder: (context, index) {
                            final track = queue[index];
                            final active = currentTrackId == track.id;
                            final playable =
                                track.isLocalPlayable ||
                                (track.resultId != null && onlineAvailable);
                            final palette = context.palette;
                            return AppListTile(
                              key: ValueKey('queue-${track.id}-$index'),
                              active: active,
                              enabled: playable,
                              onTap: () => ref
                                  .read(playerViewModelProvider)
                                  .jumpToQueueIndex(index),
                              child: Row(
                                children: [
                                  CoverArt(
                                    coverUrl: track.coverUrl,
                                    localCoverPath: track.localCoverPath,
                                    size: 44,
                                    borderRadius: tokens.coverRadius,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: active
                                                    ? palette.accent
                                                    : playable
                                                    ? palette.primaryText
                                                    : palette.secondaryText,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          active
                                              ? '${playbackSnapshot.isPlaying ? 'Playing now' : 'Paused'} · ${track.displayArtist}'
                                              : playable
                                              ? track.displayArtist
                                              : 'Unavailable offline · ${track.displayArtist}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: playable
                                                    ? palette.secondaryText
                                                    : palette.tertiaryText,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  active
                                      ? NowPlayingBars(
                                          color: palette.accent,
                                          playing: playbackSnapshot.isPlaying,
                                        )
                                      : Icon(
                                          playable
                                              ? Icons.drag_handle_rounded
                                              : Icons.block_rounded,
                                          color: playable
                                              ? palette.secondaryText
                                              : palette.tertiaryText,
                                        ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
