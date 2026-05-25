import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/app_settings.dart';
import '../../../../core/models/server_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/settings_components.dart';

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
          SettingsPageHeader(
            title: 'Settings',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            backIcon: Icons.close_rounded,
          ),
          const SizedBox(height: 28),
          SettingsSection(
            title: 'Appearance',
            children: [
              SettingsRow(
                icon: Icons.palette_rounded,
                title: 'Theme',
                subtitle: _themeModeLabel(state.settings.themeMode),
                trailing: _ThemePreview(mode: state.settings.themeMode),
                onTap: () => context.push('/settings/appearance'),
              ),
            ],
          ),
          SettingsSection(
            title: 'Online Library',
            children: [
              SettingsRow(
                icon: Icons.cloud_queue_rounded,
                title: 'Connection',
                subtitle: state.status.label,
                trailing: _StatusDot(status: state.status),
                onTap: () => context.push('/settings/online-library'),
              ),
            ],
          ),
          SettingsSection(
            title: 'Device',
            children: [
              SettingsRow(
                icon: Icons.phone_iphone_rounded,
                title: 'Device name',
                subtitle: state.settings.deviceId,
                onTap: () => context.push('/settings/device'),
              ),
            ],
          ),
          SettingsSection(
            title: 'Playback',
            children: [
              SettingsRow(
                icon: Icons.tune_rounded,
                title: 'History & sharing',
                subtitle:
                    '${state.settings.recentHistoryLimit} recent, sharing ${state.settings.shareWithText ? 'on' : 'off'}',
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
    SleewaveThemeMode.caffeineDark => 'Caffeine Dark',
    SleewaveThemeMode.caffeineLight => 'Caffeine Light',
    SleewaveThemeMode.monoDark => 'Mono Dark',
    SleewaveThemeMode.monoLight => 'Mono Light',
  };
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

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.mode});

  final SleewaveThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteFor(mode);
    final tokens = AppTheme.tokensFor(mode);
    final colors = [
      palette.background,
      palette.surface,
      palette.accent,
      palette.accentSoft,
    ];
    return Container(
      width: 78,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(tokens.previewRadius),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          for (final color in colors)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(tokens.previewRadius / 2),
                  border: Border.all(
                    color:
                        (color.computeLuminance() -
                                    palette.background.computeLuminance())
                                .abs() <
                            0.08
                        ? palette.strongBorder
                        : palette.border,
                  ),
                ),
              ),
            ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: context.palette.secondaryText,
          ),
        ],
      ),
    );
  }
}
