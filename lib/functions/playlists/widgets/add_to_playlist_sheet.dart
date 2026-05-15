import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/track.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/bottom_sheet_shell.dart';

class AddToPlaylistSheet extends ConsumerStatefulWidget {
  const AddToPlaylistSheet({super.key, required this.track});

  final Track track;

  @override
  ConsumerState<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<AddToPlaylistSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref.read(playlistRepositoryProvider).allPlaylists(),
      builder: (context, snapshot) {
        final playlists = snapshot.data ?? const [];
        return BottomSheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add to playlist',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final playlist in playlists)
                CheckboxListTile(
                  value: false,
                  title: Text(playlist.name),
                  onChanged: (_) async {
                    await ref
                        .read(playlistRepositoryProvider)
                        .addTrack(playlist.id, widget.track);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(labelText: 'New playlist'),
                onSubmitted: (_) => _create(context),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => _create(context),
                child: const Text('Create playlist'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _create(BuildContext context) async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    final playlist = await ref.read(playlistRepositoryProvider).create(name);
    await ref
        .read(playlistRepositoryProvider)
        .addTrack(playlist.id, widget.track);
    if (context.mounted) Navigator.pop(context);
  }
}
