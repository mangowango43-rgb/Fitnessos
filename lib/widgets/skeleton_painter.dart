import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/app_colors.dart';

/// CustomPainter that draws a glowing cyber-themed skeleton overlay
/// Uses Electric Cyan for lines and Cyber Lime for joints
class SkeletonPainter extends CustomPainter {
  final List<PoseLandmark>? landmarks;
  final Size imageSize;

  SkeletonPainter({
    required this.landmarks,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null || landmarks!.isEmpty) {
      return;
    }

    // Paint for lines (Electric Cyan with glow)
    final linePaint = Paint()
      ..color = AppColors.electricCyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Paint for large joints (Cyber Lime with glow) - shoulders, hips
    final largeJointPaint = Paint()
      ..color = AppColors.cyberLime
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Paint for small joints (Electric Cyan with glow) - wrists, ankles, elbows, knees
    final smallJointPaint = Paint()
      ..color = AppColors.electricCyan
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Helper function to get landmark by type
    PoseLandmark? getLandmark(PoseLandmarkType type) {
      try {
        return landmarks!.firstWhere((landmark) => landmark.type == type);
      } catch (e) {
        return null;
      }
    }

    // Helper function to convert landmark position to canvas position
    Offset? getPosition(PoseLandmark? landmark) {
      if (landmark == null) return null;
      // Scale from image coordinates to canvas coordinates
      final x = landmark.x * size.width / imageSize.width;
      final y = landmark.y * size.height / imageSize.height;
      return Offset(x, y);
    }

    // Helper function to draw line between two landmarks
    void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      final landmark1 = getLandmark(type1);
      final landmark2 = getLandmark(type2);
      final pos1 = getPosition(landmark1);
      final pos2 = getPosition(landmark2);

      if (pos1 != null && pos2 != null) {
        canvas.drawLine(pos1, pos2, linePaint);
      }
    }

    // Helper function to draw joint
    void drawJoint(PoseLandmarkType type, {bool large = false}) {
      final landmark = getLandmark(type);
      final pos = getPosition(landmark);

      if (pos != null) {
        final radius = large ? 8.0 : 6.0;
        final paint = large ? largeJointPaint : smallJointPaint;
        canvas.drawCircle(pos, radius, paint);
      }
    }

    // DRAW SKELETON CONNECTIONS

    // Torso connections
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

    // DRAW JOINTS (draw after lines so they appear on top)

    // Large joints (Cyber Lime) - shoulders and hips
    drawJoint(PoseLandmarkType.leftShoulder, large: true);
    drawJoint(PoseLandmarkType.rightShoulder, large: true);
    drawJoint(PoseLandmarkType.leftHip, large: true);
    drawJoint(PoseLandmarkType.rightHip, large: true);

    // Small joints (Electric Cyan) - elbows, wrists, knees, ankles
    drawJoint(PoseLandmarkType.leftElbow);
    drawJoint(PoseLandmarkType.rightElbow);
    drawJoint(PoseLandmarkType.leftWrist);
    drawJoint(PoseLandmarkType.rightWrist);
    drawJoint(PoseLandmarkType.leftKnee);
    drawJoint(PoseLandmarkType.rightKnee);
    drawJoint(PoseLandmarkType.leftAnkle);
    drawJoint(PoseLandmarkType.rightAnkle);
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) {
    // Only repaint if landmarks actually changed
    return oldDelegate.landmarks != landmarks;
  }
}

