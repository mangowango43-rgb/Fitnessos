import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/app_colors.dart';

/// Skeleton visual states
enum SkeletonState {
  idle,      // White, subtle - waiting
  charging,  // Cyan, building - descending into rep
  perfect,   // Bright cyan - locked or good form
  repFlash,  // Green flash - rep just counted
}

/// SKELETON PAINTER
/// 
/// Clean body skeleton. No face dots. No red.
/// Responds to state changes with color/glow/thickness.
class SkeletonPainter extends CustomPainter {
  final List<PoseLandmark>? landmarks;
  final Size imageSize;
  final bool isFrontCamera;
  final SkeletonState skeletonState;
  
  // Optional overrides
  final Color? colorOverride;
  final double? glowOverride;
  
  SkeletonPainter({
    required this.landmarks,
    required this.imageSize,
    this.isFrontCamera = true,
    this.skeletonState = SkeletonState.idle,
    this.colorOverride,
    this.glowOverride,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null || landmarks!.isEmpty) return;
    
    // Get visual properties based on state
    final Color color = colorOverride ?? _getColor();
    final double glow = glowOverride ?? _getGlow();
    final double lineWidth = _getLineWidth();
    
    // Main line paint with glow
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow);
    
    // Inner core line (brighter, thinner) for neon tube look
    final corePaint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = lineWidth * 0.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Joint outer glow
    final jointGlowPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow + 4);
    
    // Joint core
    final jointCorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Create landmark map
    final map = {for (var lm in landmarks!) lm.type: lm};
    
    // Helper: Get screen position
    Offset? getPos(PoseLandmarkType type) {
      final lm = map[type];
      if (lm == null || lm.likelihood < 0.3) return null;
      
      double x = isFrontCamera 
          ? size.width - (lm.x / imageSize.width * size.width)
          : lm.x / imageSize.width * size.width;
      double y = lm.y / imageSize.height * size.height;
      
      return Offset(x, y);
    }
    
    // Helper: Draw bone with glow + core
    void drawBone(PoseLandmarkType from, PoseLandmarkType to) {
      final start = getPos(from);
      final end = getPos(to);
      if (start == null || end == null) return;
      
      // Outer glow
      canvas.drawLine(start, end, linePaint);
      // Inner core (only when not idle)
      if (skeletonState != SkeletonState.idle) {
        canvas.drawLine(start, end, corePaint);
      }
    }
    
    // Helper: Draw joint with glow
    void drawJoint(PoseLandmarkType type, {double sizeMultiplier = 1.0}) {
      final pos = getPos(type);
      if (pos == null) return;
      
      final radius = _getJointSize() * sizeMultiplier;
      
      // Outer glow
      canvas.drawCircle(pos, radius * 1.5, jointGlowPaint);
      // Core
      canvas.drawCircle(pos, radius * 0.6, jointCorePaint);
    }
    
    // =========================================================================
    // DRAW SKELETON - BODY ONLY, NO FACE
    // =========================================================================
    
    // TORSO
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawBone(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawBone(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    
    // LEFT ARM
    drawBone(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawBone(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    
    // RIGHT ARM
    drawBone(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawBone(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    
    // LEFT LEG
    drawBone(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawBone(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    
    // RIGHT LEG
    drawBone(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawBone(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    
    // JOINTS - Major joints bigger
    drawJoint(PoseLandmarkType.leftShoulder, sizeMultiplier: 1.3);
    drawJoint(PoseLandmarkType.rightShoulder, sizeMultiplier: 1.3);
    drawJoint(PoseLandmarkType.leftHip, sizeMultiplier: 1.3);
    drawJoint(PoseLandmarkType.rightHip, sizeMultiplier: 1.3);
    
    // Arms
    drawJoint(PoseLandmarkType.leftElbow);
    drawJoint(PoseLandmarkType.rightElbow);
    drawJoint(PoseLandmarkType.leftWrist, sizeMultiplier: 0.8);
    drawJoint(PoseLandmarkType.rightWrist, sizeMultiplier: 0.8);
    
    // Legs
    drawJoint(PoseLandmarkType.leftKnee, sizeMultiplier: 1.1);
    drawJoint(PoseLandmarkType.rightKnee, sizeMultiplier: 1.1);
    drawJoint(PoseLandmarkType.leftAnkle, sizeMultiplier: 0.8);
    drawJoint(PoseLandmarkType.rightAnkle, sizeMultiplier: 0.8);
    
    // NO NOSE. NO FACE. Just body.
  }
  
  Color _getColor() {
    switch (skeletonState) {
      case SkeletonState.idle:
        return AppColors.white70;
      case SkeletonState.charging:
        return AppColors.electricCyan;
      case SkeletonState.perfect:
        return AppColors.electricCyan;
      case SkeletonState.repFlash:
        return AppColors.cyberLime;
    }
  }
  
  double _getGlow() {
    switch (skeletonState) {
      case SkeletonState.idle:
        return 4.0;
      case SkeletonState.charging:
        return 8.0;
      case SkeletonState.perfect:
        return 12.0;
      case SkeletonState.repFlash:
        return 16.0;
    }
  }
  
  double _getLineWidth() {
    switch (skeletonState) {
      case SkeletonState.idle:
        return 2.0;
      case SkeletonState.charging:
        return 3.0;
      case SkeletonState.perfect:
        return 4.0;
      case SkeletonState.repFlash:
        return 6.0;
    }
  }
  
  double _getJointSize() {
    switch (skeletonState) {
      case SkeletonState.idle:
        return 5.0;
      case SkeletonState.charging:
        return 6.0;
      case SkeletonState.perfect:
        return 7.0;
      case SkeletonState.repFlash:
        return 9.0;
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks ||
           oldDelegate.skeletonState != skeletonState ||
           oldDelegate.colorOverride != colorOverride ||
           oldDelegate.glowOverride != glowOverride;
  }
}
