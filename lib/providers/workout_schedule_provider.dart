import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_schedule.dart';
import '../services/workout_alarm_service.dart';

/// Provider for workout schedules - using Hive like FutureYou
final workoutSchedulesProvider = StateNotifierProvider<WorkoutSchedulesNotifier, List<WorkoutSchedule>>((ref) {
  return WorkoutSchedulesNotifier();
});

/// Notifier for managing workout schedules with Hive
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
      
      // Schedule alarm if enabled (like FutureYou)
      if (schedule.hasAlarm && schedule.scheduledTime != null && schedule.scheduledTime!.isNotEmpty) {
        debugPrint('   🔔 Attempting to schedule alarm...');
        
        // Check if alarm service is initialized
        if (!WorkoutAlarmService.isInitialized()) {
          debugPrint('   ❌ Alarm service not initialized!');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          await loadSchedules();
          return;
        }
        
        // Check permissions
        final hasPerms = await WorkoutAlarmService.hasPermissions();
        if (!hasPerms) {
          debugPrint('   ⚠️ Missing alarm permissions, requesting...');
          final granted = await WorkoutAlarmService.requestPermissions();
          if (!granted) {
            debugPrint('   ❌ User denied permissions. Alarm not scheduled.');
            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            await loadSchedules();
            return;
          }
        }
        
        final time = schedule.timeOfDay;
        if (time != null) {
          try {
            // Cancel existing alarms first
            await WorkoutAlarmService.cancelWorkoutAlarm(schedule.id);
            
            // If repeat days are set, use recurring alarm logic
            if (schedule.repeatDays.isNotEmpty) {
              debugPrint('   📅 Scheduling RECURRING alarm for days: ${schedule.repeatDays}');
              await WorkoutAlarmService.scheduleWorkoutAlarm(
                workoutId: schedule.id,
                workoutName: schedule.workoutName,
                time: time,
                repeatDays: schedule.repeatDays,
              );
            } else {
              // One-time alarm for specific date
              debugPrint('   📅 Scheduling ONE-TIME alarm for: ${schedule.scheduledDate}');
              await WorkoutAlarmService.scheduleOneTimeWorkoutAlarm(
                workoutId: schedule.id,
                workoutName: schedule.workoutName,
                scheduledDate: schedule.scheduledDate,
                time: time,
              );
            }
            
            debugPrint('   ✅ Alarm scheduling completed');
          } catch (e) {
            debugPrint('   ❌ Failed to schedule alarm: $e');
          }
        } else {
          debugPrint('   ❌ Invalid time format: ${schedule.scheduledTime}');
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

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    debugPrint('🗑️ Deleting schedule: $scheduleId');
    await _schedulesBox.delete(scheduleId);
    await WorkoutAlarmService.cancelWorkoutAlarm(scheduleId);
    await loadSchedules();
    debugPrint('✅ Schedule deleted');
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

