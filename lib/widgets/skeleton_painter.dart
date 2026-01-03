import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

/// CINEMATIC SKELETON PAINTER
/// 
/// Not a fitness UI. A film studio for your body.
/// The user is the HERO. The skeleton makes them look like a superhero.
/// 
/// Three states:
/// - IDLE: Dim, subtle, waiting
/// - CHARGING: Building power, thickening, brightening
/// - IMPACT: Explosive white flash, maximum intensity
class CinematicSkeletonPainter extends CustomPainter {
  final List<PoseLandmark>? landmarks;
  final Size imageSize;
  final bool isFrontCamera;
  
  /// 0.0 = idle, 0.0-1.0 = charging, 1.0+ = impact
  final double intensity;
  
  /// True for the split second when rep counts
  final bool isImpact;
  
  // Color palette
  static const Color _dimCyan = Color(0x4D00F0FF);      // 30% opacity cyan
  static const Color _electricBlue = Color(0xFF00F0FF); // Full cyan
  static const Color _impactWhite = Color(0xFFFFFFFF);  // Pure white
  static const Color _neonCore = Color(0xFFCCFF00);     // Lime accent
  
  CinematicSkeletonPainter({
    required this.landmarks,
    required this.imageSize,
    this.isFrontCamera = true,
    this.intensity = 0.0,
    this.isImpact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null || landmarks!.isEmpty) return;
    
    // Calculate visual properties based on state
    final Color skeletonColor;
    final double lineWidth;
    final double glowRadius;
    final double jointSize;
    
    if (isImpact) {
      // IMPACT STATE - Explosive white flash
      skeletonColor = _impactWhite;
      lineWidth = 8.0;
      glowRadius = 16.0;
      jointSize = 12.0;
    } else if (intensity > 0) {
      // CHARGING STATE - Building power
      // Lerp from dim to electric based on intensity
      skeletonColor = Color.lerp(_dimCyan, _electricBlue, intensity)!;
      lineWidth = 2.0 + (intensity * 4.0);  // 2px → 6px
      glowRadius = 4.0 + (intensity * 8.0); // 4 → 12
      jointSize = 5.0 + (intensity * 4.0);  // 5 → 9
    } else {
      // IDLE STATE - Dim and subtle
      skeletonColor = _dimCyan;
      lineWidth = 2.0;
      glowRadius = 4.0;
      jointSize = 5.0;
    }
    
    // Main line paint with glow
    final linePaint = Paint()
      ..color = skeletonColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
    
    // Inner core line (brighter, thinner) for that neon tube look
    final corePaint = Paint()
      ..color = isImpact ? _impactWhite : _electricBlue.withOpacity(0.9)
      ..strokeWidth = lineWidth * 0.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Joint outer glow
    final jointGlowPaint = Paint()
      ..color = skeletonColor.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius + 4);
    
    // Joint core
    final jointCorePaint = Paint()
      ..color = isImpact ? _impactWhite : _electricBlue
      ..style = PaintingStyle.fill;
    
    // Create landmark map
    final map = {for (var lm in landmarks!) lm.type: lm};
    
    // Helper: Get screen position
    Offset? getPos(PoseLandmarkType type) {
      final lm = map[type];
      if (lm == null || lm.likelihood < 0.5) return null;
      
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
      // Inner core (only when charging or impact)
      if (intensity > 0.3 || isImpact) {
        canvas.drawLine(start, end, corePaint);
      }
    }
    
    // Helper: Draw joint with glow
    void drawJoint(PoseLandmarkType type, {double sizeMultiplier = 1.0}) {
      final pos = getPos(type);
      if (pos == null) return;
      
      final radius = jointSize * sizeMultiplier;
      
      // Outer glow
      canvas.drawCircle(pos, radius * 1.5, jointGlowPaint);
      // Core
      canvas.drawCircle(pos, radius * 0.6, jointCorePaint);
    }
    
    // =========================================================================
    // DRAW SKELETON - BODY ONLY
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
  }

  @override
  bool shouldRepaint(CinematicSkeletonPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks ||
           oldDelegate.intensity != intensity ||
           oldDelegate.isImpact != isImpact;
  }
}


// =============================================================================
// SCREEN BORDER FLASH - Peripheral feedback you can see while exercising
// =============================================================================

class ScreenBorderFlash extends StatelessWidget {
  final bool isActive;
  final Color color;
  final double width;
  
  const ScreenBorderFlash({
    super.key,
    this.isActive = false,
    this.color = const Color(0xFF00F0FF),
    this.width = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: color,
              width: width,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// CAMERA DIMMER - Makes the user POP against dark background
// =============================================================================

class CameraDimmer extends StatelessWidget {
  /// 0.0 = no dim, 1.0 = full black
  final double dimLevel;
  
  const CameraDimmer({
    super.key,
    this.dimLevel = 0.3,  // 30% dim by default
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withOpacity(dimLevel),
        ),
      ),
    );
  }
}


// =============================================================================
// IMPACT FLASH - Full screen white flash on rep count
// =============================================================================

class ImpactFlash extends StatefulWidget {
  final bool trigger;
  final VoidCallback? onComplete;
  
  const ImpactFlash({
    super.key,
    this.trigger = false,
    this.onComplete,
  });

  @override
  State<ImpactFlash> createState() => _ImpactFlashState();
}

class _ImpactFlashState extends State<ImpactFlash> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }
  
  @override
  void didUpdateWidget(ImpactFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        if (_opacity.value <= 0) return const SizedBox.shrink();
        
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.white.withOpacity(_opacity.value),
            ),
          ),
        );
      },
    );
  }
}


// =============================================================================
// REP COUNTER HUD - Minimal, tactical, cinematic
// =============================================================================

class CinematicRepCounter extends StatelessWidget {
  final int current;
  final int target;
  final bool flash;
  
  const CinematicRepCounter({
    super.key,
    required this.current,
    required this.target,
    this.flash = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: flash 
              ? const Color(0xFFCCFF00)  // Lime on flash
              : const Color(0xFF00F0FF).withOpacity(0.3),
          width: flash ? 2 : 1,
        ),
        boxShadow: flash ? [
          BoxShadow(
            color: const Color(0xFFCCFF00).withOpacity(0.4),
            blurRadius: 20,
          ),
        ] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$current',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: flash ? const Color(0xFFCCFF00) : Colors.white,
              height: 1,
              letterSpacing: -2,
            ),
          ),
          Text(
            '/ $target',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// POWER BAR - Vertical gauge that fills as you descend
// =============================================================================

class PowerBar extends StatelessWidget {
  /// 0.0 = empty (standing), 1.0 = full (at depth)
  final double fillLevel;
  
  /// Target line position (0.0-1.0), typically 0.6 for "good rep"
  final double targetLine;
  
  /// True when fill has passed the target
  final bool targetHit;
  
  const PowerBar({
    super.key,
    required this.fillLevel,
    this.targetLine = 0.6,
    this.targetHit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF00F0FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Fill bar (from bottom)
          Positioned(
            left: 2,
            right: 2,
            bottom: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              height: (200 - 4) * fillLevel.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: targetHit
                      ? [
                          const Color(0xFFCCFF00),  // Lime when target hit
                          const Color(0xFFFFFFFF),  // White at top
                        ]
                      : [
                          const Color(0xFF00F0FF).withOpacity(0.7),
                          const Color(0xFF00F0FF),
                        ],
                ),
                boxShadow: targetHit ? [
                  BoxShadow(
                    color: const Color(0xFFCCFF00).withOpacity(0.6),
                    blurRadius: 10,
                  ),
                ] : null,
              ),
            ),
          ),
          
          // Target line
          Positioned(
            left: 0,
            right: 0,
            bottom: (200 - 4) * targetLine,
            child: Container(
              height: 2,
              color: targetHit 
                  ? const Color(0xFFCCFF00)
                  : Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// COMBO DISPLAY - Shows streak, only appears at 3+
// =============================================================================

class ComboDisplay extends StatelessWidget {
  final int combo;
  
  const ComboDisplay({
    super.key,
    required this.combo,
  });

  @override
  Widget build(BuildContext context) {
    if (combo < 3) return const SizedBox.shrink();
    
    // Color based on combo level
    final Color comboColor;
    final String emoji;
    
    if (combo >= 10) {
      comboColor = const Color(0xFFFF003C);  // Red - ON FIRE
      emoji = '⚡';
    } else if (combo >= 5) {
      comboColor = const Color(0xFFFF9500);  // Orange - HOT
      emoji = '🔥';
    } else {
      comboColor = const Color(0xFFCCFF00);  // Lime - GOOD
      emoji = '';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: comboColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: comboColor.withOpacity(0.5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        '$emoji ${combo}x $emoji'.trim(),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
