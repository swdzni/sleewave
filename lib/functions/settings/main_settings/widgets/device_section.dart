import 'package:flutter/material.dart';

import 'settings_components.dart';

class DeviceSection extends StatelessWidget {
  const DeviceSection({super.key, required this.deviceController});

  final TextEditingController deviceController;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Device identity',
      subtitle: 'Used to distinguish this device when syncing with a server.',
      children: [
        TextField(
          controller: deviceController,
          decoration: const InputDecoration(labelText: 'Device name'),
        ),
      ],
    );
  }
}
