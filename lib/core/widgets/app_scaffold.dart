import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.padding,
    this.safeBottom = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        bottom: safeBottom,
        child: Padding(
          padding:
              padding ??
              const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.compactScreen,
                AppSpacing.screen,
                0,
              ),
          child: child,
        ),
      ),
    );
  }
}
