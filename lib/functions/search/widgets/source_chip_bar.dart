import 'package:flutter/material.dart';

import '../../../core/models/source_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_haptics.dart';

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
    final tokens = context.themeTokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(tokens.rowRadius),
        border: Border.all(color: context.palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(tokens.rowRadius),
              onTap: () {
                AppHaptics.selection();
                setState(() => _expanded = !_expanded);
              },
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
                    onSelected: (_) {
                      AppHaptics.light();
                      widget.onSelectAll();
                    },
                  ),
                  for (final source in widget.sources)
                    _SourceChip(
                      source: source,
                      selected: widget.selectedSourceIds.contains(source.id),
                      onToggle: (sourceId) {
                        AppHaptics.light();
                        widget.onToggle(sourceId);
                      },
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
    final palette = context.palette;
    return FilterChip(
      label: Text(source.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      onSelected: unavailable ? null : (_) => onToggle(source.id),
      avatar: Tooltip(
        message: unavailable ? 'Unavailable' : 'Available',
        child: Icon(
          unavailable ? Icons.block_rounded : Icons.circle,
          size: 16,
          color: unavailable ? palette.secondaryText : Colors.transparent,
        ),
      ),
      avatarBoxConstraints: const BoxConstraints.tightFor(
        width: 16,
        height: 16,
      ),
    );
  }
}
