import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_models.dart';
import '../services/storage_service.dart';
import '../services/workout_alarm_service.dart';

// Provider for the committed workout state
final committedWorkoutProvider = StateNotifierProvider<CommittedWorkoutNotifier, LockedWorkout?>((ref) {
  return CommittedWorkoutNotifier();
});

// Legacy alias for backward compatibility during transition
final lockedWorkoutProvider = committedWorkoutProvider;

class CommittedWorkoutNotifier extends StateNotifier<LockedWorkout?> {
  CommittedWorkoutNotifier() : super(null) {
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    final storage = await StorageService.getInstance();
    state = storage.getLockedWorkout();
  }

  Future<void> commitWorkout(WorkoutPreset preset, {List<WorkoutExercise>? customExercises}) async {
    final locked = LockedWorkout.fromPreset(preset, customExercises: customExercises);
    final storage = await StorageService.getInstance();
    await storage.saveLockedWorkout(locked);
    state = locked;
  }

  // Legacy alias for backward compatibility
  Future<void> lockWorkout(WorkoutPreset preset, {List<WorkoutExercise>? customExercises}) async {
    return commitWorkout(preset, customExercises: customExercises);
  }

  Future<void> clearWorkout() async {
    final storage = await StorageService.getInstance();
    await storage.clearLockedWorkout();
    state = null;
  }

  // Reload workout from storage (useful after app restart)
  Future<void> reloadWorkout() async {
    await _loadWorkout();
  }

  // Schedule workout for a future date
  Future<void> scheduleWorkout(
    DateTime date,
    WorkoutPreset preset, {
    List<WorkoutExercise>? customExercises,
    TimeOfDay? alarmTime,
    List<int> repeatDays = const [],
  }) async {
    final workout = LockedWorkout.fromPreset(preset, customExercises: customExercises);
    final storage = await StorageService.getInstance();
    await storage.scheduleWorkout(date, workout, alarmTime, repeatDays);
    
    // Schedule alarm if time is set
    if (alarmTime != null && repeatDays.isNotEmpty) {
      await WorkoutAlarmService.scheduleWorkoutAlarm(
        workoutId: workout.id,
        workoutName: workout.name,
        time: alarmTime,
        repeatDays: repeatDays,
      );
    }
  }

  // Get scheduled workout for a specific date
  Future<LockedWorkout?> getScheduledWorkout(DateTime date) async {
    final storage = await StorageService.getInstance();
    return storage.getScheduledWorkout(date);
  }

  // Cancel scheduled workout
  Future<void> cancelScheduledWorkout(DateTime date) async {
    final storage = await StorageService.getInstance();
    final workout = storage.getScheduledWorkout(date);
    
    if (workout != null) {
      // Cancel alarm
      await WorkoutAlarmService.cancelWorkoutAlarm(workout.id);
    }
    
    await storage.cancelScheduledWorkout(date);
  }
}

// Legacy alias for backward compatibility
class LockedWorkoutNotifier extends CommittedWorkoutNotifier {}
