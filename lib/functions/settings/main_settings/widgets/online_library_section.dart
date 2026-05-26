import 'package:flutter/material.dart';

import '../../../../core/models/server_status.dart';
import '../../../../core/models/source_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_action_button.dart';
import 'settings_components.dart';

class OnlineLibrarySection extends StatelessWidget {
  const OnlineLibrarySection({
    super.key,
    required this.status,
    required this.sources,
    required this.urlController,
    required this.checking,
    required this.clearingCache,
    required this.clearingSongs,
    required this.directUrlSourceIds,
    required this.httpWarning,
    required this.onCheck,
    required this.onClear,
    required this.onClearCache,
    required this.onClearSongs,
    required this.onDirectUrlAllSourcesChanged,
    required this.onDirectUrlSourceChanged,
    required this.onOpenGuide,
  });

  final ServerStatus status;
  final List<SourceInfo> sources;
  final TextEditingController urlController;
  final bool checking;
  final bool clearingCache;
  final bool clearingSongs;
  final List<String> directUrlSourceIds;
  final bool httpWarning;
  final VoidCallback onCheck;
  final VoidCallback onClear;
  final VoidCallback onClearCache;
  final VoidCallback onClearSongs;
  final ValueChanged<bool> onDirectUrlAllSourcesChanged;
  final void Function(String sourceId, bool enabled) onDirectUrlSourceChanged;
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Connection',
          children: [
            SettingsRow(
              icon: Icons.circle,
              title: 'Status',
              subtitle: status.label,
              trailing: Icon(
                Icons.circle,
                size: 12,
                color: _statusColor(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: TextField(
                controller: urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'http://127.0.0.1:8000',
                ),
              ),
            ),
            if (httpWarning)
              SettingsRow(
                icon: Icons.warning_amber_rounded,
                title: 'HTTPS recommended',
                trailing: Icon(
                  Icons.lock_open_rounded,
                  color: context.palette.warning,
                ),
              ),
          ],
        ),
        SettingsSection(
          title: 'Setup',
          children: [
            SettingsRow(
              icon: Icons.open_in_new_rounded,
              title: 'Open setup guide',
              onTap: onOpenGuide,
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppActionButton(
              onPressed: checking ? null : onCheck,
              icon: Icons.save_rounded,
              label: 'Save',
              filled: true,
              loading: checking,
            ),
            AppActionButton(
              onPressed: onClear,
              icon: Icons.clear_rounded,
              label: 'Clear',
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (status.isConnected)
          SettingsSection(
            title: 'Server cleanup',
            children: [
              SettingsRow(
                icon: clearingCache
                    ? Icons.hourglass_top_rounded
                    : Icons.cleaning_services_rounded,
                title: 'Clear cache',
                onTap: clearingCache ? null : onClearCache,
              ),
              SettingsRow(
                icon: clearingSongs
                    ? Icons.hourglass_top_rounded
                    : Icons.delete_sweep_rounded,
                title: 'Clear all songs',
                onTap: clearingSongs ? null : onClearSongs,
                danger: true,
              ),
            ],
          ),
        if (sources.isNotEmpty)
          SettingsSection(
            title: 'Sources',
            children: [
              _AllSourcesDirectUrlRow(
                sources: sources,
                directUrlSourceIds: directUrlSourceIds,
                onChanged: onDirectUrlAllSourcesChanged,
              ),
              for (final source in sources)
                _SourceSettingsRow(
                  source: source,
                  directUrlSourceIds: directUrlSourceIds,
                  onDirectUrlSourceChanged: onDirectUrlSourceChanged,
                ),
            ],
          ),
      ],
    );
  }

  Color _statusColor(BuildContext context) {
    return switch (status.kind) {
      ServerStatusKind.connected => context.palette.success,
      ServerStatusKind.problem => context.palette.danger,
      ServerStatusKind.notConfigured => context.palette.secondaryText,
      ServerStatusKind.unknown ||
      ServerStatusKind.checking => context.palette.warning,
    };
  }
}

class _SourceSettingsRow extends StatelessWidget {
  const _SourceSettingsRow({
    required this.source,
    required this.directUrlSourceIds,
    required this.onDirectUrlSourceChanged,
  });

  final SourceInfo source;
  final List<String> directUrlSourceIds;
  final void Function(String sourceId, bool enabled) onDirectUrlSourceChanged;

  @override
  Widget build(BuildContext context) {
    final canUseDirectUrl = source.available && source.supportsStream;
    final directUrlActive = directUrlSourceIds.contains(source.id);
    return SettingsRow(
      icon: source.available ? Icons.check_circle_rounded : Icons.block_rounded,
      title: source.name,
      subtitle: _subtitle(directUrlActive),
      trailing: canUseDirectUrl
          ? Switch(
              value: directUrlActive,
              onChanged: (enabled) =>
                  onDirectUrlSourceChanged(source.id, enabled),
            )
          : Icon(
              source.available
                  ? Icons.not_interested_rounded
                  : Icons.block_rounded,
              color: context.palette.secondaryText,
            ),
    );
  }

  String _subtitle(bool directUrlActive) {
    final parts = <String>[
      source.available ? 'Available' : 'Unavailable',
      if (!source.supportsSearch) 'No search',
      if (!source.supportsStream)
        'No streaming'
      else if (directUrlActive)
        'Direct links on'
      else
        'Normal stream',
    ];
    return parts.join(' · ');
  }
}

class _AllSourcesDirectUrlRow extends StatelessWidget {
  const _AllSourcesDirectUrlRow({
    required this.sources,
    required this.directUrlSourceIds,
    required this.onChanged,
  });

  final List<SourceInfo> sources;
  final List<String> directUrlSourceIds;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final streamableIds = [
      for (final source in sources)
        if (source.available && source.supportsStream) source.id,
    ];
    final selectedCount = streamableIds
        .where(directUrlSourceIds.contains)
        .length;
    final allSelected =
        streamableIds.isNotEmpty && selectedCount == streamableIds.length;
    return SettingsRow(
      icon: Icons.link_rounded,
      title: 'All direct URLs',
      subtitle: streamableIds.isEmpty
          ? 'No streamable sources.'
          : '$selectedCount of ${streamableIds.length} sources enabled.',
      trailing: Switch(
        value: allSelected,
        onChanged: streamableIds.isEmpty ? null : onChanged,
      ),
    );
  }
}
