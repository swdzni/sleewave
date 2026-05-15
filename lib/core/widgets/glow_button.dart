import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool active;
  final bool loading;
  final String? semanticLabel;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final color = widget.active
        ? context.palette.accent
        : context.palette.elevated;
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.symmetric(
              horizontal: widget.label == null ? 0 : 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: enabled
                  ? color
                  : context.palette.elevated.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.palette.border),
              boxShadow: widget.active && enabled
                  ? GlowTheme.softGlow(color)
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
                      color: context.palette.primaryText,
                    ),
                  )
                else
                  Icon(
                    widget.icon,
                    color: enabled
                        ? context.palette.primaryText
                        : context.palette.secondaryText,
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
