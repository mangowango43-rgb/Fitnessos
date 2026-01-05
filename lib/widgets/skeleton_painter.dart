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

/// Simplified skeleton states - clean 2-state system
enum SkeletonState {
  normal,   // White bones, black joints - default state
  success,  // Blue bones, green joints - rep counted flash
}

/// CustomPainter that draws a glowing cyber-themed skeleton overlay
/// Color changes based on form quality during exercise
/// GAMING FEATURES: Dynamic line thickness, state-based colors, perfect flash
/// NO FACE DOTS - Body only for clean cinematic look
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

  /// Bone color - simple 2-state system
  Color get _skeletonColor {
    switch (skeletonState) {
      case SkeletonState.normal:
        return Colors.white;  // Clean white bones
      case SkeletonState.success:
        return const Color(0xFF00F0FF);  // Electric blue flash
    }
  }

  /// Joint color - simple 2-state system
  Color get _jointColor {
    switch (skeletonState) {
      case SkeletonState.normal:
        return Colors.black.withOpacity(0.8);  // Shiny black joints
      case SkeletonState.success:
        return const Color(0xFF00FF88);  // Emerald green flash
    }
  }

  /// Glow intensity - subtle normally, strong on success
  double get _glowIntensity {
    switch (skeletonState) {
      case SkeletonState.normal:
        return 4.0;  // Subtle glow
      case SkeletonState.success:
        return 14.0;  // Strong glow on rep count
    }
  }

  /// Line width - consistent, slightly thicker on success
  double get _lineWidth {
    switch (skeletonState) {
      case SkeletonState.normal:
        return 2.5;
      case SkeletonState.success:
        return 4.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null || landmarks!.isEmpty) {
      return;
    }

    // OUTER GLOW - the neon effect
    final glowPaint = Paint()
      ..color = _skeletonColor.withOpacity(0.6)
      ..strokeWidth = _lineWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _glowIntensity);

    // MAIN LINES - solid core
    final linePaint = Paint()
      ..color = _skeletonColor
      ..strokeWidth = _lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // INNER CORE - bright center line for neon tube effect
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = _lineWidth * 0.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Joint outer glow
    final jointGlowPaint = Paint()
      ..color = _jointColor.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _glowIntensity + 4);

    // Joint core
    final jointCorePaint = Paint()
      ..color = _jointColor
      ..style = PaintingStyle.fill;

    // Create a map for quick landmark lookup
    final Map<PoseLandmarkType, PoseLandmark> landmarkMap = {};
    for (final landmark in landmarks!) {
      landmarkMap[landmark.type] = landmark;
    }

    // Helper function to get position with proper scaling and mirroring
    Offset? getPosition(PoseLandmarkType type) {
      final landmark = landmarkMap[type];
      if (landmark == null) return null;
      
      // Skip low confidence landmarks
      if (landmark.likelihood < 0.3) return null;

      double x = landmark.x * size.width / imageSize.width;
      double y = landmark.y * size.height / imageSize.height;

      if (isFrontCamera) {
        x = size.width - x;
      }

      return Offset(x, y);
    }

    // Helper to draw line between two landmarks - WITH GLOW
    void drawBone(PoseLandmarkType type1, PoseLandmarkType type2) {
      final pos1 = getPosition(type1);
      final pos2 = getPosition(type2);
      if (pos1 != null && pos2 != null) {
        // Layer 1: Outer glow
        canvas.drawLine(pos1, pos2, glowPaint);
        // Layer 2: Main line
        canvas.drawLine(pos1, pos2, linePaint);
        // Layer 3: Inner core (only on success)
        if (skeletonState == SkeletonState.success) {
          canvas.drawLine(pos1, pos2, corePaint);
        }
      }
    }

    // Helper to draw joint with glow - FIXED sizes (no chargeProgress scaling)
    void drawJoint(PoseLandmarkType type, {bool large = false}) {
      final pos = getPosition(type);
      if (pos != null) {
        final radius = large ? 12.0 : 8.0;  // Fixed sizes, no chargeProgress scaling

        // Outer glow
        canvas.drawCircle(pos, radius * 1.8, jointGlowPaint);
        // Core
        canvas.drawCircle(pos, radius * 0.7, jointCorePaint);
      }
    }

    // === DRAW SKELETON - BODY ONLY, NO FACE ===

    // Torso
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawBone(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawBone(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

    // Left arm
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawBone(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);

    // Right arm
    drawBone(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawBone(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // Left leg
    drawBone(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawBone(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);

    // Right leg
    drawBone(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawBone(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // === DRAW JOINTS - BODY ONLY, NO NOSE ===

    // Major joints (bigger)
    drawJoint(PoseLandmarkType.leftShoulder, large: true);
    drawJoint(PoseLandmarkType.rightShoulder, large: true);
    drawJoint(PoseLandmarkType.leftHip, large: true);
    drawJoint(PoseLandmarkType.rightHip, large: true);

    // Arm joints
    drawJoint(PoseLandmarkType.leftElbow);
    drawJoint(PoseLandmarkType.rightElbow);
    drawJoint(PoseLandmarkType.leftWrist);
    drawJoint(PoseLandmarkType.rightWrist);

    // Leg joints
    drawJoint(PoseLandmarkType.leftKnee, large: true);
    drawJoint(PoseLandmarkType.rightKnee, large: true);
    drawJoint(PoseLandmarkType.leftAnkle);
    drawJoint(PoseLandmarkType.rightAnkle);

    // NO NOSE. NO FACE. Just body.

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
