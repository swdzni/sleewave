import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/song_card.dart';
import '../view_models/player_view_model.dart';

class QueuePanel extends ConsumerWidget {
  const QueuePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueServiceProvider).queue;
    final player = ref.read(playerViewModelProvider);
    if (queue.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Queue', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final track in queue)
          SongCard(
            track: track,
            mode: SongCardMode.compact,
            onTap: () => player.play(track, queue: queue),
          ),
      ],
    );
  }
}
