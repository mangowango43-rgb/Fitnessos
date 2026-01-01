import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/app_colors.dart';

/// Shatter animation - Shows "COMBO BROKEN" with particle effect
class ShatterAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const ShatterAnimation({
    super.key,
    this.onComplete,
  });

  @override
  State<ShatterAnimation> createState() => _ShatterAnimationState();
}

class _ShatterAnimationState extends State<ShatterAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Generate particles
    _particles = List.generate(20, (index) {
      final angle = (_random.nextDouble() * 2 * pi);
      final speed = 50 + _random.nextDouble() * 100;
      
      return Particle(
        startX: 0,
        startY: 0,
        velocityX: cos(angle) * speed,
        velocityY: sin(angle) * speed - 50, // Upward bias
        size: 4 + _random.nextDouble() * 8,
        color: AppColors.neonCrimson.withOpacity(0.8),
      );
    });

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
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
        return CustomPaint(
          size: Size.infinite,
          painter: ShatterPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: Center(
            child: Opacity(
              opacity: 1.0 - _controller.value,
              child: Transform.scale(
                scale: 1.0 + (_controller.value * 0.5),
                child: Text(
                  'COMBO\nBROKEN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.neonCrimson,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: AppColors.neonCrimson.withOpacity(0.8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Particle data model
class Particle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double size;
  final Color color;

  const Particle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.color,
  });
}

/// Custom painter for particle effect
class ShatterPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  static const double gravity = 200.0;

  const ShatterPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (final particle in particles) {
      // Calculate position with physics
      final t = progress;
      final x = centerX + particle.startX + (particle.velocityX * t);
      final y = centerY + particle.startY + (particle.velocityY * t) + (0.5 * gravity * t * t);

      // Fade out as progress increases
      final opacity = (1.0 - progress) * 0.8;

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ShatterPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

