import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/app_colors.dart';

class TrackBadges extends StatelessWidget {
  const TrackBadges({super.key, required this.track, this.sourceLabel});

  final Track track;
  final String? sourceLabel;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];
    if (track.isLocalPlayable || track.isDownloaded) {
      badges.add(const _Badge(label: 'Downloaded', icon: Icons.check_circle));
    } else if (track.isServerCached) {
      badges.add(const _Badge(label: 'Online', icon: Icons.cloud_done));
    } else if (track.resultId != null) {
      badges.add(const _Badge(label: 'Remote', icon: Icons.cloud));
    }
    if (track.isMix) {
      badges.add(const _Badge(label: 'Mix', icon: Icons.graphic_eq));
    }
    final source = sourceLabel ?? track.sourceId;
    if (source != null && source.trim().isNotEmpty) {
      badges.add(_Badge(label: source, icon: Icons.link_rounded));
    }
    return Wrap(spacing: 6, runSpacing: 4, children: badges);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.palette.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: context.palette.accent),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
