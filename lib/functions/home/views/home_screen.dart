import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/song_card.dart';
import '../../player/view_models/player_view_model.dart';
import '../view_models/home_view_model.dart';
import '../widgets/home_section.dart';
import '../widgets/host_info_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(homeViewModelProvider).load(refreshStatus: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(homeViewModelProvider);
    final state = vm.state;
    final player = ref.read(playerViewModelProvider);
    return AppScaffold(
      safeBottom: false,
      child: RefreshIndicator(
        onRefresh: vm.refreshBackend,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 170),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sleewave',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (ref.watch(themeControllerProvider).settings.backendBaseUrl !=
                null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: HostInfoCard(
                  status: state.status,
                  onTap: () => context.push('/settings'),
                ),
              ),
            if (state.playlists.isNotEmpty)
              HomeSection(
                title: 'Playlists',
                child: SizedBox(
                  height: 102,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final playlist = state.playlists[index];
                      return InkWell(
                        onTap: () => context.push('/playlists/${playlist.id}'),
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.queue_music_rounded),
                              const Spacer(),
                              Text(
                                playlist.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text('${playlist.trackCount} tracks'),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemCount: state.playlists.length,
                  ),
                ),
              ),
            if (state.recentTracks.isNotEmpty)
              HomeSection(
                title: 'Recently played',
                child: Column(
                  children: [
                    for (final track in state.recentTracks)
                      SongCard(
                        track: track,
                        mode: SongCardMode.compact,
                        onTap: () => player.play(track),
                        onLike: () =>
                            ref.read(trackRepositoryProvider).toggleLike(track),
                        onDelete: () => ref
                            .read(trackRepositoryProvider)
                            .deleteLocalState(track),
                      ),
                  ],
                ),
              ),
            HomeSection(
              title: 'Saved on server',
              child: state.savedSongs.isEmpty
                  ? const EmptyState(title: 'No server-cached tracks yet.')
                  : Column(
                      children: [
                        for (final track in state.savedSongs)
                          SongCard(
                            track: track,
                            onTap: () => player.play(track),
                            onLike: () => ref
                                .read(trackRepositoryProvider)
                                .toggleLike(track),
                          ),
                      ],
                    ),
            ),
            HomeSection(
              title: 'Offline library',
              child: state.localPreview.isEmpty
                  ? const EmptyState(
                      title: 'No local tracks yet.',
                      subtitle: 'Import audio files from Library.',
                    )
                  : Column(
                      children: [
                        for (final track in state.localPreview)
                          SongCard(
                            track: track,
                            onTap: () => player.play(track),
                            onLike: () => ref
                                .read(trackRepositoryProvider)
                                .toggleLike(track),
                            onDelete: () => ref
                                .read(trackRepositoryProvider)
                                .deleteLocalState(track),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
