import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_models.dart';
import '../services/storage_service.dart';

// Provider for the locked workout state
final lockedWorkoutProvider = StateNotifierProvider<LockedWorkoutNotifier, LockedWorkout?>((ref) {
  return LockedWorkoutNotifier();
});

class LockedWorkoutNotifier extends StateNotifier<LockedWorkout?> {
  LockedWorkoutNotifier() : super(null) {
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    final storage = await StorageService.getInstance();
    state = storage.getLockedWorkout();
  }

  Future<void> lockWorkout(WorkoutPreset preset, {List<WorkoutExercise>? customExercises}) async {
    final locked = LockedWorkout.fromPreset(preset, customExercises: customExercises);
    final storage = await StorageService.getInstance();
    await storage.saveLockedWorkout(locked);
    state = locked;
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
}
