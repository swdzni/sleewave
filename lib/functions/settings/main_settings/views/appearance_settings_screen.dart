import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/appearance_section.dart';

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
          _SettingsSubHeader(title: 'Appearance', onBack: () => context.pop()),
          const SizedBox(height: 18),
          AppearanceSection(
            themeMode: state.settings.themeMode,
            glowMode: state.settings.glowMode,
            onThemeChanged: vm.setThemeMode,
            onGlowChanged: vm.setGlowMode,
          ),
        ],
      ),
    );
  }
}

class _SettingsSubHeader extends StatelessWidget {
  const _SettingsSubHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
        ),
      ],
    );
  }
}
