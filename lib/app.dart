import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_startup_controller.dart';
import 'core/constants/app_constants.dart';
import 'core/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/loading_state.dart';

class SleewaveApp extends ConsumerStatefulWidget {
  const SleewaveApp({super.key});

  @override
  ConsumerState<SleewaveApp> createState() => _SleewaveAppState();
}

class _SleewaveAppState extends ConsumerState<SleewaveApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appStartupControllerProvider).start());
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final startup = ref.watch(appStartupControllerProvider);
    final router = ref.watch(appRouterProvider);

    if (!startup.ready && !theme.loaded) {
      return MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.fromMode(theme.settings.themeMode),
        home: const LoadingState(label: 'Starting Sleewave'),
      );
    }

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromMode(theme.settings.themeMode),
      routerConfig: router,
    );
  }
}
