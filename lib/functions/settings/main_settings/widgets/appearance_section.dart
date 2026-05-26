import 'package:flutter/material.dart';

import '../../../../core/models/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _ThemeOption.options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.42,
          ),
          itemBuilder: (context, index) {
            final option = _ThemeOption.options[index];
            return _ThemeCard(
              option: option,
              selected: themeMode == option.mode,
              onTap: () => onThemeChanged(option.mode),
            );
          },
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
    return Semantics(
      label: option.title,
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey('theme-card-${option.mode.name}'),
        borderRadius: BorderRadius.circular(context.themeTokens.rowRadius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.state,
          curve: AppCurves.standard,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? appPalette.accentSoft.withValues(alpha: 0.54)
                : appPalette.surfaceMuted,
            borderRadius: BorderRadius.circular(context.themeTokens.rowRadius),
            border: Border.all(
              color: selected ? appPalette.strongBorder : appPalette.border,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _ThemePreviewTile(option: option)),
              Positioned(
                top: 7,
                left: 7,
                child: _ThemeGlyph(
                  mode: option.mode,
                  palette: palette,
                  tokens: tokens,
                ),
              ),
              Positioned(
                right: 7,
                top: 7,
                child: AnimatedContainer(
                  duration: AppDurations.state,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected ? palette.accent : palette.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? palette.accent
                          : _visibleBorder(palette.border, palette),
                    ),
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: palette.primaryOnAccent,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewTile extends StatelessWidget {
  const _ThemePreviewTile({required this.option});

  final _ThemeOption option;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteFor(option.mode);
    final tokens = AppTheme.tokensFor(option.mode);
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.previewRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(tokens.previewRadius),
          border: Border.all(color: _visibleBorder(palette.border, palette)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 34, 10, 9),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(
                            tokens.coverRadius,
                          ),
                          border: Border.all(
                            color: _visibleBorder(palette.border, palette),
                          ),
                          boxShadow: palette.shadow.a > 0
                              ? [
                                  BoxShadow(
                                    color: palette.shadow,
                                    blurRadius: tokens.shadowBlur,
                                    offset: tokens.shadowOffset,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(
                            tokens.controlRadius,
                          ),
                          border: Border.all(
                            color: _visibleBorder(palette.border, palette),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final color in [
                    palette.accent,
                    palette.accentSoft,
                    palette.primaryText,
                    palette.surface,
                  ])
                    Expanded(
                      child: Container(
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            tokens.previewRadius,
                          ),
                          border: Border.all(
                            color: _visibleBorder(color, palette),
                            width: 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
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
    final isGlue =
        mode == SleewaveThemeMode.glueDark ||
        mode == SleewaveThemeMode.glueLight;
    return SizedBox.square(
      key: ValueKey(
        isGlue
            ? 'glue-theme-icon'
            : tokens.isMono
            ? 'mono-theme-icon'
            : 'caffeine-theme-icon',
      ),
      dimension: 42,
      child: CustomPaint(
        painter: isGlue
            ? _GlueIconPainter(palette)
            : tokens.isMono
            ? _MonoIconPainter(palette)
            : _CaffeineIconPainter(palette),
      ),
    );
  }
}

class _GlueIconPainter extends CustomPainter {
  const _GlueIconPainter(this.palette);

  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = palette.strongBorder.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final highlight = Paint()
      ..color = palette.accent.withValues(alpha: 0.86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;

    void pane(Rect rect, Color color) {
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(13));
      canvas.drawRRect(rrect, Paint()..color = color);
      canvas.drawRRect(rrect, border);
    }

    pane(
      Rect.fromLTWH(8, 8, 24, 24),
      palette.surfaceMuted.withValues(alpha: 0.62),
    );
    pane(
      Rect.fromLTWH(11, 11, 24, 24),
      palette.surface.withValues(alpha: 0.78),
    );
    canvas.drawLine(const Offset(17, 18), const Offset(29, 18), highlight);
    canvas.drawLine(const Offset(17, 25), const Offset(25, 25), highlight);
  }

  @override
  bool shouldRepaint(covariant _GlueIconPainter oldDelegate) {
    return oldDelegate.palette != palette;
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
  const _ThemeOption({required this.mode, required this.title});

  final SleewaveThemeMode mode;
  final String title;

  static const options = [
    _ThemeOption(mode: SleewaveThemeMode.caffeineDark, title: 'Caffeine Dark'),
    _ThemeOption(
      mode: SleewaveThemeMode.caffeineLight,
      title: 'Caffeine Light',
    ),
    _ThemeOption(mode: SleewaveThemeMode.monoDark, title: 'Mono Dark'),
    _ThemeOption(mode: SleewaveThemeMode.monoLight, title: 'Mono Light'),
    _ThemeOption(mode: SleewaveThemeMode.glueDark, title: 'Glue Dark'),
    _ThemeOption(mode: SleewaveThemeMode.glueLight, title: 'Glue Light'),
  ];
}
