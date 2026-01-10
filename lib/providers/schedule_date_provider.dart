import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// Provider for the selected date when scheduling workouts
/// This allows home tab to pass the selected date to workouts tab
final selectedScheduleDateProvider = StateProvider<DateTime?>((ref) => null);

/// Provider to indicate that user wants to schedule (not just commit)
final isSchedulingModeProvider = StateProvider<bool>((ref) => false);

