import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cover_art.dart';
import '../view_models/player_view_model.dart';

Future<void> showQueueSheet(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Queue',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _QueueDialog(animation: animation);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.36),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
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
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12 * animation.value,
            sigmaY: 12 * animation.value,
          ),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.24 * animation.value),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.58,
          child: _QueueSheetBody(),
        ),
      ),
    );
  }
}

class _QueueSheetBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueService = ref.watch(queueServiceProvider);
    final queue = queueService.queue;
    final playbackSnapshot = ref.watch(playerViewModelProvider).state.snapshot;
    final currentTrackId = playbackSnapshot.currentTrack?.id;
    return Dismissible(
      key: const ValueKey('queue-sheet'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.pop(context),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: context.palette.border)),
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
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          itemCount: queue.length,
                          onReorder: ref.read(queueServiceProvider).reorder,
                          itemBuilder: (context, index) {
                            final track = queue[index];
                            final active = currentTrackId == track.id;
                            return ListTile(
                              key: ValueKey('queue-${track.id}-$index'),
                              tileColor: active
                                  ? context.palette.accent.withValues(
                                      alpha: 0.12,
                                    )
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: active
                                      ? context.palette.accent
                                      : Colors.transparent,
                                ),
                              ),
                              leading: CoverArt(
                                coverUrl: track.coverUrl,
                                localCoverPath: track.localCoverPath,
                                size: 42,
                                borderRadius: 8,
                              ),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: active
                                    ? TextStyle(color: context.palette.accent)
                                    : null,
                              ),
                              subtitle: Text(
                                active
                                    ? '${playbackSnapshot.isPlaying ? 'Playing now' : 'Paused'} · ${track.displayArtist}'
                                    : track.displayArtist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: active
                                  ? _PlayingBars(
                                      color: context.palette.accent,
                                      playing: playbackSnapshot.isPlaying,
                                    )
                                  : const Icon(Icons.drag_handle_rounded),
                              onTap: () => ref
                                  .read(playerViewModelProvider)
                                  .jumpToQueueIndex(index),
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

class _PlayingBars extends StatefulWidget {
  const _PlayingBars({required this.color, required this.playing});

  final Color color;
  final bool playing;

  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
      value: 0.5,
    );
    if (widget.playing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PlayingBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing == oldWidget.playing) {
      return;
    }
    if (widget.playing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = widget.playing ? _controller.value : 0.5;
        return SizedBox(
          width: 24,
          height: 22,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(8 + 9 * value),
              const SizedBox(width: 3),
              _bar(16 - 7 * value),
              const SizedBox(width: 3),
              _bar(10 + 6 * (1 - value)),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
