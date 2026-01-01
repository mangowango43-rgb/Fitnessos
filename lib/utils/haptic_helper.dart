import 'package:flutter/services.dart';
import 'dart:io';

/// Platform-safe haptic feedback helper
/// Provides different haptic intensities for various workout events
class HapticHelper {
  /// Perfect rep completed - HEAVY impact
  static Future<void> perfectRepHaptic() async {
    if (_isHapticSupported()) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Good rep completed - MEDIUM impact
  static Future<void> goodRepHaptic() async {
    if (_isHapticSupported()) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Missed rep or bad form - LIGHT impact
  static Future<void> missedRepHaptic() async {
    if (_isHapticSupported()) {
      await HapticFeedback.lightImpact();
    }
  }

  /// Combo break - VIBRATE (error feel)
  static Future<void> comboBreakHaptic() async {
    if (_isHapticSupported()) {
      await HapticFeedback.vibrate();
    }
  }

  /// Combo milestone reached (5X, 10X) - Selection click
  static Future<void> comboMilestoneHaptic() async {
    if (_isHapticSupported()) {
      await HapticFeedback.selectionClick();
    }
  }

  /// Set complete - HEAVY impact
  static Future<void> setCompleteHaptic() async {
    if (_isHapticSupported()) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Workout complete - DOUBLE HEAVY impact
  static Future<void> workoutCompleteHaptic() async {
    if (_isHapticSupported()) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    }
  }

  /// Check if platform supports haptics
  static bool _isHapticSupported() {
    return Platform.isIOS || Platform.isAndroid;
  }
}

