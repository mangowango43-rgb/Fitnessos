import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/app_colors.dart';

/// Form quality levels for visual feedback
enum FormQuality {
  good,    // Green - form score >= 80
  okay,    // Yellow - form score 50-79
  bad,     // Red - form score < 50
  neutral, // Cyan - no exercise active / between reps
}

/// Skeleton state for gaming-style visual feedback
enum SkeletonState {
  idle,      // White - waiting for next rep
  charging,  // Cyan - user descending into rep, lines thickening
  perfect,   // Lime flash - perfect rep completed
  error,     // Red - bad form detected
}

/// CustomPainter that draws a glowing cyber-themed skeleton overlay
/// Color changes based on form quality during exercise
/// NOW WITH GAMING FEATURES: Dynamic line thickness, state-based colors, perfect flash
class SkeletonPainter extends CustomPainter {
  final List<PoseLandmark>? landmarks;
  final Size imageSize;
  final bool isFrontCamera;
  final FormQuality formQuality;
  final SkeletonState skeletonState;
  final double chargeProgress; // 0.0 to 1.0 - how deep into rep (for power gauge sync)
  final double? currentAngle; // Optional: display current angle for debugging

  SkeletonPainter({
    required this.landmarks,
    required this.imageSize,
    this.isFrontCamera = true,
    this.formQuality = FormQuality.neutral,
    this.skeletonState = SkeletonState.idle,
    this.chargeProgress = 0.0,
    this.currentAngle,
  });

  /// Get skeleton color based on SKELETON STATE (for gaming feedback)
  /// This overrides form quality when in special states
  Color get _skeletonColor {
    // State-based colors take priority
    switch (skeletonState) {
      case SkeletonState.idle:
        return AppColors.white70; // White when idle
      case SkeletonState.charging:
        return AppColors.electricCyan; // Cyan when charging
      case SkeletonState.perfect:
        return AppColors.cyberLime; // LIME FLASH on perfect rep
      case SkeletonState.error:
        return AppColors.neonCrimson; // Red on error
    }
  }

  /// Get joint color based on skeleton state
  Color get _jointColor {
    switch (skeletonState) {
      case SkeletonState.idle:
        return AppColors.cyberLime.withOpacity(0.7);
      case SkeletonState.charging:
        return AppColors.cyberLime;
      case SkeletonState.perfect:
        return AppColors.cyberLime; // LIME joints on perfect
      case SkeletonState.error:
        return AppColors.neonCrimson;
    }
  }

  /// Get glow intensity based on skeleton state
  /// Charging state increases glow with chargeProgress
  double get _glowIntensity {
    switch (skeletonState) {
      case SkeletonState.idle:
        return 6.0;
      case SkeletonState.charging:
        // Glow intensifies as user goes deeper: 6px → 12px
        return 6.0 + (chargeProgress * 6.0);
      case SkeletonState.perfect:
        return 14.0; // MAXIMUM GLOW on perfect flash
      case SkeletonState.error:
        return 10.0;
    }
  }

  /// Get line width based on skeleton state
  /// Lines thicken as user descends into rep
  double get _lineWidth {
    switch (skeletonState) {
      case SkeletonState.idle:
        return 2.0;
      case SkeletonState.charging:
        // Lines thicken from 2px → 4px as user goes deeper
        return 2.0 + (chargeProgress * 2.0);
      case SkeletonState.perfect:
        return 4.0; // Thick lines on perfect
      case SkeletonState.error:
        return 3.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null || landmarks!.isEmpty) {
      return;
    }

    // Paint for lines with state-based color and DYNAMIC WIDTH
    final linePaint = Paint()
      ..color = _skeletonColor
      ..strokeWidth = _lineWidth // DYNAMIC: 2-4px based on state
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _glowIntensity);

    // Paint for large joints with form-based color
    final largeJointPaint = Paint()
      ..color = _jointColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _glowIntensity + 2);

    // Paint for small joints
    final smallJointPaint = Paint()
      ..color = _skeletonColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _glowIntensity);

    // Create a map for quick landmark lookup
    final Map<PoseLandmarkType, PoseLandmark> landmarkMap = {};
    for (final landmark in landmarks!) {
      landmarkMap[landmark.type] = landmark;
    }

    // Helper function to get position with proper scaling and mirroring
    Offset? getPosition(PoseLandmarkType type) {
      final landmark = landmarkMap[type];
      if (landmark == null) return null;

      double x = landmark.x * size.width / imageSize.width;
      double y = landmark.y * size.height / imageSize.height;

      if (isFrontCamera) {
        x = size.width - x;
      }

      return Offset(x, y);
    }

    // Helper to draw line between two landmarks
    void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      final pos1 = getPosition(type1);
      final pos2 = getPosition(type2);
      if (pos1 != null && pos2 != null) {
        canvas.drawLine(pos1, pos2, linePaint);
      }
    }

    // Helper to draw joint
    void drawJoint(PoseLandmarkType type, {bool large = false}) {
      final pos = getPosition(type);
      if (pos != null) {
        final radius = large ? 12.0 : 8.0;
        final paint = large ? largeJointPaint : smallJointPaint;
        canvas.drawCircle(pos, radius, paint);
      }
    }

    // === DRAW SKELETON ===

    // Torso
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

    // Left arm
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);

    // Right arm
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // Left leg
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);

    // Right leg
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // === DRAW JOINTS ===

    // Large joints
    drawJoint(PoseLandmarkType.leftShoulder, large: true);
    drawJoint(PoseLandmarkType.rightShoulder, large: true);
    drawJoint(PoseLandmarkType.leftHip, large: true);
    drawJoint(PoseLandmarkType.rightHip, large: true);

    // Small joints
    drawJoint(PoseLandmarkType.leftElbow);
    drawJoint(PoseLandmarkType.rightElbow);
    drawJoint(PoseLandmarkType.leftWrist);
    drawJoint(PoseLandmarkType.rightWrist);
    drawJoint(PoseLandmarkType.leftKnee);
    drawJoint(PoseLandmarkType.rightKnee);
    drawJoint(PoseLandmarkType.leftAnkle);
    drawJoint(PoseLandmarkType.rightAnkle);

    // Head
    drawJoint(PoseLandmarkType.nose, large: true);

    // === OPTIONAL: Debug angle display ===
    if (currentAngle != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${currentAngle!.toStringAsFixed(1)}°',
          style: TextStyle(
            color: _skeletonColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: _skeletonColor.withOpacity(0.8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(20, size.height - 60));
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks ||
        oldDelegate.formQuality != formQuality ||
        oldDelegate.skeletonState != skeletonState ||
        oldDelegate.chargeProgress != chargeProgress ||
        oldDelegate.currentAngle != currentAngle;
  }
}

// =============================================================================
// HELPER: Convert form score (0-100) to FormQuality
// =============================================================================

FormQuality getFormQuality(double? formScore) {
  if (formScore == null) return FormQuality.neutral;
  if (formScore >= 80) return FormQuality.good;
  if (formScore >= 50) return FormQuality.okay;
  return FormQuality.bad;
}
