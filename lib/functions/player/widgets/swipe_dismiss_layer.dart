import 'package:flutter/material.dart';

class SwipeDismissLayer extends StatefulWidget {
  const SwipeDismissLayer({
    super.key,
    required this.child,
    required this.onDismiss,
  });

  final Widget child;
  final VoidCallback onDismiss;

  @override
  State<SwipeDismissLayer> createState() => _SwipeDismissLayerState();
}

class _SwipeDismissLayerState extends State<SwipeDismissLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _resetAnimation;
  double _offset = 0;
  bool _dragEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          final animation = _resetAnimation;
          if (animation == null) {
            return;
          }
          setState(() => _offset = animation.value);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final threshold = height * 0.4;
    final progress = (_offset / threshold).clamp(0.0, 1.0);
    final coverProgress = 1 - progress;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.46 * coverProgress),
          ),
        ),
        Transform.translate(
          offset: Offset(0, _offset),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (details) {
              final topGripHeight = MediaQuery.paddingOf(context).top + 180;
              _dragEnabled = details.globalPosition.dy <= topGripHeight;
              if (_dragEnabled) {
                _controller.stop();
              }
            },
            onVerticalDragUpdate: (details) {
              if (!_dragEnabled) {
                return;
              }
              final next = (_offset + details.delta.dy).clamp(0.0, height);
              setState(() => _offset = next);
            },
            onVerticalDragEnd: (details) {
              if (!_dragEnabled) {
                return;
              }
              _dragEnabled = false;
              final velocity = details.primaryVelocity ?? 0;
              if (_offset >= threshold || velocity > 360) {
                widget.onDismiss();
                return;
              }
              _animateBack();
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }

  void _animateBack() {
    _resetAnimation = Tween<double>(
      begin: _offset,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller
      ..reset()
      ..forward();
  }
}
