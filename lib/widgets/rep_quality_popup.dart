import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/rep_quality.dart';

/// Floating text that shows rep quality (PERFECT/GOOD/MISS)
/// Fades in, scales up, then fades out
class RepQualityPopup extends StatefulWidget {
  final RepQuality quality;
  
  const RepQualityPopup({
    super.key,
    required this.quality,
  });

  @override
  State<RepQualityPopup> createState() => _RepQualityPopupState();
}

class _RepQualityPopupState extends State<RepQualityPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade: 0 → 1 → 0
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Scale: 0.5 → 1.2 → 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Get text based on quality
  String get _text {
    switch (widget.quality) {
      case RepQuality.perfect:
        return 'PERFECT';
      case RepQuality.good:
        return 'GOOD';
      case RepQuality.miss:
        return 'MISS';
    }
  }

  /// Get color based on quality
  Color get _color {
    switch (widget.quality) {
      case RepQuality.perfect:
        return AppColors.cyberLime;
      case RepQuality.good:
        return const Color(0xFFFFAA00); // Amber
      case RepQuality.miss:
        return AppColors.neonCrimson;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _color.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                _text,
                style: TextStyle(
                  color: _color,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: _color.withOpacity(0.8),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

