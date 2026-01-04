import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Simple sparkline chart for showing trends
/// Perfect for showing workout progress over time
class Sparkline extends StatelessWidget {
  final List<double> data;
  final double width;
  final double height;
  final Color color;
  final double strokeWidth;
  final bool showDots;

  const Sparkline({
    super.key,
    required this.data,
    required this.width,
    required this.height,
    this.color = AppColors.cyberLime,
    this.strokeWidth = 2.0,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(
        data: data,
        color: color,
        strokeWidth: strokeWidth,
        showDots: showDots,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double strokeWidth;
  final bool showDots;

  _SparklinePainter({
    required this.data,
    required this.color,
    required this.strokeWidth,
    required this.showDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Find min and max for scaling
    double minValue = data.reduce((a, b) => a < b ? a : b);
    double maxValue = data.reduce((a, b) => a > b ? a : b);
    
    // Add padding to avoid clipping
    final range = maxValue - minValue;
    if (range > 0) {
      minValue -= range * 0.1;
      maxValue += range * 0.1;
    } else {
      // All values are the same, add some range
      minValue -= 1;
      maxValue += 1;
    }

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = (data[i] - minValue) / (maxValue - minValue);
      final y = size.height - (normalizedValue * size.height);

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw the line
    canvas.drawPath(path, paint);

    // Draw dots if enabled
    if (showDots) {
      for (final point in points) {
        canvas.drawCircle(point, strokeWidth * 1.5, dotPaint);
      }
    }

    // Draw glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = strokeWidth * 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showDots != showDots;
  }
}

