import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum AppAlertVariant { info, success, warning, danger, mono }

class AppAlert extends StatelessWidget {
  const AppAlert({
    super.key,
    required this.title,
    required this.message,
    this.variant = AppAlertVariant.info,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final AppAlertVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tokens = context.themeTokens;
    final color = switch (variant) {
      AppAlertVariant.info => palette.accent,
      AppAlertVariant.success => palette.success,
      AppAlertVariant.warning => palette.warning,
      AppAlertVariant.danger => palette.danger,
      AppAlertVariant.mono => palette.secondaryText,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(tokens.rowRadius),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(variant), color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AppAlertVariant variant) {
    return switch (variant) {
      AppAlertVariant.info => Icons.info_outline_rounded,
      AppAlertVariant.success => Icons.check_circle_outline_rounded,
      AppAlertVariant.warning => Icons.warning_amber_rounded,
      AppAlertVariant.danger => Icons.error_outline_rounded,
      AppAlertVariant.mono => Icons.subdirectory_arrow_right_rounded,
    };
  }
}
