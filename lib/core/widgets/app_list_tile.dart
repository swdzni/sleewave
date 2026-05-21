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
          color: enabled
              ? palette.surface
              : palette.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(tokens.rowRadius),
          border: Border.all(color: active ? palette.accent : palette.border),
          boxShadow: active && palette.shadow.a > 0
              ? [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.14),
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
