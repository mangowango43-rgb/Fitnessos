import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_schedule.dart';
import '../services/workout_schedule_db.dart';
import '../services/workout_alarm_service.dart';

/// Provider for workout schedules
final workoutSchedulesProvider = StateNotifierProvider<WorkoutSchedulesNotifier, List<WorkoutSchedule>>((ref) {
  return WorkoutSchedulesNotifier();
});

/// Notifier for managing workout schedules
class WorkoutSchedulesNotifier extends StateNotifier<List<WorkoutSchedule>> {
  WorkoutSchedulesNotifier() : super([]) {
    loadSchedules();
  }

  final _db = WorkoutScheduleDB.instance;

  /// Load all schedules from database
  Future<void> loadSchedules() async {
    final schedules = await _db.getAllSchedules();
    state = schedules;
  }

  /// Add or update a schedule
  Future<void> saveSchedule(WorkoutSchedule schedule) async {
    await _db.saveSchedule(schedule);
    
    // Schedule alarm if enabled
    if (schedule.hasAlarm && schedule.scheduledTime != null) {
      // Parse time string "HH:mm" to TimeOfDay
      final timeParts = schedule.scheduledTime!.split(':');
      if (timeParts.length == 2) {
        final time = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
        
        // Use ONE-TIME alarm for specific date, not recurring weekly alarm
        await WorkoutAlarmService.scheduleOneTimeWorkoutAlarm(
          workoutId: schedule.id,
          workoutName: schedule.workoutName,
          scheduledDate: schedule.scheduledDate,
          time: time,
        );
      }
    }
    
    await loadSchedules();
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    await _db.deleteSchedule(scheduleId);
    await WorkoutAlarmService.cancelWorkoutAlarm(scheduleId);
    await loadSchedules();
  }

  /// Mark schedule as completed
  Future<void> markAsCompleted(String scheduleId) async {
    await _db.markAsCompleted(scheduleId);
    await loadSchedules();
  }

  /// Get schedules for a specific date
  List<WorkoutSchedule> getSchedulesForDate(DateTime date) {
    return state.where((schedule) {
      return schedule.scheduledDate.year == date.year &&
             schedule.scheduledDate.month == date.month &&
             schedule.scheduledDate.day == date.day;
    }).toList();
  }

  /// Get today's hero workout (first non-completed workout for today)
  WorkoutSchedule? getTodaysHeroWorkout() {
    final now = DateTime.now();
    final todaySchedules = state.where((schedule) {
      return schedule.scheduledDate.year == now.year &&
             schedule.scheduledDate.month == now.month &&
             schedule.scheduledDate.day == now.day &&
             !schedule.isCompleted;
    }).toList();

    return todaySchedules.isNotEmpty ? todaySchedules.first : null;
  }
}

/// Provider for today's hero workout
final todaysHeroWorkoutProvider = Provider<WorkoutSchedule?>((ref) {
  final schedules = ref.watch(workoutSchedulesProvider);
  final now = DateTime.now();
  
  final todaySchedules = schedules.where((schedule) {
    return schedule.scheduledDate.year == now.year &&
           schedule.scheduledDate.month == now.month &&
           schedule.scheduledDate.day == now.day &&
           !schedule.isCompleted;
  }).toList();

  return todaySchedules.isNotEmpty ? todaySchedules.first : null;
});

