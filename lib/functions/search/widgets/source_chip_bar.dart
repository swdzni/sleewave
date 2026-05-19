import 'package:flutter/material.dart';

import '../../../core/models/source_info.dart';
import '../../../core/theme/app_colors.dart';

class SourceChipBar extends StatefulWidget {
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
  State<SourceChipBar> createState() => _SourceChipBarState();
}

class _SourceChipBarState extends State<SourceChipBar> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.sources.isEmpty) {
      return const SizedBox.shrink();
    }
    final allSelected = widget.selectedSourceIds.isEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surface.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'Sources',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: allSelected,
                    onSelected: (_) => widget.onSelectAll(),
                  ),
                  for (final source in widget.sources)
                    _SourceChip(
                      source: source,
                      selected: widget.selectedSourceIds.contains(source.id),
                      onToggle: widget.onToggle,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
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
    final unavailable = !source.canSearch;
    return FilterChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(source.name),
          if (unavailable)
            Text(
              'Unavailable',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.palette.secondaryText,
              ),
            ),
        ],
      ),
      selected: selected,
      onSelected: unavailable ? null : (_) => onToggle(source.id),
      avatar: unavailable ? const Icon(Icons.block_rounded, size: 16) : null,
    );
  }
}
