import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../player/view_models/player_view_model.dart';
import '../view_models/search_view_model.dart';
import '../widgets/search_result_list.dart';
import '../widgets/source_chip_bar.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(searchViewModelProvider);
    final state = vm.state;
    final currentTrackId = ref
        .watch(playerViewModelProvider)
        .state
        .snapshot
        .currentTrack
        ?.id;
    final sourceNames = {
      for (final source in state.availableSources) source.id: source.name,
    };
    final downloadProgress = ref.watch(downloadServiceProvider).progress;
    return AppScaffold(
      safeBottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 220),
        children: [
          Text('Search', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 14),
          CupertinoSearchTextField(
            placeholder: 'Search for artists, tracks...',
            onChanged: vm.setQuery,
            onSubmitted: (_) => vm.searchNow(force: true),
          ),
          const SizedBox(height: 12),
          SourceChipBar(
            sources: state.availableSources,
            selectedSourceIds: state.selectedSourceIds,
            onToggle: vm.toggleSource,
            onSelectAll: vm.selectAllSources,
          ),
          if (state.isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
          for (final warning in state.warnings)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(label: Text(warning)),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(state.error!, textAlign: TextAlign.center),
            ),
          if (state.query.trim().isEmpty)
            EmptyState(
              title: state.hasBackend
                  ? 'Search your Online Library sources.'
                  : 'Search your offline Library.',
              icon: Icons.search_rounded,
            )
          else if (state.allResults.isEmpty && !state.isSearching)
            const EmptyState(title: 'No tracks found.')
          else
            SearchResultList(
              localMatches: state.localMatches,
              streamedResults: state.streamedResults,
              onPlay: vm.playTrack,
              onLike: vm.toggleLike,
              onDownload: vm.downloadTrack,
              onShare: vm.shareTrack,
              onDelete: vm.deleteTrack,
              onDeleteFromServer: vm.deleteFromServer,
              currentTrackId: currentTrackId,
              sourceNames: sourceNames,
              downloadProgress: downloadProgress,
              onlineAvailable: state.hasBackend,
            ),
        ],
      ),
    );
  }
}
