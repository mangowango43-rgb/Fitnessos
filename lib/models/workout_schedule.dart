import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'workout_schedule.g.dart';

/// Model for scheduled workouts with alarm support - using Hive like FutureYou
@HiveType(typeId: 1)
class WorkoutSchedule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String workoutId;  // References workout from WorkoutData

  @HiveField(2)
  String workoutName;

  @HiveField(3)
  DateTime scheduledDate;

  @HiveField(4)
  String? scheduledTime;  // Format: "HH:mm" (e.g., "08:00")

  @HiveField(5)
  bool hasAlarm;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  List<int> repeatDays; // 0=Sun...6=Sat (like FutureYou)

  WorkoutSchedule({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.scheduledDate,
    this.scheduledTime,
    this.hasAlarm = false,
    this.isCompleted = false,
    required this.createdAt,
    this.repeatDays = const [],
  });

  /// Get TimeOfDay from string time
  TimeOfDay? get timeOfDay {
    if (scheduledTime == null || scheduledTime!.isEmpty) return null;
    final parts = scheduledTime!.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Check if scheduled for a specific date (based on repeatDays if set)
  bool isScheduledForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final scheduleOnly = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    
    // If no repeat days, only check if it's the exact scheduled date
    if (repeatDays.isEmpty) {
      return dateOnly == scheduleOnly;
    }
    
    // If repeat days are set, check if date's weekday matches
    // Dart: Monday=1..Sunday=7  -> Our model: Sunday=0..Saturday=6
    final weekday = date.weekday == 7 ? 0 : date.weekday;
    return repeatDays.contains(weekday) && !dateOnly.isBefore(scheduleOnly);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'scheduledTime': scheduledTime,
      'hasAlarm': hasAlarm,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'repeatDays': repeatDays,
    };
  }

  /// Create from JSON
  factory WorkoutSchedule.fromJson(Map<String, dynamic> json) {
    return WorkoutSchedule(
      id: json['id'] as String,
      workoutId: json['workoutId'] as String,
      workoutName: json['workoutName'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      scheduledTime: json['scheduledTime'] as String?,
      hasAlarm: json['hasAlarm'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      repeatDays: (json['repeatDays'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }

  /// Copy with modifications
  WorkoutSchedule copyWith({
    String? id,
    String? workoutId,
    String? workoutName,
    DateTime? scheduledDate,
    String? scheduledTime,
    bool? hasAlarm,
    bool? isCompleted,
    DateTime? createdAt,
    List<int>? repeatDays,
  }) {
    return WorkoutSchedule(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  /// Get formatted date
  String get formattedDate {
    return DateFormat('EEE, MMM d').format(scheduledDate);
  }

  /// Get formatted time
  String get formattedTime {
    if (scheduledTime == null) return 'Anytime';
    return scheduledTime!;
  }

  /// Check if this is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
           scheduledDate.month == now.month &&
           scheduledDate.day == now.day;
  }

  /// Check if this is in the past
  bool get isPast {
    final now = DateTime.now();
    final scheduleDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return scheduleDate.isBefore(today);
  }

  /// Get unique alarm ID for notifications
  int get alarmId {
    return id.hashCode.abs() % 2147483647; // Max int32 value
  }
}

