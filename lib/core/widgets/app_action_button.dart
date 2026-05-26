import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.danger = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool danger;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading || onPressed == null ? null : onPressed;
    final childIcon = AnimatedSwitcher(
      duration: AppDurations.state,
      child: loading
          ? const SizedBox.square(
              key: ValueKey('loading'),
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(key: const ValueKey('icon'), icon),
    );
    final child = Text(label, overflow: TextOverflow.ellipsis);
    if (filled) {
      return FilledButton.icon(
        onPressed: effectiveOnPressed,
        icon: childIcon,
        label: child,
        style: danger ? _filledDangerStyle(context) : null,
      );
    }
    return OutlinedButton.icon(
      onPressed: effectiveOnPressed,
      icon: childIcon,
      label: child,
      style: danger ? _outlinedDangerStyle(context) : null,
    );
  }

  ButtonStyle _filledDangerStyle(BuildContext context) {
    final palette = context.palette;
    return FilledButton.styleFrom(
      backgroundColor: palette.danger,
      foregroundColor: Colors.white,
      disabledBackgroundColor: palette.danger.withValues(alpha: 0.32),
      disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
    );
  }

  ButtonStyle _outlinedDangerStyle(BuildContext context) {
    final palette = context.palette;
    return OutlinedButton.styleFrom(
      foregroundColor: palette.danger,
      side: BorderSide(color: palette.danger.withValues(alpha: 0.44)),
    );
  }
}
