import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
          padding: padding ?? const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: child,
        ),
      ),
    );
  }
}
