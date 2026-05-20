import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class TrackBadges extends StatelessWidget {
  const TrackBadges({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];
    if (track.isLocalPlayable || track.isDownloaded) {
      badges.add(
        const _Badge(
          label: 'Downloaded',
          icon: Icons.check_circle_rounded,
          tone: _BadgeTone.success,
        ),
      );
    } else if (track.isServerCached) {
      badges.add(
        const _Badge(
          label: 'Cached',
          icon: Icons.cloud_done_rounded,
          tone: _BadgeTone.accent,
        ),
      );
    } else if (track.resultId != null) {
      badges.add(
        const _Badge(
          label: 'Remote',
          icon: Icons.cloud_rounded,
          tone: _BadgeTone.muted,
        ),
      );
    }
    return Wrap(spacing: 6, runSpacing: 4, children: badges);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, required this.tone});

  final String label;
  final IconData icon;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch (tone) {
      _BadgeTone.success => palette.success,
      _BadgeTone.accent => palette.accent,
      _BadgeTone.muted => palette.secondaryText,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: palette.primaryText),
          ),
        ],
      ),
    );
  }
}

enum _BadgeTone { success, accent, muted }
