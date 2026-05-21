import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class BottomSheetShell extends StatelessWidget {
  const BottomSheetShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final tokens = context.themeTokens;
    return AnimatedPadding(
      duration: AppDurations.state,
      curve: AppCurves.standard,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.elevated,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.sheetRadius),
          ),
          border: Border.all(color: context.palette.border),
          boxShadow: context.palette.shadow.a == 0
              ? null
              : [
                  BoxShadow(
                    color: context.palette.shadow,
                    blurRadius: tokens.shadowBlur + 14,
                    offset: -tokens.shadowOffset,
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
