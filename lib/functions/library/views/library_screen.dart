import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/song_card.dart';
import '../../home/widgets/home_section.dart';
import '../view_models/library_view_model.dart';
import '../widgets/folder_header.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(libraryViewModelProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(libraryViewModelProvider);
    final state = vm.state;
    return AppScaffold(
      safeBottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 170),
        children: [
          FolderHeader(path: state.folderPath, onImport: vm.importFiles),
          const SizedBox(height: 24),
          HomeSection(
            title: 'Downloaded',
            child: state.downloaded.isEmpty
                ? const EmptyState(title: 'No downloaded tracks yet.')
                : Column(
                    children: [
                      for (final track in state.downloaded)
                        SongCard(
                          track: track,
                          onTap: () => vm.play(track),
                          onLike: () => ref
                              .read(trackRepositoryProvider)
                              .toggleLike(track),
                          onDelete: () => vm.deleteTrack(track),
                        ),
                    ],
                  ),
          ),
          HomeSection(
            title: 'Imported',
            child: state.imported.isEmpty
                ? const EmptyState(title: 'No imported tracks yet.')
                : Column(
                    children: [
                      for (final track in state.imported)
                        SongCard(
                          track: track,
                          onTap: () => vm.play(track),
                          onLike: () => ref
                              .read(trackRepositoryProvider)
                              .toggleLike(track),
                          onDelete: () => vm.deleteTrack(track),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
