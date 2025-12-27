import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double? opacity;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity ?? 0.05),
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: Border.all(
              color: borderColor ?? AppColors.white10,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassmorphismCardStrong extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const GlassmorphismCardStrong({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.white15,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

