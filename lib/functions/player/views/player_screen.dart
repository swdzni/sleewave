import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/cover_art.dart';
import '../../../core/widgets/track_badges.dart';
import '../view_models/player_view_model.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_track_actions.dart';
import '../widgets/swipe_dismiss_layer.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  Duration? _dragPosition;

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(playerViewModelProvider);
    final snapshot = vm.state.snapshot;
    final track = snapshot.currentTrack;
    final displayedPosition = _dragPosition ?? snapshot.position;
    final tokens = context.themeTokens;
    return SwipeDismissLayer(
      onDismiss: context.pop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: BoxDecoration(color: context.palette.background),
          child: SafeArea(
            child: track == null
                ? Center(
                    child: Text(
                      'Track is unavailable.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: context.palette.secondaryText.withValues(
                                alpha: 0.45,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Close',
                              onPressed: context.pop,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: track.isLiked ? 'Unlike' : 'Like',
                              onPressed: () async {
                                final updated = await ref
                                    .read(trackRepositoryProvider)
                                    .toggleLike(track);
                                ref
                                    .read(playerViewModelProvider)
                                    .replaceCurrentTrack(updated);
                                notifyLibraryChangedFromWidget(ref);
                              },
                              icon: Icon(
                                track.isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: track.isLiked
                                    ? context.palette.danger
                                    : context.palette.secondaryText,
                              ),
                            ),
                            IconButton(
                              tooltip: 'More',
                              onPressed: () => showPlayerTrackActions(
                                context: context,
                                ref: ref,
                                track: track,
                              ),
                              icon: const Icon(Icons.more_horiz_rounded),
                            ),
                          ],
                        ),
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: GestureDetector(
                              onLongPress: () {
                                AppHaptics.medium();
                                showPlayerTrackActions(
                                  context: context,
                                  ref: ref,
                                  track: track,
                                );
                              },
                              child: Hero(
                                tag: 'cover-${track.id}',
                                child: CoverArt(
                                  coverUrl: track.coverUrl,
                                  localCoverPath: track.localCoverPath,
                                  size: 300,
                                  borderRadius: tokens.coverRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          track.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          track.displayArtist,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: context.palette.secondaryText),
                        ),
                        const SizedBox(height: 12),
                        TrackBadges(track: track),
                        const SizedBox(height: 20),
                        Slider(
                          value: snapshot.duration.inMilliseconds == 0
                              ? 0
                              : displayedPosition.inMilliseconds
                                    .clamp(0, snapshot.duration.inMilliseconds)
                                    .toDouble(),
                          max: snapshot.duration.inMilliseconds == 0
                              ? 1
                              : snapshot.duration.inMilliseconds.toDouble(),
                          onChangeStart: (value) {
                            setState(
                              () => _dragPosition = Duration(
                                milliseconds: value.round(),
                              ),
                            );
                          },
                          onChanged: (value) {
                            setState(
                              () => _dragPosition = Duration(
                                milliseconds: value.round(),
                              ),
                            );
                          },
                          onChangeEnd: (value) async {
                            final next = Duration(milliseconds: value.round());
                            setState(() => _dragPosition = next);
                            await vm.seek(next);
                            if (mounted) {
                              setState(() => _dragPosition = null);
                            }
                          },
                        ),
                        Row(
                          children: [
                            Text(
                              _format(displayedPosition),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Spacer(),
                            Text(
                              '-${_format(snapshot.duration - displayedPosition)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const PlayerControls(),
                        if (snapshot.error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            snapshot.error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: context.palette.warning),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _format(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final minutes = safe.inMinutes;
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
