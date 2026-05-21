import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_startup_controller.dart';
import '../../../core/widgets/app_error_popup.dart';
import '../../../core/widgets/glass_tab_bar.dart';
import '../../player/view_models/player_view_model.dart';
import '../../player/widgets/mini_player.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  String? _lastPlaybackErrorKey;

  @override
  Widget build(BuildContext context) {
    ref.listen(playerViewModelProvider.select((vm) => vm.state.snapshot), (
      previous,
      next,
    ) {
      final error = next.error;
      if (error == null) {
        _lastPlaybackErrorKey = null;
        return;
      }
      final track = next.currentTrack;
      final key = '${track?.id ?? 'unknown'}|$error';
      if (_lastPlaybackErrorKey == key) {
        return;
      }
      _lastPlaybackErrorKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        showAppErrorPopup(
          context: context,
          title: track == null ? 'Playback failed' : 'Could not play',
          message: track == null ? error : '${track.title}\n$error',
          primaryLabel: 'Open player',
          onPrimary: () => context.push('/player'),
        );
      });
    });

    final currentIndex = widget.navigationShell.currentIndex;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: widget.navigationShell),
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
                    widget.navigationShell.goBranch(
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
