import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/glow_theme.dart';

class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.active = false,
    this.loading = false,
    this.semanticLabel,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.accentColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool active;
  final bool loading;
  final String? semanticLabel;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final Color? accentColor;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final palette = context.palette;
    final tokens = context.themeTokens;
    final accentColor = widget.accentColor ?? palette.accent;
    final color = widget.active ? accentColor : palette.surfaceMuted;
    final effectiveColor = enabled
        ? color
        : palette.surfaceMuted.withValues(alpha: 0.6);
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        onTapDown: enabled
            ? (_) {
                setState(() => _pressed = true);
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: enabled ? widget.onPressed : null,
        onLongPressStart: enabled && widget.onLongPressStart != null
            ? (_) => widget.onLongPressStart?.call()
            : null,
        onLongPressEnd: enabled && widget.onLongPressEnd != null
            ? (_) => widget.onLongPressEnd?.call()
            : null,
        onLongPressCancel: enabled && widget.onLongPressEnd != null
            ? widget.onLongPressEnd
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1,
          duration: AppDurations.press,
          curve: AppCurves.standard,
          child: AnimatedContainer(
            duration: AppDurations.state,
            constraints: const BoxConstraints(
              minWidth: AppSizes.iconButton,
              minHeight: AppSizes.iconButton,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.label == null ? 0 : 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: tokens.isGlass ? null : effectiveColor,
              gradient: tokens.isGlass
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        effectiveColor.withValues(
                          alpha: widget.active ? 0.84 : 0.66,
                        ),
                        palette.surfaceMuted.withValues(alpha: 0.42),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              border: Border.all(
                color: widget.active
                    ? palette.strongBorder.withValues(
                        alpha: tokens.isGlass ? 0.74 : 1,
                      )
                    : palette.border,
              ),
              boxShadow: widget.active && enabled
                  ? GlowTheme.softGlow(color)
                  : tokens.isGlass && enabled && palette.shadow.a > 0
                  ? [
                      BoxShadow(
                        color: palette.shadow,
                        blurRadius: tokens.shadowBlur,
                        offset: tokens.shadowOffset,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.primaryText,
                    ),
                  )
                else
                  Icon(
                    widget.icon,
                    color: enabled ? palette.primaryText : palette.tertiaryText,
                    size: 20,
                  ),
                if (widget.label != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.label!,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
