import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/playback_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_button.dart';
import '../view_models/player_view_model.dart';

class PlaybackModeButton extends ConsumerWidget {
  const PlaybackModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(playerViewModelProvider);
    final snapshot = vm.state.snapshot;
    final mode = snapshot.mode;
    final playbackAccent = context.palette.accent;
    final icon = switch (mode) {
      PlaybackMode.normal => Icons.arrow_right_alt_rounded,
      PlaybackMode.shuffle => Icons.shuffle_rounded,
      PlaybackMode.repeatAll => Icons.repeat_rounded,
      PlaybackMode.repeatOne => Icons.repeat_one_rounded,
    };
    return GlowButton(
      icon: icon,
      active: mode != PlaybackMode.normal,
      accentColor: playbackAccent,
      onPressed: vm.cycleMode,
      semanticLabel: 'Playback mode',
    );
  }
}
