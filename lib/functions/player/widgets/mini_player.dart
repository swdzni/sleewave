import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/glow_theme.dart';
import '../../../core/widgets/cover_art.dart';
import '../../../core/widgets/now_playing_bars.dart';
import '../view_models/player_view_model.dart';
import 'player_track_actions.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(playerViewModelProvider);
    final snapshot = vm.state.snapshot;
    final track = snapshot.currentTrack;
    final tokens = context.themeTokens;
    final playbackAccent = GlowTheme.playbackAccent(
      mode: ref.watch(themeControllerProvider).settings.glowMode,
      track: track,
      fallback: context.palette.accent,
    );
    if (track == null) {
      return const SizedBox.shrink();
    }
    return AnimatedOpacity(
      opacity: snapshot.hasTrack ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/player');
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            showPlayerTrackActions(context: context, ref: ref, track: track);
          },
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -120) {
              context.push('/player');
            }
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -150) {
              vm.next();
            } else if (velocity > 150) {
              vm.restartOrPrevious();
            }
          },
          child: Container(
            height: AppSizes.miniPlayer,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.palette.elevated.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(tokens.floatingRadius),
              border: Border.all(color: context.palette.border),
              boxShadow: context.palette.shadow.a == 0
                  ? null
                  : [
                      BoxShadow(
                        color: context.palette.shadow,
                        blurRadius: tokens.shadowBlur,
                        offset: tokens.shadowOffset,
                      ),
                    ],
            ),
            child: Row(
              children: [
                CoverArt(
                  coverUrl: track.coverUrl,
                  localCoverPath: track.localCoverPath,
                  size: 50,
                  borderRadius: tokens.coverRadius,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        track.displayArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                NowPlayingBars(
                  color: playbackAccent,
                  playing: snapshot.isPlaying,
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
                  onPressed: snapshot.isBuffering ? null : vm.togglePlayPause,
                  icon: snapshot.isBuffering
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Icon(
                          snapshot.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                ),
                IconButton(
                  tooltip: 'Next',
                  onPressed: vm.next,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
