import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_schedule.dart';
import '../services/workout_alarm_service.dart';

/// Provider for workout schedules - using Hive like FutureYou
final workoutSchedulesProvider = StateNotifierProvider<WorkoutSchedulesNotifier, List<WorkoutSchedule>>((ref) {
  return WorkoutSchedulesNotifier();
});

/// Notifier for managing workout schedules with Hive (like FutureYou's HabitEngine)
class WorkoutSchedulesNotifier extends StateNotifier<List<WorkoutSchedule>> {
  WorkoutSchedulesNotifier() : super([]) {
    loadSchedules();
  }

  Box<WorkoutSchedule> get _schedulesBox => Hive.box<WorkoutSchedule>('workout_schedules');

  /// Load all schedules from Hive
  Future<void> loadSchedules() async {
    debugPrint('📥 Loading workout schedules from Hive...');
    state = _schedulesBox.values.toList();
    debugPrint('✅ Loaded ${state.length} workout schedules');
  }

  /// Add or update a schedule (like FutureYou's addHabit)
  Future<void> saveSchedule(WorkoutSchedule schedule) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('💾 Saving workout schedule: ${schedule.workoutName}');
      debugPrint('   - Date: ${schedule.scheduledDate}');
      debugPrint('   - Has Alarm: ${schedule.hasAlarm}');
      debugPrint('   - Time: ${schedule.scheduledTime ?? "N/A"}');
      debugPrint('   - Repeat Days: ${schedule.repeatDays}');
      
      // Save to Hive
      await _schedulesBox.put(schedule.id, schedule);
      debugPrint('   ✅ Schedule saved to Hive');
      
      // Schedule alarm if enabled (using FutureYou's exact logic)
      if (schedule.hasAlarm && schedule.scheduledTime != null && schedule.scheduledTime!.isNotEmpty) {
        debugPrint('   🔔 Attempting to schedule alarm using FutureYou logic...');
        
        try {
          // Cancel existing alarms first
          await WorkoutAlarmService.cancelAlarm(schedule.id);
          
          // Schedule new alarm
          await WorkoutAlarmService.scheduleAlarm(schedule);
          
          debugPrint('   ✅ Alarm scheduling completed');
        } catch (e) {
          debugPrint('   ❌ Failed to schedule alarm: $e');
        }
      }
      
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      await loadSchedules();
    } catch (e, stack) {
      debugPrint('❌ Error saving schedule: $e');
      debugPrint('Stack: $stack');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Delete a schedule (like FutureYou's deleteHabit)
  Future<void> deleteSchedule(String scheduleId) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🗑️ DELETING SCHEDULE: $scheduleId');
    
    // Find schedule details for logging
    final schedule = _schedulesBox.get(scheduleId);
    if (schedule != null) {
      debugPrint('   📝 Workout: "${schedule.workoutName}"');
      debugPrint('   ⏰ Had alarm: ${schedule.hasAlarm}');
      debugPrint('   🕐 Time: ${schedule.scheduledTime ?? "N/A"}');
    }
    
    // Step 1: Cancel alarms FIRST (before deleting from storage)
    try {
      debugPrint('🔔 Step 1: Cancelling alarms...');
      await WorkoutAlarmService.cancelAlarm(scheduleId);
      debugPrint('✅ Alarm cancellation completed');
    } catch (e, stack) {
      debugPrint('❌ CRITICAL ERROR: Failed to cancel alarms for schedule: $scheduleId');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      debugPrint('⚠️ Continuing with schedule deletion despite alarm cancellation failure');
    }
    
    // Step 2: Delete from storage
    debugPrint('💾 Step 2: Deleting from Hive...');
    await _schedulesBox.delete(scheduleId);
    
    // Step 3: Reload state
    debugPrint('🔄 Step 3: Reloading schedules...');
    await loadSchedules();
    
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✅ DELETION COMPLETE for: "${schedule?.workoutName ?? scheduleId}"');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Mark schedule as completed
  Future<void> markAsCompleted(String scheduleId) async {
    final schedule = _schedulesBox.get(scheduleId);
    if (schedule == null) return;
    
    final updated = schedule.copyWith(isCompleted: true);
    await _schedulesBox.put(scheduleId, updated);
    await loadSchedules();
    debugPrint('✅ Schedule marked as completed');
  }

  /// Get schedules for a specific date
  List<WorkoutSchedule> getSchedulesForDate(DateTime date) {
    return state.where((schedule) {
      return schedule.isScheduledForDate(date);
    }).toList();
  }

  /// Get today's hero workout (first non-completed workout for today)
  WorkoutSchedule? getTodaysHeroWorkout() {
    final now = DateTime.now();
    final todaySchedules = state.where((schedule) {
      return schedule.isScheduledForDate(now) && !schedule.isCompleted;
    }).toList();

    return todaySchedules.isNotEmpty ? todaySchedules.first : null;
  }
}

/// Provider for today's hero workout
final todaysHeroWorkoutProvider = Provider<WorkoutSchedule?>((ref) {
  final schedules = ref.watch(workoutSchedulesProvider);
  final now = DateTime.now();
  
  final todaySchedules = schedules.where((schedule) {
    return schedule.isScheduledForDate(now) && !schedule.isCompleted;
  }).toList();

  return todaySchedules.isNotEmpty ? todaySchedules.first : null;
});
