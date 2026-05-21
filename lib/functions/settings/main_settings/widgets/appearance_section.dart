import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import 'settings_components.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({
    super.key,
    required this.themeMode,
    required this.glowMode,
    required this.onThemeChanged,
    required this.onGlowChanged,
  });

  final SleewaveThemeMode themeMode;
  final GlowMode glowMode;
  final ValueChanged<SleewaveThemeMode> onThemeChanged;
  final ValueChanged<GlowMode> onGlowChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Theme',
          subtitle: 'Choose the base palette for the whole app.',
          children: [
            for (final option in _ThemeOption.options)
              _ThemeOptionTile(
                option: option,
                selected: themeMode == option.mode,
                onTap: () => onThemeChanged(option.mode),
              ),
          ],
        ),
        SettingsSection(
          title: 'Motion glow',
          subtitle: 'Keep visual motion calm or let playback react to artwork.',
          children: [
            SettingsRow(
              icon: Icons.radio_button_checked_rounded,
              title: 'Static',
              subtitle: 'Stable controls with subtle press feedback.',
              trailing: glowMode == GlowMode.static
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => onGlowChanged(GlowMode.static),
            ),
            SettingsRow(
              icon: Icons.graphic_eq_rounded,
              title: 'Dynamic',
              subtitle: 'Player accents can follow current track artwork.',
              trailing: glowMode == GlowMode.dynamic
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => onGlowChanged(GlowMode.dynamic),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tokens = context.themeTokens;
    return InkWell(
      borderRadius: BorderRadius.circular(tokens.rowRadius),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _PalettePreview(mode: option.mode),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? palette.accent : palette.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.mode});

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
      palette.success,
      palette.warning,
      palette.danger,
    ];
    return Container(
      width: 72,
      height: 44,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(tokens.previewRadius),
        border: Border.all(color: context.palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            for (final color in colors)
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(tokens.previewRadius / 2),
                  border: Border.all(color: palette.border),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption({
    required this.mode,
    required this.title,
    required this.subtitle,
  });

  final SleewaveThemeMode mode;
  final String title;
  final String subtitle;

  static const options = [
    _ThemeOption(
      mode: SleewaveThemeMode.caffeineDark,
      title: 'Caffeine Dark',
      subtitle: 'Warm black with cream controls.',
    ),
    _ThemeOption(
      mode: SleewaveThemeMode.caffeineLight,
      title: 'Caffeine Light',
      subtitle: 'Soft white with roasted coffee accent.',
    ),
    _ThemeOption(
      mode: SleewaveThemeMode.monoDark,
      title: 'Mono Dark',
      subtitle: 'Strict black, white, and graphite.',
    ),
    _ThemeOption(
      mode: SleewaveThemeMode.monoLight,
      title: 'Mono Light',
      subtitle: 'White, gray, and ink.',
    ),
  ];
}
