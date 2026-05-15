import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../view_models/playlists_view_model.dart';
import '../widgets/playlist_card.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(playlistsViewModelProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(playlistsViewModelProvider);
    final state = vm.state;
    return AppScaffold(
      safeBottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 170),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Playlists',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              IconButton(
                tooltip: 'Add playlist',
                onPressed: () => _showCreateDialog(context, vm),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (state.playlists.isEmpty && !state.loading)
            const EmptyState(title: 'No playlists yet.')
          else
            for (final playlist in state.playlists)
              PlaylistCard(
                playlist: playlist,
                onTap: () => context.push('/playlists/${playlist.id}'),
              ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    PlaylistsViewModel vm,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) {
      await vm.create(name);
    }
  }
}
