import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/workout_history_db.dart';

/// Stats model - all real data from database
class WorkoutStats {
  final int totalWorkouts;
  final int currentStreak;
  final int longestStreak;
  final int repsThisWeek;
  final int repsLastWeek;
  final int workoutsThisWeek;
  final int totalMinutes;
  final int totalLifetimeReps;
  final double avgFormScore;
  final DateTime? lastWorkoutDate;

  const WorkoutStats({
    required this.totalWorkouts,
    required this.currentStreak,
    required this.longestStreak,
    required this.repsThisWeek,
    required this.repsLastWeek,
    required this.workoutsThisWeek,
    required this.totalMinutes,
    required this.totalLifetimeReps,
    required this.avgFormScore,
    this.lastWorkoutDate,
  });

  /// Create empty stats (when no workouts exist yet)
  factory WorkoutStats.empty() {
    return const WorkoutStats(
      totalWorkouts: 0,
      currentStreak: 0,
      longestStreak: 0,
      repsThisWeek: 0,
      repsLastWeek: 0,
      workoutsThisWeek: 0,
      totalMinutes: 0,
      totalLifetimeReps: 0,
      avgFormScore: 0.0,
      lastWorkoutDate: null,
    );
  }

  /// Get reps comparison (this week vs last week)
  int get repsComparison => repsThisWeek - repsLastWeek;
  
  /// Get percentage change
  double get repsChangePercent {
    if (repsLastWeek == 0) return 0.0;
    return ((repsThisWeek - repsLastWeek) / repsLastWeek) * 100;
  }

  /// Format total training time
  String get formattedTrainingTime {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  /// Check if user trained today
  bool get trainedToday {
    if (lastWorkoutDate == null) return false;
    final today = DateTime.now();
    final lastWorkout = lastWorkoutDate!;
    return today.year == lastWorkout.year &&
           today.month == lastWorkout.month &&
           today.day == lastWorkout.day;
  }

  /// Days since last workout
  int get daysSinceLastWorkout {
    if (lastWorkoutDate == null) return 999;
    return DateTime.now().difference(lastWorkoutDate!).inDays;
  }
}

/// Provider for workout stats (NO MOCK DATA)
final workoutStatsProvider = FutureProvider<WorkoutStats>((ref) async {
  try {
    final db = WorkoutHistoryDB.instance;

    // Fetch all stats in parallel with timeout
    final results = await Future.wait([
      db.getTotalWorkouts(),
      db.getCurrentStreak(),
      db.getLongestStreak(),
      db.getTotalRepsThisWeek(),
      db.getTotalRepsLastWeek(),
      db.getWorkoutsThisWeek(),
      db.getTotalTrainingMinutes(),
      db.getTotalLifetimeReps(),
      db.getAverageFormScore(),
      db.getLastWorkoutDate(),
    ]).timeout(const Duration(seconds: 5));

    return WorkoutStats(
      totalWorkouts: results[0] as int,
      currentStreak: results[1] as int,
      longestStreak: results[2] as int,
      repsThisWeek: results[3] as int,
      repsLastWeek: results[4] as int,
      workoutsThisWeek: results[5] as int,
      totalMinutes: results[6] as int,
      totalLifetimeReps: results[7] as int,
      avgFormScore: results[8] as double,
      lastWorkoutDate: results[9] as DateTime?,
    );
  } catch (e) {
    print('❌ Error loading workout stats: $e');
    // Return empty stats instead of throwing
    return WorkoutStats.empty();
  }
});

/// Provider to refresh stats (call after completing a workout)
final refreshStatsProvider = Provider((ref) {
  return () {
    ref.invalidate(workoutStatsProvider);
  };
});

