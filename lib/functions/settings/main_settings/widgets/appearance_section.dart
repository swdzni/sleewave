import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/app_settings.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({
    super.key,
    required this.themeMode,
    required this.glowMode,
    required this.onThemeChanged,
    required this.onGlowChanged,
  });

  final SleewaveThemeMode themeMode;
  final GlowMode glowMode;
  final ValueChanged<SleewaveThemeMode> onThemeChanged;
  final ValueChanged<GlowMode> onGlowChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        CupertinoSlidingSegmentedControl<SleewaveThemeMode>(
          groupValue: themeMode,
          onValueChanged: (value) {
            if (value != null) onThemeChanged(value);
          },
          children: const {
            SleewaveThemeMode.pureDark: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('Pure Dark'),
            ),
            SleewaveThemeMode.dark: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('Dark'),
            ),
            SleewaveThemeMode.white: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('White'),
            ),
          },
        ),
        const SizedBox(height: 12),
        CupertinoSlidingSegmentedControl<GlowMode>(
          groupValue: glowMode,
          onValueChanged: (value) {
            if (value != null) onGlowChanged(value);
          },
          children: const {
            GlowMode.static: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Static'),
            ),
            GlowMode.dynamic: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Dynamic'),
            ),
          },
        ),
      ],
    );
  }
}
