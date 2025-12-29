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

/// CustomPainter that draws a glowing cyber-themed skeleton overlay
/// Color changes based on form quality during exercise
class SkeletonPainter extends CustomPainter {
  final List<PoseLandmark>? landmarks;
  final Size imageSize;
  final bool isFrontCamera;
  final FormQuality formQuality;
  final double? currentAngle; // Optional: display current angle for debugging

  SkeletonPainter({
    required this.landmarks,
    required this.imageSize,
    this.isFrontCamera = true,
    this.formQuality = FormQuality.neutral,
    this.currentAngle,
  });

  /// Get skeleton color based on form quality
  Color get _skeletonColor {
    switch (formQuality) {
      case FormQuality.good:
        return const Color(0xFF00FF66); // Bright Green
      case FormQuality.okay:
        return const Color(0xFFFFDD00); // Yellow/Gold
      case FormQuality.bad:
        return const Color(0xFFFF003C); // Neon Red (your Neon Crimson)
      case FormQuality.neutral:
        return AppColors.electricCyan; // Default cyan
    }
  }

  /// Get joint color based on form quality
  Color get _jointColor {
    switch (formQuality) {
      case FormQuality.good:
        return const Color(0xFF00FF66);
      case FormQuality.okay:
        return const Color(0xFFFFDD00);
      case FormQuality.bad:
        return const Color(0xFFFF003C);
      case FormQuality.neutral:
        return AppColors.cyberLime;
    }
  }

  /// Get glow intensity based on form quality
  double get _glowIntensity {
    switch (formQuality) {
      case FormQuality.good:
        return 10.0; // Stronger glow for good form
      case FormQuality.okay:
        return 8.0;
      case FormQuality.bad:
        return 12.0; // Extra glow to make red visible
      case FormQuality.neutral:
        return 6.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null || landmarks!.isEmpty) {
      return;
    }

    // Paint for lines with form-based color
    final linePaint = Paint()
      ..color = _skeletonColor
      ..strokeWidth = 4
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
