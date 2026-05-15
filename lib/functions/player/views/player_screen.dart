import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cover_art.dart';
import '../view_models/player_view_model.dart';
import '../widgets/player_controls.dart';
import '../widgets/queue_panel.dart';
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
        backgroundColor: context.palette.background,
        body: SafeArea(
          child: track == null
              ? Center(
                  child: Text(
                    'Track is unavailable.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Close',
                          onPressed: context.pop,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: track.isLiked ? 'Unlike' : 'Like',
                          onPressed: () => ref
                              .read(trackRepositoryProvider)
                              .toggleLike(track),
                          icon: Icon(
                            track.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
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
                    const SizedBox(height: 28),
                    Text(
                      track.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      track.displayArtist,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.palette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 24),
                    const PlayerControls(),
                    const SizedBox(height: 28),
                    const QueuePanel(),
                  ],
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
