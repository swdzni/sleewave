import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
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
    required this.directUrlEnabled,
    required this.httpWarning,
    required this.onCheck,
    required this.onClear,
    required this.onClearCache,
    required this.onClearSongs,
    required this.onDirectUrlChanged,
    required this.onOpenGuide,
  });

  final ServerStatus status;
  final List<SourceInfo> sources;
  final TextEditingController urlController;
  final bool checking;
  final bool clearingCache;
  final bool clearingSongs;
  final bool directUrlEnabled;
  final bool httpWarning;
  final VoidCallback onCheck;
  final VoidCallback onClear;
  final VoidCallback onClearCache;
  final VoidCallback onClearSongs;
  final ValueChanged<bool> onDirectUrlChanged;
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Connection',
          subtitle: 'Sleewave works offline. Online Library is optional.',
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
                subtitle: 'Use HTTPS for remote servers when possible.',
                trailing: Icon(
                  Icons.lock_open_rounded,
                  color: context.palette.warning,
                ),
              ),
            SettingsRow(
              icon: Icons.link_rounded,
              title: 'Direct URLs',
              subtitle:
                  'Allow provider redirects for uncached streams and downloads.',
              trailing: Switch(
                value: directUrlEnabled,
                onChanged: onDirectUrlChanged,
              ),
            ),
          ],
        ),
        SettingsSection(
          title: 'Setup',
          subtitle: 'Prepare a server, run the backend, then paste the link.',
          children: [
            SettingsRow(
              icon: Icons.open_in_new_rounded,
              title: 'Open setup guide',
              subtitle: AppConfig.backendSetupRepoUrl,
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
            subtitle: 'Destructive actions for server-side cached content.',
            children: [
              SettingsRow(
                icon: clearingCache
                    ? Icons.hourglass_top_rounded
                    : Icons.cleaning_services_rounded,
                title: 'Clear cache',
                subtitle: 'Remove cached audio files from the server.',
                onTap: clearingCache ? null : onClearCache,
              ),
              SettingsRow(
                icon: clearingSongs
                    ? Icons.hourglass_top_rounded
                    : Icons.delete_sweep_rounded,
                title: 'Clear all songs',
                subtitle: 'Clear server catalog and device-library records.',
                onTap: clearingSongs ? null : onClearSongs,
                danger: true,
              ),
            ],
          ),
        if (sources.isNotEmpty)
          SettingsSection(
            title: 'Sources',
            subtitle: 'Available search providers reported by your server.',
            children: [
              for (final source in sources)
                SettingsRow(
                  icon: source.canSearch
                      ? Icons.check_circle_rounded
                      : Icons.block_rounded,
                  title: source.name,
                  subtitle: source.canSearch ? 'Available' : 'Unavailable',
                  trailing: Icon(
                    source.canSearch
                        ? Icons.search_rounded
                        : Icons.not_interested_rounded,
                    color: source.canSearch
                        ? context.palette.success
                        : context.palette.secondaryText,
                  ),
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
