import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/appearance_section.dart';
import '../widgets/settings_components.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsViewModelProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(settingsViewModelProvider);
    final state = vm.state;
    return AppScaffold(
      child: ListView(
        children: [
          SettingsPageHeader(title: 'Appearance', onBack: () => context.pop()),
          const SizedBox(height: 28),
          AppearanceSection(
            themeMode: state.settings.themeMode,
            onThemeChanged: vm.setThemeMode,
          ),
        ],
      ),
    );
  }
}
