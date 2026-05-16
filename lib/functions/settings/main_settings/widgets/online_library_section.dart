import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/models/server_status.dart';
import '../../../../core/models/source_info.dart';
import '../../../../core/theme/app_colors.dart';

class OnlineLibrarySection extends StatelessWidget {
  const OnlineLibrarySection({
    super.key,
    required this.status,
    required this.sources,
    required this.urlController,
    required this.checking,
    required this.clearingCache,
    required this.clearingSongs,
    required this.httpWarning,
    required this.onCheck,
    required this.onClear,
    required this.onClearCache,
    required this.onClearSongs,
    required this.onOpenGuide,
  });

  final ServerStatus status;
  final List<SourceInfo> sources;
  final TextEditingController urlController;
  final bool checking;
  final bool clearingCache;
  final bool clearingSongs;
  final bool httpWarning;
  final VoidCallback onCheck;
  final VoidCallback onClear;
  final VoidCallback onClearCache;
  final VoidCallback onClearSongs;
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Online Library', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.palette.border),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 12, color: _statusColor(context)),
              const SizedBox(width: 10),
              Expanded(child: Text(status.label)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sleewave works offline. You can optionally connect your own Online Library server.\n\n'
          '1. Prepare a server or VPS.\n'
          '2. Clone and run the Sleewave backend on your server.\n'
          '3. Paste your server link here.\n'
          '4. Press Check.',
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onOpenGuide,
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Open setup guide'),
        ),
        const SizedBox(height: 4),
        Text(
          AppConfig.backendSetupRepoUrl,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: urlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'http://127.0.0.1:8000',
          ),
        ),
        if (httpWarning)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'HTTPS is recommended for remote servers.',
              style: TextStyle(color: context.palette.warning),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: checking ? null : onCheck,
              icon: checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering_rounded),
              label: const Text('Check'),
            ),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (status.isConnected) ...[
          Text(
            'Server cleanup',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: clearingCache ? null : onClearCache,
                icon: clearingCache
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cleaning_services_rounded),
                label: const Text('Clear cache'),
              ),
              OutlinedButton.icon(
                onPressed: clearingSongs ? null : onClearSongs,
                icon: clearingSongs
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_sweep_rounded),
                label: const Text('Clear all songs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.palette.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        for (final source in sources)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              source.canSearch
                  ? Icons.check_circle_rounded
                  : Icons.block_rounded,
              color: source.canSearch
                  ? context.palette.success
                  : context.palette.secondaryText,
            ),
            title: Text(source.name),
            subtitle: Text(source.canSearch ? 'Available' : 'Unavailable'),
            enabled: source.available,
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
