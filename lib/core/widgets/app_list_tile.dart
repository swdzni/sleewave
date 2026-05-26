import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_pressable.dart';

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.active = false,
    this.enabled = true,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool active;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tokens = context.themeTokens;
    return AppPressable(
      onTap: enabled ? onTap : null,
      onLongPress: onLongPress,
      borderRadius: tokens.rowRadius,
      child: AnimatedContainer(
        duration: AppDurations.state,
        curve: AppCurves.standard,
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: padding,
        decoration: BoxDecoration(
          color: tokens.isGlass
              ? null
              : enabled
              ? palette.surface
              : palette.surface.withValues(alpha: 0.58),
          gradient: tokens.isGlass
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (enabled ? palette.surface : palette.surfaceMuted)
                        .withValues(alpha: active ? 0.9 : 0.72),
                    palette.surfaceMuted.withValues(alpha: 0.44),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(tokens.rowRadius),
          border: Border.all(
            color: active
                ? palette.accent.withValues(alpha: tokens.isGlass ? 0.72 : 1)
                : palette.border,
          ),
          boxShadow: (active || tokens.isGlass) && palette.shadow.a > 0
              ? [
                  BoxShadow(
                    color: active
                        ? palette.accent.withValues(alpha: 0.18)
                        : palette.shadow,
                    blurRadius: tokens.shadowBlur,
                    offset: tokens.shadowOffset,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}
