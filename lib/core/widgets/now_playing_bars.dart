import 'package:flutter/material.dart';

class NowPlayingBars extends StatefulWidget {
  const NowPlayingBars({
    super.key,
    required this.color,
    required this.playing,
    this.width = 22,
    this.height = 20,
  });

  final Color color;
  final bool playing;
  final double width;
  final double height;

  @override
  State<NowPlayingBars> createState() => _NowPlayingBarsState();
}

class _NowPlayingBarsState extends State<NowPlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
      value: 0.34,
    );
    if (widget.playing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant NowPlayingBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing == widget.playing) {
      return;
    }
    if (widget.playing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.animateTo(0.2, duration: const Duration(milliseconds: 220));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = widget.playing ? _controller.value : 0.2;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(widget.height * (0.36 + 0.42 * value)),
              const SizedBox(width: 3),
              _bar(widget.height * (0.64 - 0.32 * value)),
              const SizedBox(width: 3),
              _bar(widget.height * (0.42 + 0.28 * (1 - value))),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
