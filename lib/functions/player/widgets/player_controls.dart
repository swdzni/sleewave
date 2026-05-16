import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlowButton(
          icon: Icons.skip_previous_rounded,
          onPressed: vm.restartOrPrevious,
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
          onPressed: vm.togglePlayPause,
          semanticLabel: snapshot.isPlaying ? 'Pause' : 'Play',
        ),
        const SizedBox(width: 16),
        GlowButton(
          icon: Icons.skip_next_rounded,
          onPressed: vm.next,
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
