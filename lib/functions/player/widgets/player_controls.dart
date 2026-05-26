import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/glow_button.dart';
import '../view_models/player_view_model.dart';
import 'playback_mode_button.dart';
import 'queue_sheet.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(playerViewModelProvider);
    final snapshot = vm.state.snapshot;
    final playbackAccent = context.palette.accent;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlowButton(
          icon: Icons.skip_previous_rounded,
          onPressed: () {
            AppHaptics.light();
            vm.restartOrPrevious();
          },
          onLongPressStart: vm.beginRewind,
          onLongPressEnd: vm.endRewind,
          semanticLabel: 'Previous',
        ),
        const SizedBox(width: 16),
        GlowButton(
          icon: snapshot.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          active: true,
          accentColor: playbackAccent,
          onPressed: () {
            AppHaptics.light();
            vm.togglePlayPause();
          },
          semanticLabel: snapshot.isPlaying ? 'Pause' : 'Play',
        ),
        const SizedBox(width: 16),
        GlowButton(
          icon: Icons.skip_next_rounded,
          onPressed: () {
            AppHaptics.light();
            vm.next();
          },
          onLongPressStart: vm.beginFastForward,
          onLongPressEnd: vm.endFastForward,
          semanticLabel: 'Next',
        ),
        const SizedBox(width: 16),
        const PlaybackModeButton(),
        const SizedBox(width: 16),
        GlowButton(
          icon: Icons.queue_music_rounded,
          onPressed: () => showQueueSheet(context),
          semanticLabel: 'Queue',
        ),
      ],
    );
  }
}
