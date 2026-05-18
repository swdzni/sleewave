import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../view_models/settings_view_model.dart';

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
          _SettingsSubHeader(title: 'Other', onBack: () => context.pop()),
          const SizedBox(height: 18),
          Text(
            'Recently played',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Row(
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
          const SizedBox(height: 6),
          Text(
            'Keep up to $limit tracks in play history.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Share with text'),
            subtitle: const Text('Add "Sent from Sleewave player" to shares.'),
            value: state.settings.shareWithText,
            onChanged: vm.setShareWithText,
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

class _SettingsSubHeader extends StatelessWidget {
  const _SettingsSubHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
        ),
      ],
    );
  }
}
