import 'package:flutter/material.dart';

import '../../../../core/models/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/app_haptics.dart';
import 'settings_components.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final SleewaveThemeMode themeMode;
  final ValueChanged<SleewaveThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Themes',
      children: [
        for (final option in _ThemeOption.options)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _ThemeCard(
              option: option,
              selected: themeMode == option.mode,
              onTap: () => onThemeChanged(option.mode),
            ),
          ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appPalette = context.palette;
    final palette = AppTheme.paletteFor(option.mode);
    final tokens = AppTheme.tokensFor(option.mode);
    return InkWell(
      key: ValueKey('theme-card-${option.mode.name}'),
      borderRadius: BorderRadius.circular(context.themeTokens.rowRadius),
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppDurations.state,
        curve: AppCurves.standard,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? appPalette.accentSoft.withValues(alpha: 0.66)
              : appPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(context.themeTokens.rowRadius),
          border: Border.all(
            color: selected ? appPalette.strongBorder : appPalette.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ThemeGlyph(mode: option.mode, palette: palette, tokens: tokens),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? appPalette.accent
                            : appPalette.secondaryText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _MiniUiPreview(mode: option.mode),
                  const SizedBox(height: 10),
                  _SwatchRow(mode: option.mode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeGlyph extends StatelessWidget {
  const _ThemeGlyph({
    required this.mode,
    required this.palette,
    required this.tokens,
  });

  final SleewaveThemeMode mode;
  final AppPalette palette;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: ValueKey(tokens.isMono ? 'mono-theme-icon' : 'caffeine-theme-icon'),
      dimension: 42,
      child: CustomPaint(
        painter: tokens.isMono
            ? _MonoIconPainter(palette)
            : _CaffeineIconPainter(palette),
      ),
    );
  }
}

class _MiniUiPreview extends StatelessWidget {
  const _MiniUiPreview({required this.mode});

  final SleewaveThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteFor(mode);
    final tokens = AppTheme.tokensFor(mode);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(tokens.previewRadius),
        border: Border.all(color: _visibleBorder(palette.border, palette)),
      ),
      padding: const EdgeInsets.all(7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(tokens.coverRadius),
              border: Border.all(
                color: _visibleBorder(palette.border, palette),
              ),
            ),
            child: Icon(
              Icons.music_note_rounded,
              size: 17,
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 7,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: palette.primaryText,
                    borderRadius: BorderRadius.circular(tokens.previewRadius),
                  ),
                ),
                const SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.58,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: palette.secondaryText,
                      borderRadius: BorderRadius.circular(tokens.previewRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              border: Border.all(
                color: _visibleBorder(palette.strongBorder, palette),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.mode});

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
    return Row(
      children: [
        for (var index = 0; index < colors.length; index++)
          Container(
            key: ValueKey(
              'theme-swatch-${mode.name}-$index-${colors[index].toARGB32()}',
            ),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: colors[index],
              borderRadius: BorderRadius.circular(tokens.previewRadius / 2),
              border: Border.all(color: _visibleBorder(colors[index], palette)),
            ),
          ),
      ],
    );
  }
}

class _MonoIconPainter extends CustomPainter {
  const _MonoIconPainter(this.palette);

  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = palette.strongBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = palette.surface;
    final rect = Offset.zero & size;
    canvas.drawRect(rect.deflate(1), fill);
    canvas.drawRect(rect.deflate(1), border);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '>_',
        style: TextStyle(
          color: palette.primaryText,
          fontFamily: 'monospace',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(9, size.height / 2 - 9));
  }

  @override
  bool shouldRepaint(covariant _MonoIconPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}

class _CaffeineIconPainter extends CustomPainter {
  const _CaffeineIconPainter(this.palette);

  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = palette.surface;
    final border = Paint()
      ..color = palette.strongBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final accent = Paint()
      ..color = palette.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    ).deflate(1);
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);

    final cup = Rect.fromLTWH(10, 19, 18, 11);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cup, const Radius.circular(5)),
      Paint()..color = palette.accentSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cup, const Radius.circular(5)),
      border,
    );
    canvas.drawArc(Rect.fromLTWH(25, 21, 8, 8), -1.45, 2.9, false, accent);
    canvas.drawLine(const Offset(15, 11), const Offset(13, 16), accent);
    canvas.drawLine(const Offset(22, 10), const Offset(20, 16), accent);
  }

  @override
  bool shouldRepaint(covariant _CaffeineIconPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}

Color _visibleBorder(Color color, AppPalette palette) {
  final tooCloseToBackground =
      (color.computeLuminance() - palette.background.computeLuminance()).abs() <
      0.08;
  return tooCloseToBackground ? palette.strongBorder : palette.border;
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
      subtitle: 'Warm black, cream controls, soft corners.',
    ),
    _ThemeOption(
      mode: SleewaveThemeMode.caffeineLight,
      title: 'Caffeine Light',
      subtitle: 'Clean white, roasted accent, soft controls.',
    ),
    _ThemeOption(
      mode: SleewaveThemeMode.monoDark,
      title: 'Mono Dark',
      subtitle: 'Terminal sharpness with graphite contrast.',
    ),
    _ThemeOption(
      mode: SleewaveThemeMode.monoLight,
      title: 'Mono Light',
      subtitle: 'White, ink, square edges, quiet chrome.',
    ),
  ];
}
