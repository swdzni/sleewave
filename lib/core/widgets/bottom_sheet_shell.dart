import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BottomSheetShell extends StatelessWidget {
  const BottomSheetShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }
}
