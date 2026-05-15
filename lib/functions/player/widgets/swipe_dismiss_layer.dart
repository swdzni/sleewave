import 'package:flutter/material.dart';

class SwipeDismissLayer extends StatelessWidget {
  const SwipeDismissLayer({
    super.key,
    required this.child,
    required this.onDismiss,
  });

  final Widget child;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 150) {
          onDismiss();
        }
      },
      child: child,
    );
  }
}
