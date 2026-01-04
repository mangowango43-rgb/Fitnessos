import 'package:flutter/material.dart';

/// Animated counter that counts up to a target number
/// Creates that premium "numbers coming alive" effect
class AnimatedCounter extends StatefulWidget {
  final int target;
  final Duration duration;
  final TextStyle? style;
  final String? suffix;
  final String? prefix;

  const AnimatedCounter({
    super.key,
    required this.target,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.suffix,
    this.prefix,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = IntTween(begin: 0, end: widget.target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _animation = IntTween(
        begin: oldWidget.target,
        end: widget.target,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
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
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix ?? ''}${_animation.value}${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}

/// Animated counter for doubles (for percentages, etc.)
class AnimatedDoubleCounter extends StatefulWidget {
  final double target;
  final Duration duration;
  final TextStyle? style;
  final String? suffix;
  final String? prefix;
  final int decimals;

  const AnimatedDoubleCounter({
    super.key,
    required this.target,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.suffix,
    this.prefix,
    this.decimals = 0,
  });

  @override
  State<AnimatedDoubleCounter> createState() => _AnimatedDoubleCounterState();
}

class _AnimatedDoubleCounterState extends State<AnimatedDoubleCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: widget.target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedDoubleCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _animation = Tween<double>(
        begin: oldWidget.target,
        end: widget.target,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
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
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix ?? ''}${_animation.value.toStringAsFixed(widget.decimals)}${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}

