import 'package:flutter/animation.dart';
import 'dart:math';

/// Custom animation curves for gaming effects

/// Elastic out curve - bouncy effect for combo badge
class ElasticOutCurve extends Curve {
  @override
  double transformInternal(double t) {
    const double s = 0.3;
    return (pow(2, -10 * t) * sin((t - s / 4) * (2 * pi) / s) + 1).toDouble();
  }
}

/// Sharp peak curve - quick rise and fall for perfect flash
class SharpPeakCurve extends Curve {
  @override
  double transformInternal(double t) {
    if (t < 0.5) {
      // Rise sharply
      return pow(t * 2, 3);
    } else {
      // Fall sharply
      return 1.0 - pow((t - 0.5) * 2, 3);
    }
  }
}

/// Smooth charge curve - eased filling for power gauge
class SmoothChargeCurve extends Curve {
  @override
  double transformInternal(double t) {
    return t * t * (3.0 - 2.0 * t); // Smoothstep function
  }
}

/// Export custom curves
final Curve elasticOut = ElasticOutCurve();
final Curve sharpPeak = SharpPeakCurve();
final Curve smoothCharge = SmoothChargeCurve();

