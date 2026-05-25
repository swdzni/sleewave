import 'package:flutter/material.dart';

import '../../../core/models/server_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

class HostInfoCard extends StatelessWidget {
  const HostInfoCard({
    super.key,
    required this.status,
    required this.onTap,
    this.onRetry,
  });

  final ServerStatus status;
  final VoidCallback onTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final color = switch (status.kind) {
      ServerStatusKind.connected => context.palette.success,
      ServerStatusKind.problem => context.palette.danger,
      ServerStatusKind.notConfigured => context.palette.secondaryText,
      ServerStatusKind.unknown ||
      ServerStatusKind.checking => context.palette.warning,
    };
    final retry = onRetry;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.rowRadius),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(tokens.rowRadius),
          border: Border.all(color: context.palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Online Library',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    status.label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (status.kind == ServerStatusKind.problem && retry != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Retry Online Library',
                onPressed: retry,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ] else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
