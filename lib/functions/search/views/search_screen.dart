import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../view_models/search_view_model.dart';
import '../widgets/search_result_list.dart';
import '../widgets/source_chip_bar.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(searchViewModelProvider);
    final state = vm.state;
    return AppScaffold(
      safeBottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 170),
        children: [
          Text('Search', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 14),
          CupertinoSearchTextField(
            placeholder: 'Search your Online Library sources.',
            onChanged: vm.setQuery,
            onSubmitted: (_) => vm.searchNow(),
          ),
          const SizedBox(height: 12),
          SourceChipBar(
            sources: state.availableSources,
            selectedSourceIds: state.selectedSourceIds,
            onToggle: vm.toggleSource,
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
                  : 'Connect Online Library in Settings or use your offline Library.',
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
              onDelete: vm.deleteTrack,
            ),
        ],
      ),
    );
  }
}
