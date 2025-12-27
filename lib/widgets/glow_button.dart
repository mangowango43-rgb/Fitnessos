import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class GlowButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? glowColor;
  final Color? textColor;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final double? fontSize;
  final IconData? icon;

  const GlowButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.glowColor,
    this.textColor,
    this.backgroundColor,
    this.padding,
    this.fontSize,
    this.icon,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? AppColors.cyberLime;
    final backgroundColor = widget.backgroundColor ?? AppColors.cyberLime;
    final textColor = widget.textColor ?? Colors.black;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        child: Container(
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: glowColor.withOpacity(0.4),
                blurRadius: 60,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: textColor, size: widget.fontSize ?? 24),
                const SizedBox(width: 12),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: widget.fontSize ?? 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlowButtonOutline extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? borderColor;
  final Color? textColor;
  final EdgeInsets? padding;

  const GlowButtonOutline({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderColor,
    this.textColor,
    this.padding,
  });

  @override
  State<GlowButtonOutline> createState() => _GlowButtonOutlineState();
}

class _GlowButtonOutlineState extends State<GlowButtonOutline> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: _isPressed ? AppColors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.borderColor ?? AppColors.white20,
            width: 1,
          ),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            color: widget.textColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

