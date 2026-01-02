import 'package:flutter/services.dart';
import 'dart:io';

/// Platform-safe haptic feedback helper
/// Uses multiple fallback methods for maximum compatibility
class HapticHelper {
  /// Perfect rep completed - HEAVY impact
  static Future<void> perfectRepHaptic() async {
    await _triggerHaptic(HapticType.heavy);
  }

  /// Good rep completed - MEDIUM impact
  static Future<void> goodRepHaptic() async {
    await _triggerHaptic(HapticType.medium);
  }

  /// Missed rep or bad form - LIGHT impact
  static Future<void> missedRepHaptic() async {
    await _triggerHaptic(HapticType.light);
  }

  /// Combo break - VIBRATE (error feel)
  static Future<void> comboBreakHaptic() async {
    await _triggerHaptic(HapticType.vibrate);
  }

  /// Combo milestone reached (5X, 10X) - Selection click
  static Future<void> comboMilestoneHaptic() async {
    await _triggerHaptic(HapticType.selection);
  }

  /// Set complete - HEAVY impact
  static Future<void> setCompleteHaptic() async {
    await _triggerHaptic(HapticType.heavy);
  }

  /// Workout complete - DOUBLE HEAVY impact
  static Future<void> workoutCompleteHaptic() async {
    await _triggerHaptic(HapticType.heavy);
    await Future.delayed(const Duration(milliseconds: 150));
    await _triggerHaptic(HapticType.heavy);
  }

  /// Core haptic trigger with multiple fallbacks
  static Future<void> _triggerHaptic(HapticType type) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      switch (type) {
        case HapticType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case HapticType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticType.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticType.selection:
          await HapticFeedback.selectionClick();
          break;
        case HapticType.vibrate:
          await HapticFeedback.vibrate();
          break;
      }
      print('📳 Haptic triggered: $type');
    } catch (e) {
      // Fallback to basic vibrate if specific haptic fails
      print('⚠️ Haptic fallback for $type: $e');
      try {
        await HapticFeedback.vibrate();
      } catch (_) {
        // Device doesn't support haptics at all
        print('❌ No haptic support on this device');
      }
    }
  }
}

enum HapticType {
  heavy,
  medium,
  light,
  selection,
  vibrate,
}
