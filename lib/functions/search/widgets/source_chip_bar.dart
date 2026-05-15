import 'package:flutter/material.dart';

import '../../../core/models/source_info.dart';

class SourceChipBar extends StatelessWidget {
  const SourceChipBar({
    super.key,
    required this.sources,
    required this.selectedSourceIds,
    required this.onToggle,
  });

  final List<SourceInfo> sources;
  final List<String> selectedSourceIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final source = sources[index];
          return FilterChip(
            label: Text(source.name),
            selected: selectedSourceIds.contains(source.id),
            onSelected: source.canSearch ? (_) => onToggle(source.id) : null,
            avatar: source.canSearch
                ? null
                : const Icon(Icons.block_rounded, size: 16),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: sources.length,
      ),
    );
  }
}
