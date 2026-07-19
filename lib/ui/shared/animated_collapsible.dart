import 'package:flutter/material.dart';

class AnimatedCollapsible extends StatefulWidget {
  const AnimatedCollapsible({
    required this.visible,
    required this.child,
    this.topPadding = 0,
    this.duration = const Duration(milliseconds: 180),
    super.key,
  });

  final bool visible;
  final Widget child;
  final double topPadding;
  final Duration duration;

  @override
  State<AnimatedCollapsible> createState() => _AnimatedCollapsibleState();
}

class _AnimatedCollapsibleState extends State<AnimatedCollapsible>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.visible ? 1 : 0,
  );
  @override
  void didUpdateWidget(AnimatedCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.visible == widget.visible) {
      return;
    }

    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _controller.drive(CurveTween(curve: Curves.easeInOut));

    return IgnorePointer(
      ignoring: !widget.visible,
      child: SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: animation,
          child: AnimatedPadding(
            duration: widget.duration,
            curve: Curves.easeInOut,
            padding: EdgeInsets.only(top: widget.topPadding),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
