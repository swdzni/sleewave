import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/settings_components.dart';

class OtherSettingsScreen extends ConsumerStatefulWidget {
  const OtherSettingsScreen({super.key});

  @override
  ConsumerState<OtherSettingsScreen> createState() =>
      _OtherSettingsScreenState();
}

class _OtherSettingsScreenState extends ConsumerState<OtherSettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsViewModelProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(settingsViewModelProvider);
    final state = vm.state;
    final limit = state.settings.recentHistoryLimit;
    return AppScaffold(
      child: ListView(
        children: [
          SettingsPageHeader(
            title: 'General',
            subtitle: 'History and sharing behavior.',
            onBack: () => context.pop(),
          ),
          const SizedBox(height: 28),
          SettingsSection(
            title: 'Playback history',
            subtitle: 'Control how many recently played tracks are kept.',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: limit.toDouble(),
                        min: AppConstants.minRecentHistoryLimit.toDouble(),
                        max: AppConstants.maxRecentHistoryLimit.toDouble(),
                        divisions:
                            (AppConstants.maxRecentHistoryLimit -
                                AppConstants.minRecentHistoryLimit) ~/
                            5,
                        label: '$limit',
                        onChanged: (value) =>
                            vm.setRecentHistoryLimit((value / 5).round() * 5),
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        '$limit',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              SettingsRow(
                icon: Icons.history_rounded,
                title: 'Recently played limit',
                subtitle: 'Keep up to $limit tracks in play history.',
              ),
            ],
          ),
          SettingsSection(
            title: 'Sharing',
            subtitle: 'Choose whether shared tracks include app attribution.',
            children: [
              SettingsRow(
                icon: Icons.ios_share_rounded,
                title: 'Share with text',
                subtitle: 'Add "Sent from Sleewave player" to shares.',
                trailing: Switch(
                  value: state.settings.shareWithText,
                  onChanged: vm.setShareWithText,
                ),
              ),
            ],
          ),
          if (state.message != null) ...[
            const SizedBox(height: 16),
            Text(state.message!),
          ],
        ],
      ),
    );
  }
}
