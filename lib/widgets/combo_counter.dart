import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/app_colors.dart';

/// Combo Counter widget - Shows combo streak with gaming-style feedback
/// Only appears when combo >= 3
class ComboCounter extends StatefulWidget {
  final int comboCount;
  final int maxCombo;

  const ComboCounter({
    super.key,
    required this.comboCount,
    required this.maxCombo,
  });

  @override
  State<ComboCounter> createState() => _ComboCounterState();
}

class _ComboCounterState extends State<ComboCounter> 
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  int _lastCombo = 0;

  @override
  void initState() {
    super.initState();
    _lastCombo = widget.comboCount;
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(ComboCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comboCount > _lastCombo && widget.comboCount >= 3) {
      // Combo increased - trigger shake animation
      _shakeController
        ..reset()
        ..forward();
      _lastCombo = widget.comboCount;
    } else if (widget.comboCount < _lastCombo) {
      _lastCombo = widget.comboCount;
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Get color based on combo count
  Color get _comboColor {
    if (widget.comboCount >= 10) return AppColors.neonCrimson; // RED at 10X
    if (widget.comboCount >= 5) return const Color(0xFFFFAA00); // AMBER at 5X
    return AppColors.cyberLime; // LIME at 3X
  }

  /// Get emoji based on combo count
  String get _comboEmoji {
    if (widget.comboCount >= 10) return '⚡'; // Lightning at 10X
    if (widget.comboCount >= 5) return '🔥'; // Fire at 5X
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if combo < 3
    if (widget.comboCount < 3) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        // Calculate shake offset
        final shakeValue = sin(_shakeAnimation.value * pi * 4) * 5;
        
        // Calculate scale for pop effect
        final scale = 1.0 + (_shakeAnimation.value < 0.5 
            ? _shakeAnimation.value * 0.4  // Scale up
            : (1.0 - _shakeAnimation.value) * 0.4); // Scale down

        return Transform.translate(
          offset: Offset(shakeValue, 0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.8),
                border: Border.all(
                  color: _comboColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _comboColor.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Combo count
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.comboCount}X',
                        style: TextStyle(
                          color: _comboColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: _comboColor.withOpacity(0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'COMBO',
                        style: TextStyle(
                          color: _comboColor.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  
                  // Emoji overlay (fire/lightning)
                  if (_comboEmoji.isNotEmpty)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Text(
                        _comboEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

