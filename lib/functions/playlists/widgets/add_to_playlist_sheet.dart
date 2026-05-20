import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/playlist.dart';
import '../../../core/models/track.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/bottom_sheet_shell.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/cover_art.dart';
import '../../../core/theme/app_colors.dart';
import '../../player/view_models/player_view_model.dart';

class AddToPlaylistSheet extends ConsumerStatefulWidget {
  const AddToPlaylistSheet({super.key, required this.track});

  final Track track;

  @override
  ConsumerState<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<AddToPlaylistSheet> {
  final _controller = TextEditingController();
  late Future<List<Playlist>> _playlistsFuture;
  Track? _track;
  Set<String> _selectedPlaylistIds = {};
  String _filter = '';

  Track get _currentTrack => _track ?? widget.track;

  @override
  void initState() {
    super.initState();
    _track = widget.track;
    _playlistsFuture = _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return FutureBuilder<List<Playlist>>(
      future: _playlistsFuture,
      builder: (context, snapshot) {
        final playlists = (snapshot.data ?? const <Playlist>[]).where((
          playlist,
        ) {
          final query = _filter.trim().toLowerCase();
          return query.isEmpty || playlist.name.toLowerCase().contains(query);
        }).toList();
        return BottomSheetShell(
          child: SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add to playlist',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _TrackPreview(track: _currentTrack),
                const SizedBox(height: 10),
                AppSearchField(
                  placeholder: 'Filter playlists',
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child:
                      playlists.isEmpty &&
                          snapshot.connectionState != ConnectionState.waiting
                      ? Center(
                          child: Text(
                            _filter.trim().isEmpty
                                ? 'No playlists yet.'
                                : 'No matching playlists.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            final selected = _selectedPlaylistIds.contains(
                              playlist.id,
                            );
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              leading: Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.playlist_play_rounded,
                                color: selected
                                    ? context.palette.accent
                                    : context.palette.secondaryText,
                              ),
                              title: Text(
                                playlist.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('${playlist.trackCount} tracks'),
                              trailing: Icon(
                                selected
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                color: selected
                                    ? context.palette.accent
                                    : context.palette.secondaryText,
                              ),
                              onTap: () =>
                                  _setMembership(playlist, selected: !selected),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          labelText: 'New playlist',
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _create(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _create,
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Playlist>> _load() async {
    final playlists = await ref.read(playlistRepositoryProvider).allPlaylists();
    final selected = <String>{};
    for (final playlist in playlists) {
      if (await ref
          .read(playlistRepositoryProvider)
          .containsTrack(playlist.id, _currentTrack)) {
        selected.add(playlist.id);
      }
    }
    if (mounted) {
      setState(() => _selectedPlaylistIds = selected);
    } else {
      _selectedPlaylistIds = selected;
    }
    return playlists;
  }

  Future<void> _setMembership(
    Playlist playlist, {
    required bool selected,
  }) async {
    final repository = ref.read(playlistRepositoryProvider);
    final updated = selected
        ? await repository.addTrack(playlist.id, _currentTrack)
        : await repository.removeTrack(playlist.id, _currentTrack);
    _track = updated;
    ref.read(playerViewModelProvider).replaceCurrentTrack(updated);
    notifyLibraryChangedFromWidget(ref);
    setState(() {
      if (selected) {
        _selectedPlaylistIds.add(playlist.id);
      } else {
        _selectedPlaylistIds.remove(playlist.id);
      }
    });
  }

  Future<void> _create() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    final repository = ref.read(playlistRepositoryProvider);
    final playlist = await repository.create(name);
    await _setMembership(playlist, selected: true);
    _controller.clear();
    setState(() => _playlistsFuture = _load());
  }
}

class _TrackPreview extends StatelessWidget {
  const _TrackPreview({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          CoverArt(
            coverUrl: track.coverUrl,
            localCoverPath: track.localCoverPath,
            size: 42,
            borderRadius: 12,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
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
          Icon(Icons.playlist_add_rounded, color: palette.secondaryText),
        ],
      ),
    );
  }
}
