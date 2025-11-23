import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_model.dart';
import '../models/workout_session_model.dart';
import '../services/exercise_generator.dart';
import 'user_provider.dart';

final todayExercisesProvider = Provider<List<Exercise>>((ref) {
  final user = ref.watch(userProvider);
  
  if (user == null) {
    return [];
  }
  
  return ExerciseGenerator.getTodayExercises(
    user.goalMode,
    user.equipmentMode,
  );
});

final recentSessionsProvider = StateProvider<List<WorkoutSession>>((ref) {
  // Mock data for now - will be loaded from database
  return [
    WorkoutSession(
      id: '1',
      name: 'Full Body Power',
      date: DateTime.now().subtract(const Duration(days: 2)),
      durationMinutes: 42,
      status: SessionStatus.complete,
      exercises: const [],
    ),
    WorkoutSession(
      id: '2',
      name: 'Upper Body Focus',
      date: DateTime.now().subtract(const Duration(days: 5)),
      durationMinutes: null,
      status: SessionStatus.skipped,
      exercises: const [],
    ),
    WorkoutSession(
      id: '3',
      name: 'Lower Body Strength',
      date: DateTime.now().subtract(const Duration(days: 7)),
      durationMinutes: 38,
      status: SessionStatus.complete,
      exercises: const [],
    ),
  ];
});

final weekScheduleProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'day': 'Monday', 'workout': 'Rest', 'status': null},
    {'day': 'Tuesday', 'workout': 'Lower Body', 'status': 'complete'},
    {'day': 'Wednesday', 'workout': 'Upper Body', 'status': 'today'},
    {'day': 'Thursday', 'workout': 'Movement', 'status': null},
    {'day': 'Friday', 'workout': 'Full Body', 'status': null},
  ];
});

