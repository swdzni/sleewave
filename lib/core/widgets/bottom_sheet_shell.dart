import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class BottomSheetShell extends StatelessWidget {
  const BottomSheetShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return AnimatedPadding(
      duration: AppDurations.state,
      curve: AppCurves.standard,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.elevated,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
          border: Border.all(color: context.palette.border),
          boxShadow: context.palette.shadow.a == 0
              ? null
              : [
                  BoxShadow(
                    color: context.palette.shadow,
                    blurRadius: 32,
                    offset: const Offset(0, -8),
                  ),
                ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: child,
          ),
        ),
      ),
    );
  }
}
