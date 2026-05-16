import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/app_settings.dart';
import '../../../../core/models/server_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../view_models/settings_view_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsViewModelProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsViewModelProvider).state;
    return AppScaffold(
      child: ListView(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Close',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            title: 'Appearance',
            children: [
              _SettingsRow(
                icon: Icons.palette_rounded,
                title: 'Theme',
                subtitle: _themeModeLabel(state.settings.themeMode),
                onTap: () => context.push('/settings/appearance'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Connections',
            children: [
              _SettingsRow(
                icon: Icons.cloud_queue_rounded,
                title: 'Online Library',
                subtitle: state.status.label,
                trailing: _StatusDot(status: state.status),
                onTap: () => context.push('/settings/online-library'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Device',
            children: [
              _SettingsRow(
                icon: Icons.phone_iphone_rounded,
                title: 'Device name',
                subtitle: state.settings.deviceId,
                onTap: () => context.push('/settings/device'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Other',
            children: [
              _SettingsRow(
                icon: Icons.history_rounded,
                title: 'Recently played',
                subtitle: '${state.settings.recentHistoryLimit} tracks',
                onTap: () => context.push('/settings/other'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _themeModeLabel(SleewaveThemeMode mode) {
  return switch (mode) {
    SleewaveThemeMode.pureDark => 'Pure Dark',
    SleewaveThemeMode.dark => 'Dark',
    SleewaveThemeMode.white => 'White',
  };
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.palette.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: context.palette.secondaryText,
          ),
      onTap: onTap,
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final ServerStatus status;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.circle, size: 12, color: _color(context));
  }

  Color _color(BuildContext context) {
    return switch (status.kind) {
      ServerStatusKind.connected => context.palette.success,
      ServerStatusKind.problem => context.palette.danger,
      ServerStatusKind.notConfigured => context.palette.secondaryText,
      ServerStatusKind.unknown ||
      ServerStatusKind.checking => context.palette.warning,
    };
  }
}
