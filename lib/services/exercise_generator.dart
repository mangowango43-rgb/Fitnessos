import '../models/exercise_model.dart';
import '../models/goal_config.dart';

class ExerciseGenerator {
  // Bodyweight exercises
  static final List<Exercise> _bodyweightUpperReset = [
    const Exercise(
      id: 'bw1',
      name: 'Incline Push-Ups',
      sets: 3,
      reps: '10–15',
      muscles: 'Chest • Triceps • Core',
      difficulty: ExerciseDifficulty.easy,
    ),
    const Exercise(
      id: 'bw2',
      name: 'Bodyweight Rows (Table/Bar)',
      sets: 3,
      reps: '8–12',
      muscles: 'Back • Biceps',
      difficulty: ExerciseDifficulty.medium,
    ),
    const Exercise(
      id: 'bw3',
      name: 'Pike Push-Ups',
      sets: 3,
      reps: '6–10',
      muscles: 'Shoulders • Triceps',
      difficulty: ExerciseDifficulty.medium,
    ),
    const Exercise(
      id: 'bw4',
      name: 'Deadbug Hold',
      sets: 3,
      reps: '20–30s',
      muscles: 'Core • Hip Flexors',
      difficulty: ExerciseDifficulty.easy,
    ),
  ];

  // Dumbbell exercises
  static final List<Exercise> _dumbbellUpperReset = [
    const Exercise(
      id: 'db1',
      name: 'Dumbbell Bench Press',
      sets: 3,
      reps: '8–12',
      muscles: 'Chest • Triceps',
      difficulty: ExerciseDifficulty.medium,
    ),
    const Exercise(
      id: 'db2',
      name: 'One-Arm Dumbbell Row',
      sets: 3,
      reps: '8–12 / side',
      muscles: 'Back • Biceps',
      difficulty: ExerciseDifficulty.medium,
    ),
    const Exercise(
      id: 'db3',
      name: 'Seated Shoulder Press',
      sets: 3,
      reps: '8–10',
      muscles: 'Shoulders • Triceps',
      difficulty: ExerciseDifficulty.medium,
    ),
    const Exercise(
      id: 'db4',
      name: 'Weighted Deadbug',
      sets: 3,
      reps: '10–12',
      muscles: 'Core • Hip Flexors',
      difficulty: ExerciseDifficulty.medium,
    ),
  ];

  // Gym exercises
  static final List<Exercise> _gymUpperStrength = [
    const Exercise(
      id: 'gm1',
      name: 'Barbell Bench Press',
      sets: 4,
      reps: '4–6',
      muscles: 'Chest • Triceps • Front Delts',
      difficulty: ExerciseDifficulty.hard,
    ),
    const Exercise(
      id: 'gm2',
      name: 'Weighted Pull-Ups or Lat Pulldown',
      sets: 4,
      reps: '6–8',
      muscles: 'Back • Biceps',
      difficulty: ExerciseDifficulty.hard,
    ),
    const Exercise(
      id: 'gm3',
      name: 'Overhead Press',
      sets: 3,
      reps: '5–8',
      muscles: 'Shoulders • Triceps',
      difficulty: ExerciseDifficulty.hard,
    ),
    const Exercise(
      id: 'gm4',
      name: 'Cable Face Pull',
      sets: 3,
      reps: '12–15',
      muscles: 'Rear Delts • Upper Back',
      difficulty: ExerciseDifficulty.easy,
    ),
  ];

  static List<Exercise> getTodayExercises(
    GoalMode goal,
    EquipmentMode equipment,
  ) {
    if (equipment == EquipmentMode.bodyweight) {
      if (goal == GoalMode.cut || goal == GoalMode.recomp) {
        return _bodyweightUpperReset;
      }
      if (goal == GoalMode.athletic) {
        return [
          const Exercise(
            id: 'bwA1',
            name: 'Explosive Push-Ups',
            sets: 4,
            reps: '5–8',
            muscles: 'Chest • Triceps • Nervous System',
            difficulty: ExerciseDifficulty.hard,
          ),
          const Exercise(
            id: 'bwA2',
            name: 'Alternating Reverse Lunge',
            sets: 3,
            reps: '10 / side',
            muscles: 'Glutes • Quads • Balance',
            difficulty: ExerciseDifficulty.medium,
          ),
          _bodyweightUpperReset[3],
        ];
      }
      if (goal == GoalMode.bulk || goal == GoalMode.strength) {
        return [
          const Exercise(
            id: 'bwS1',
            name: 'Feet-Elevated Push-Ups',
            sets: 4,
            reps: '8–12',
            muscles: 'Chest • Shoulders',
            difficulty: ExerciseDifficulty.medium,
          ),
          _bodyweightUpperReset[1],
          _bodyweightUpperReset[2],
        ];
      }
      return _bodyweightUpperReset;
    }

    if (equipment == EquipmentMode.dumbbells) {
      if (goal == GoalMode.cut) {
        return [
          _dumbbellUpperReset[0],
          _dumbbellUpperReset[1],
          const Exercise(
            id: 'dbC1',
            name: 'Dumbbell Lateral Raise',
            sets: 3,
            reps: '12–15',
            muscles: 'Shoulders',
            difficulty: ExerciseDifficulty.easy,
          ),
          _dumbbellUpperReset[3],
        ];
      }
      if (goal == GoalMode.bulk || goal == GoalMode.strength) {
        return [
          _dumbbellUpperReset[0],
          _dumbbellUpperReset[1],
          _dumbbellUpperReset[2],
          const Exercise(
            id: 'dbB1',
            name: 'Hammer Curls',
            sets: 3,
            reps: '8–10',
            muscles: 'Biceps • Forearms',
            difficulty: ExerciseDifficulty.medium,
          ),
        ];
      }
      if (goal == GoalMode.athletic) {
        return [
          const Exercise(
            id: 'dbA1',
            name: 'Push Press',
            sets: 4,
            reps: '4–6',
            muscles: 'Shoulders • Legs • Core',
            difficulty: ExerciseDifficulty.hard,
          ),
          _dumbbellUpperReset[1],
          _dumbbellUpperReset[3],
        ];
      }
      return _dumbbellUpperReset;
    }

    // GYM
    if (goal == GoalMode.strength || goal == GoalMode.bulk) {
      return _gymUpperStrength;
    }
    if (goal == GoalMode.cut) {
      return [
        const Exercise(
          id: 'gmC1',
          name: 'Incline Bench Press',
          sets: 3,
          reps: '8–10',
          muscles: 'Upper Chest • Shoulders',
          difficulty: ExerciseDifficulty.medium,
        ),
        _gymUpperStrength[1],
        _gymUpperStrength[3],
      ];
    }
    if (goal == GoalMode.athletic) {
      return [
        const Exercise(
          id: 'gmA1',
          name: 'Med Ball Chest Pass or Speed Bench',
          sets: 4,
          reps: '3–5',
          muscles: 'Chest • Triceps • Power',
          difficulty: ExerciseDifficulty.hard,
        ),
        _gymUpperStrength[1],
        _gymUpperStrength[3],
      ];
    }
    // RECOMP default
    return [_gymUpperStrength[0], _gymUpperStrength[1], _gymUpperStrength[3]];
  }
}

