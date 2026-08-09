import 'package:flutter/material.dart';

/// Recreates the website's staggered entrance animations
/// (`anim-slide-up`, `anim-slide-right`, `anim-scale-in`).
enum EntranceType { fadeUp, slideRight, scaleIn }

class AnimatedEntrance extends StatefulWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.type = EntranceType.fadeUp,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget child;
  final Duration delay;
  final EntranceType type;
  final Duration duration;

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const curve = Cubic(0.16, 1.0, 0.3, 1.0);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final eased = Curves.easeOut.transform(t);
        final visited = curve.transform(t).clamp(0.0, 1.0);

        Offset offset = Offset.zero;
        if (widget.type == EntranceType.fadeUp) {
          offset = Offset(0, 30 * (1 - visited));
        } else if (widget.type == EntranceType.slideRight) {
          offset = Offset(-40 * (1 - visited), 0);
        }

        double scale = 1;
        if (widget.type == EntranceType.scaleIn) {
          scale = 0.9 + (0.1 * visited);
        }

        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: offset,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}