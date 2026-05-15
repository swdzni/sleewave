import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../functions/home/views/home_screen.dart';
import '../../functions/library/views/library_screen.dart';
import '../../functions/player/views/player_screen.dart';
import '../../functions/playlists/views/playlist_detail_screen.dart';
import '../../functions/playlists/views/playlists_screen.dart';
import '../../functions/search/views/search_screen.dart';
import '../../functions/settings/main_settings/views/appearance_settings_screen.dart';
import '../../functions/settings/main_settings/views/device_settings_screen.dart';
import '../../functions/settings/main_settings/views/online_library_settings_screen.dart';
import '../../functions/settings/main_settings/views/settings_screen.dart';
import '../../functions/shell/views/shell_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: RouteNames.search,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/playlists',
                name: RouteNames.playlists,
                builder: (context, state) => const PlaylistsScreen(),
                routes: [
                  GoRoute(
                    path: ':playlistId',
                    name: RouteNames.playlistDetail,
                    builder: (context, state) => PlaylistDetailScreen(
                      playlistId: state.pathParameters['playlistId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                name: RouteNames.library,
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        pageBuilder: (context, state) =>
            _bottomUpPage(state, const SettingsScreen()),
        routes: [
          GoRoute(
            path: 'appearance',
            name: RouteNames.settingsAppearance,
            pageBuilder: (context, state) =>
                _bottomUpPage(state, const AppearanceSettingsScreen()),
          ),
          GoRoute(
            path: 'online-library',
            name: RouteNames.settingsOnlineLibrary,
            pageBuilder: (context, state) =>
                _bottomUpPage(state, const OnlineLibrarySettingsScreen()),
          ),
          GoRoute(
            path: 'device',
            name: RouteNames.settingsDevice,
            pageBuilder: (context, state) =>
                _bottomUpPage(state, const DeviceSettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/player',
        name: RouteNames.player,
        pageBuilder: (context, state) =>
            _bottomUpPage(state, const PlayerScreen(), opaque: false),
      ),
    ],
  );
});

CustomTransitionPage<void> _bottomUpPage(
  GoRouterState state,
  Widget child, {
  bool opaque = true,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    child: child,
    opaque: opaque,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}
