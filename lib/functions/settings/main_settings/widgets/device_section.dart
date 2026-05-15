import 'package:flutter/material.dart';

class DeviceSection extends StatelessWidget {
  const DeviceSection({super.key, required this.deviceController});

  final TextEditingController deviceController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Device', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TextField(
          controller: deviceController,
          decoration: const InputDecoration(labelText: 'Device name'),
        ),
      ],
    );
  }
}
