import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cover_art.dart';
import '../../../core/widgets/track_badges.dart';
import '../view_models/player_view_model.dart';
import '../widgets/player_controls.dart';
import '../widgets/swipe_dismiss_layer.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(playerViewModelProvider);
    final snapshot = vm.state.snapshot;
    final track = snapshot.currentTrack;
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
                          ],
                        ),
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: Hero(
                              tag: 'cover-${track.id}',
                              child: CoverArt(
                                coverUrl: track.coverUrl,
                                localCoverPath: track.localCoverPath,
                                size: 300,
                                borderRadius: 18,
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
                              : snapshot.position.inMilliseconds
                                    .clamp(0, snapshot.duration.inMilliseconds)
                                    .toDouble(),
                          max: snapshot.duration.inMilliseconds == 0
                              ? 1
                              : snapshot.duration.inMilliseconds.toDouble(),
                          onChanged: (value) =>
                              vm.seek(Duration(milliseconds: value.round())),
                        ),
                        Row(
                          children: [
                            Text(_format(snapshot.position)),
                            const Spacer(),
                            Text(
                              '-${_format(snapshot.duration - snapshot.position)}',
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
