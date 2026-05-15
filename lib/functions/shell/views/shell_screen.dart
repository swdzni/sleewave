import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/widgets/glass_tab_bar.dart';
import '../../player/widgets/mini_player.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayer(),
                const SizedBox(height: 8),
                GlassTabBar(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == currentIndex,
                    );
                    if (index == 0) {
                      ref
                          .read(appStartupControllerProvider)
                          .refreshBackend(keepConnectedStatus: true);
                    }
                  },
                  items: const [
                    GlassTabItem(
                      label: 'Home',
                      icon: Icons.home_rounded,
                      semanticLabel: 'Home tab',
                    ),
                    GlassTabItem(
                      label: 'Search',
                      icon: Icons.search_rounded,
                      semanticLabel: 'Search tab',
                    ),
                    GlassTabItem(
                      label: 'Playlists',
                      icon: Icons.queue_music_rounded,
                      semanticLabel: 'Playlists tab',
                    ),
                    GlassTabItem(
                      label: 'Library',
                      icon: Icons.library_music_rounded,
                      semanticLabel: 'Library tab',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
