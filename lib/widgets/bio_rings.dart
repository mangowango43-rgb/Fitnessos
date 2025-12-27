import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_colors.dart';

class BioRings extends StatefulWidget {
  final double formScore;
  final int streak;
  final double moveProgress;

  const BioRings({
    super.key,
    required this.formScore,
    required this.streak,
    this.moveProgress = 0.85,
  });

  @override
  State<BioRings> createState() => _BioRingsState();
}

class _BioRingsState extends State<BioRings>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating rings
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(320, 320),
                  painter: BioRingsPainter(
                    outerProgress: widget.moveProgress,
                    middleProgress: widget.formScore / 100,
                    innerProgress: 0.99,
                  ),
                ),
              );
            },
          ),
          
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.formScore.toInt()}%',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: AppColors.electricCyan,
                  shadows: [
                    Shadow(
                      color: AppColors.electricCyan,
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'FORM SCORE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white40,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '🔥 ${widget.streak}',
                style: const TextStyle(
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'DAY STREAK',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.white40,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BioRingsPainter extends CustomPainter {
  final double outerProgress;
  final double middleProgress;
  final double innerProgress;

  BioRingsPainter({
    required this.outerProgress,
    required this.middleProgress,
    required this.innerProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Outer ring (cyan)
    _drawRing(
      canvas,
      center,
      140,
      16,
      AppColors.electricCyan,
      outerProgress,
      AppColors.white5,
    );

    // Middle ring (lime)
    _drawRing(
      canvas,
      center,
      100,
      16,
      AppColors.cyberLime,
      middleProgress,
      AppColors.white5,
    );

    // Inner ring (orange)
    _drawRing(
      canvas,
      center,
      60,
      16,
      const Color(0xFFFF6B35),
      innerProgress,
      AppColors.white5,
    );
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
    Color color,
    double progress,
    Color backgroundColor,
  ) {
    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth / 2);

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(BioRingsPainter oldDelegate) {
    return oldDelegate.outerProgress != outerProgress ||
        oldDelegate.middleProgress != middleProgress ||
        oldDelegate.innerProgress != innerProgress;
  }
}

