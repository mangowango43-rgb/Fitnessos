import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_colors.dart';

class SkeletonOverlay extends StatelessWidget {
  final Size size;
  final String? formFeedback; // 'PERFECT FORM', 'ELBOWS IN', null

  const SkeletonOverlay({
    super.key,
    required this.size,
    this.formFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: SkeletonPainter(formFeedback: formFeedback),
    );
  }
}

class SkeletonPainter extends CustomPainter {
  final String? formFeedback;

  SkeletonPainter({this.formFeedback});

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = formFeedback == 'PERFECT FORM'
        ? AppColors.cyberLime
        : formFeedback == 'ELBOWS IN'
            ? AppColors.neonCrimson
            : AppColors.electricCyan;

    // Line paint
    final linePaint = Paint()
      ..color = baseColor.withOpacity(0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Joint paint
    final jointPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Define skeleton points (percentages of screen)
    final head = Offset(size.width * 0.5, size.height * 0.22);
    final shoulderLeft = Offset(size.width * 0.38, size.height * 0.32);
    final shoulderRight = Offset(size.width * 0.62, size.height * 0.32);
    final spine = Offset(size.width * 0.5, size.height * 0.50);
    final elbowLeft = Offset(size.width * 0.32, size.height * 0.48);
    final elbowRight = Offset(size.width * 0.68, size.height * 0.48);
    final wristLeft = Offset(size.width * 0.28, size.height * 0.60);
    final wristRight = Offset(size.width * 0.72, size.height * 0.60);

    // Draw skeleton lines
    canvas.drawLine(head, spine, linePaint); // Spine
    canvas.drawLine(head, shoulderLeft, linePaint); // Left shoulder
    canvas.drawLine(head, shoulderRight, linePaint); // Right shoulder
    canvas.drawLine(shoulderLeft, elbowLeft, linePaint); // Left upper arm
    canvas.drawLine(shoulderRight, elbowRight, linePaint); // Right upper arm
    canvas.drawLine(elbowLeft, wristLeft, linePaint); // Left forearm
    canvas.drawLine(elbowRight, wristRight, linePaint); // Right forearm

    // Draw joints
    canvas.drawCircle(head, 8, jointPaint); // Head
    
    // Elbows (larger if there's feedback)
    final elbowSize = formFeedback == 'ELBOWS IN' ? 10.0 : 8.0;
    canvas.drawCircle(shoulderLeft, elbowSize, jointPaint);
    canvas.drawCircle(shoulderRight, elbowSize, jointPaint);
    canvas.drawCircle(elbowLeft, 8, jointPaint);
    canvas.drawCircle(elbowRight, 8, jointPaint);
    canvas.drawCircle(wristLeft, 6, jointPaint);
    canvas.drawCircle(wristRight, 6, jointPaint);

    // Draw angle indicators
    if (formFeedback == 'PERFECT FORM') {
      _drawAngleText(canvas, '92°', elbowLeft.translate(-30, -10), AppColors.cyberLime);
      _drawAngleText(canvas, '92°', elbowRight.translate(15, -10), AppColors.cyberLime);
    }
  }

  void _drawAngleText(Canvas canvas, String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              color: color,
              blurRadius: 8,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) {
    return oldDelegate.formFeedback != formFeedback;
  }
}

