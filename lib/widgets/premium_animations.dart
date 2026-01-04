import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Pulsing glow animation widget
/// Perfect for "Ready to Train" card or important CTAs
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  const PulsingGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.minOpacity = 0.3,
    this.maxOpacity = 0.8,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
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
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_animation.value),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// Entrance animation for cards sliding up and fading in
class SlideUpAnimation extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;

  const SlideUpAnimation({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<SlideUpAnimation> createState() => _SlideUpAnimationState();
}

class _SlideUpAnimationState extends State<SlideUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Delay before starting
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Milestone celebration particle burst
class MilestoneBurst extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final VoidCallback? onComplete;

  const MilestoneBurst({
    super.key,
    required this.child,
    required this.trigger,
    this.onComplete,
  });

  @override
  State<MilestoneBurst> createState() => _MilestoneBurstState();
}

class _MilestoneBurstState extends State<MilestoneBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(MilestoneBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !_hasTriggered) {
      _hasTriggered = true;
      _controller.forward(from: 0).then((_) {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    } else if (!widget.trigger) {
      _hasTriggered = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.isAnimating)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticleBurstPainter(
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ParticleBurstPainter extends CustomPainter {
  final double progress;
  static const int particleCount = 20;

  _ParticleBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = progress * size.width * 0.5;
      
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      // Fade out as particles move away
      final opacity = 1.0 - progress;
      
      // Alternate colors
      final colors = [
        const Color(0xFFCCFF00), // cyberLime
        const Color(0xFF00F0FF), // electricCyan
        const Color(0xFFFFFFFF), // white
      ];
      
      paint.color = colors[i % colors.length].withOpacity(opacity);

      // Vary particle sizes
      final radius = (3.0 + (i % 3) * 2.0) * (1.0 - progress * 0.5);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

