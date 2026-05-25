import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/device_section.dart';
import '../widgets/settings_components.dart';

class DeviceSettingsScreen extends ConsumerStatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  ConsumerState<DeviceSettingsScreen> createState() =>
      _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends ConsumerState<DeviceSettingsScreen> {
  final _deviceController = TextEditingController();
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsViewModelProvider).load());
  }

  @override
  void dispose() {
    _deviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(settingsViewModelProvider);
    final state = vm.state;
    if (!_seeded) {
      _deviceController.text = state.settings.deviceId;
      _seeded = true;
    }
    return AppScaffold(
      child: ListView(
        children: [
          SettingsPageHeader(title: 'Device', onBack: () => context.pop()),
          const SizedBox(height: 28),
          DeviceSection(deviceController: _deviceController),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => vm.saveDevice(_deviceController.text),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save'),
              ),
              OutlinedButton.icon(
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: state.settings.deviceId),
                ),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy device name'),
              ),
            ],
          ),
          if (state.message != null) ...[
            const SizedBox(height: 16),
            Text(state.message!),
          ],
        ],
      ),
    );
  }
}
