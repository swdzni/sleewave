import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../player/view_models/player_view_model.dart';
import '../view_models/search_view_model.dart';
import '../widgets/search_result_list.dart';
import '../widgets/source_chip_bar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _scrollController = ScrollController();
  String? _lastErrorKey;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearBottom);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreNearBottom)
      ..dispose();
    super.dispose();
  }

  void _loadMoreNearBottom() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 520) {
      return;
    }
    final vm = ref.read(searchViewModelProvider);
    if (vm.state.hasMore && !vm.state.isLoadingMore) {
      vm.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchViewModelProvider.select((vm) => vm.state.error), (
      previous,
      next,
    ) {
      if (next == null) {
        _lastErrorKey = null;
        return;
      }
      if (_lastErrorKey == next) {
        return;
      }
      _lastErrorKey = next;
      AppHaptics.light();
    });
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
      child: Listener(
        onPointerMove: (event) {
          if (event.delta.dy > 0 &&
              _scrollController.hasClients &&
              _scrollController.position.pixels <= 0) {
            FocusScope.of(context).unfocus();
          }
        },
        child: ListView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 220),
          children: [
            Text('Search', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 14),
            AppSearchField(
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
                child: AppAlert(
                  title: 'Source warning',
                  message: warning,
                  variant: AppAlertVariant.warning,
                ),
              ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: AppAlert(
                  title: state.errorTitle,
                  message: state.error!,
                  variant: AppAlertVariant.danger,
                  actionLabel: state.errorTitle == 'Search failed'
                      ? 'Try again'
                      : null,
                  onAction: state.errorTitle == 'Search failed'
                      ? () => vm.searchNow(force: true)
                      : null,
                ),
              ),
            if (state.notice != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: AppAlert(
                  title: state.noticeTitle,
                  message: state.notice!,
                  variant: AppAlertVariant.success,
                ),
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
            else ...[
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
              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.hasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: TextButton(
                    onPressed: vm.loadMore,
                    child: const Text('More results'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
