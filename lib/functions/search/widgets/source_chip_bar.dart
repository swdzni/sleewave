import 'package:flutter/material.dart';

import '../../../core/models/source_info.dart';

class SourceChipBar extends StatelessWidget {
  const SourceChipBar({
    super.key,
    required this.sources,
    required this.selectedSourceIds,
    required this.onToggle,
    required this.onSelectAll,
  });

  final List<SourceInfo> sources;
  final List<String> selectedSourceIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const SizedBox.shrink();
    }
    final visibleSources = sources.take(3).toList();
    final hiddenSources = sources.skip(3).toList();
    final allSelected = selectedSourceIds.isEmpty;
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: allSelected,
              onSelected: (_) => onSelectAll(),
            ),
          ),
          for (final source in visibleSources)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SourceChip(
                source: source,
                selected: selectedSourceIds.contains(source.id),
                onToggle: onToggle,
              ),
            ),
          if (hiddenSources.isNotEmpty)
            ActionChip(
              avatar: const Icon(Icons.more_horiz_rounded, size: 16),
              label: const Text('More'),
              onPressed: () => _showAllSources(context),
            ),
        ],
      ),
    );
  }

  void _showAllSources(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text('Sources', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: selectedSourceIds.isEmpty,
                title: const Text('All'),
                onChanged: (_) {
                  Navigator.pop(context);
                  onSelectAll();
                },
              ),
              for (final source in sources)
                CheckboxListTile(
                  value: selectedSourceIds.contains(source.id),
                  enabled: source.canSearch,
                  title: Text(source.name),
                  subtitle: source.canSearch ? null : const Text('Unavailable'),
                  onChanged: (_) {
                    Navigator.pop(context);
                    onToggle(source.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.source,
    required this.selected,
    required this.onToggle,
  });

  final SourceInfo source;
  final bool selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(source.name),
      selected: selected,
      onSelected: source.canSearch ? (_) => onToggle(source.id) : null,
      avatar: source.canSearch
          ? null
          : const Icon(Icons.block_rounded, size: 16),
    );
  }
}
