import 'package:flutter/material.dart';

import '../../../core/models/server_status.dart';
import '../../../core/theme/app_colors.dart';

class HostInfoCard extends StatelessWidget {
  const HostInfoCard({super.key, required this.status, required this.onTap});

  final ServerStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.kind) {
      ServerStatusKind.connected => context.palette.success,
      ServerStatusKind.problem => context.palette.danger,
      ServerStatusKind.notConfigured => context.palette.secondaryText,
      ServerStatusKind.unknown ||
      ServerStatusKind.checking => context.palette.warning,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(8),
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
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
