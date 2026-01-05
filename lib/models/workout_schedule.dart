import 'package:intl/intl.dart';

/// Model for scheduled workouts with alarm support
class WorkoutSchedule {
  final String id;
  final String workoutId;  // References workout from WorkoutData
  final String workoutName;
  final DateTime scheduledDate;
  final String? scheduledTime;  // Format: "HH:mm" (e.g., "08:00")
  final bool hasAlarm;
  final bool isCompleted;
  final DateTime createdAt;
  
  const WorkoutSchedule({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.scheduledDate,
    this.scheduledTime,
    this.hasAlarm = false,
    this.isCompleted = false,
    required this.createdAt,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'scheduledTime': scheduledTime,
      'hasAlarm': hasAlarm ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
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
      hasAlarm: (json['hasAlarm'] as int) == 1,
      isCompleted: (json['isCompleted'] as int) == 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
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

