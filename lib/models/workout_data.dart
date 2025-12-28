import 'workout_models.dart';

class Exercise {
  final String id;
  final String name;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final String equipment; // 'weights', 'bodyweight', 'none'

  const Exercise({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.equipment,
  });
}

class CircuitExercise {
  final String name;
  final int timeSeconds;
  final int restSeconds;

  const CircuitExercise({
    required this.name,
    required this.timeSeconds,
    required this.restSeconds,
  });
}

class CircuitWorkout {
  final String id;
  final String name;
  final String duration;
  final List<CircuitExercise> exercises;
  final int rounds;
  final String difficulty;

  const CircuitWorkout({
    required this.id,
    required this.name,
    required this.duration,
    required this.exercises,
    required this.rounds,
    required this.difficulty,
  });
}

class TrainingSplitDay {
  final String name;
  final List<String> exercises;

  const TrainingSplitDay({
    required this.name,
    required this.exercises,
  });
}

class TrainingSplit {
  final String id;
  final String name;
  final String icon;
  final List<TrainingSplitDay> days;

  const TrainingSplit({
    required this.id,
    required this.name,
    required this.icon,
    required this.days,
  });
}

class WorkoutCategory {
  final String id;
  final String name;
  final String icon;
  final String description;

  const WorkoutCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}

// Complete Exercise Database
class WorkoutData {
  // Muscle Split Categories
  static const Map<String, List<Exercise>> muscleSplits = {
    'chest': [
      Exercise(id: 'bench_press', name: 'Bench Press', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'incline_press', name: 'Incline Press', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'decline_press', name: 'Decline Press', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'chest_flys', name: 'Chest Flys', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'pushups', name: 'Push-ups', difficulty: 'beginner', equipment: 'bodyweight'),
      Exercise(id: 'dips_chest', name: 'Dips (Chest)', difficulty: 'advanced', equipment: 'bodyweight'),
      Exercise(id: 'cable_crossover', name: 'Cable Crossovers', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'landmine_press', name: 'Landmine Press', difficulty: 'intermediate', equipment: 'weights'),
    ],
    'back': [
      Exercise(id: 'deadlift', name: 'Deadlift', difficulty: 'advanced', equipment: 'weights'),
      Exercise(id: 'bent_rows', name: 'Bent-Over Rows', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'pullups', name: 'Pull-ups', difficulty: 'advanced', equipment: 'bodyweight'),
      Exercise(id: 'lat_pulldown', name: 'Lat Pulldowns', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'cable_rows', name: 'Cable Rows', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'tbar_rows', name: 'T-Bar Rows', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'face_pulls', name: 'Face Pulls', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'reverse_flys', name: 'Reverse Flys', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'shrugs', name: 'Shrugs', difficulty: 'beginner', equipment: 'weights'),
    ],
    'shoulders': [
      Exercise(id: 'overhead_press', name: 'Overhead Press', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'arnold_press', name: 'Arnold Press', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'lateral_raises', name: 'Lateral Raises', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'front_raises', name: 'Front Raises', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'rear_delt_flys', name: 'Rear Delt Flys', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'upright_rows', name: 'Upright Rows', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'pike_pushups', name: 'Pike Push-ups', difficulty: 'intermediate', equipment: 'bodyweight'),
    ],
    'legs': [
      Exercise(id: 'squats', name: 'Squats', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'romanian_deadlift', name: 'Romanian Deadlift', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'lunges', name: 'Lunges', difficulty: 'beginner', equipment: 'bodyweight'),
      Exercise(id: 'bulgarian_split', name: 'Bulgarian Split Squats', difficulty: 'advanced', equipment: 'weights'),
      Exercise(id: 'leg_press', name: 'Leg Press', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'leg_extensions', name: 'Leg Extensions', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'leg_curls', name: 'Leg Curls', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'calf_raises', name: 'Calf Raises', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'step_ups', name: 'Step-ups', difficulty: 'beginner', equipment: 'bodyweight'),
      Exercise(id: 'goblet_squats', name: 'Goblet Squats', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'wall_sits', name: 'Wall Sits', difficulty: 'beginner', equipment: 'bodyweight'),
      Exercise(id: 'jump_squats', name: 'Jump Squats', difficulty: 'intermediate', equipment: 'bodyweight'),
    ],
    'arms': [
      Exercise(id: 'bicep_curls', name: 'Bicep Curls', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'hammer_curls', name: 'Hammer Curls', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'preacher_curls', name: 'Preacher Curls', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'tricep_extensions', name: 'Tricep Extensions', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'skull_crushers', name: 'Skull Crushers', difficulty: 'intermediate', equipment: 'weights'),
      Exercise(id: 'overhead_tricep', name: 'Overhead Tricep Extension', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'close_grip_pushups', name: 'Close-grip Push-ups', difficulty: 'intermediate', equipment: 'bodyweight'),
      Exercise(id: 'concentration_curls', name: 'Concentration Curls', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'cable_curls', name: 'Cable Curls', difficulty: 'beginner', equipment: 'weights'),
      Exercise(id: 'diamond_pushups', name: 'Diamond Push-ups', difficulty: 'advanced', equipment: 'bodyweight'),
    ],
    'core': [
      Exercise(id: 'situps', name: 'Sit-ups', difficulty: 'beginner', equipment: 'bodyweight'),
      Exercise(id: 'crunches', name: 'Crunches', difficulty: 'beginner', equipment: 'bodyweight'),
      Exercise(id: 'planks', name: 'Planks', difficulty: 'beginner', equipment: 'bodyweight'),
      Exercise(id: 'side_planks', name: 'Side Planks', difficulty: 'intermediate', equipment: 'bodyweight'),
      Exercise(id: 'leg_raises', name: 'Leg Raises', difficulty: 'intermediate', equipment: 'bodyweight'),
      Exercise(id: 'russian_twists', name: 'Russian Twists', difficulty: 'beginner', equipment: 'bodyweight'),
      Exercise(id: 'mountain_climbers', name: 'Mountain Climbers', difficulty: 'intermediate', equipment: 'bodyweight'),
      Exercise(id: 'bicycle_crunches', name: 'Bicycle Crunches', difficulty: 'beginner', equipment: 'bodyweight'),
    ],
  };

  // Circuit Workouts
  static const List<CircuitWorkout> circuits = [
    CircuitWorkout(
      id: 'full_body_hiit',
      name: 'FULL BODY HIIT',
      duration: '20 min',
      difficulty: 'intermediate',
      rounds: 3,
      exercises: [
        CircuitExercise(name: 'Burpees', timeSeconds: 45, restSeconds: 15),
        CircuitExercise(name: 'Jump Squats', timeSeconds: 45, restSeconds: 15),
        CircuitExercise(name: 'Push-ups', timeSeconds: 45, restSeconds: 15),
        CircuitExercise(name: 'Mountain Climbers', timeSeconds: 45, restSeconds: 15),
      ],
    ),
    CircuitWorkout(
      id: 'upper_blast',
      name: 'UPPER BODY BLAST',
      duration: '15 min',
      difficulty: 'intermediate',
      rounds: 3,
      exercises: [
        CircuitExercise(name: 'Push-ups', timeSeconds: 40, restSeconds: 20),
        CircuitExercise(name: 'Dips', timeSeconds: 40, restSeconds: 20),
        CircuitExercise(name: 'Pike Push-ups', timeSeconds: 40, restSeconds: 20),
        CircuitExercise(name: 'Diamond Push-ups', timeSeconds: 40, restSeconds: 20),
      ],
    ),
    CircuitWorkout(
      id: 'leg_burner',
      name: 'LEG BURNER',
      duration: '18 min',
      difficulty: 'advanced',
      rounds: 3,
      exercises: [
        CircuitExercise(name: 'Jump Squats', timeSeconds: 50, restSeconds: 10),
        CircuitExercise(name: 'Lunges', timeSeconds: 50, restSeconds: 10),
        CircuitExercise(name: 'Wall Sits', timeSeconds: 50, restSeconds: 10),
        CircuitExercise(name: 'Calf Raises', timeSeconds: 50, restSeconds: 10),
      ],
    ),
    CircuitWorkout(
      id: 'cardio_blast',
      name: 'CARDIO BLAST',
      duration: '25 min',
      difficulty: 'intermediate',
      rounds: 4,
      exercises: [
        CircuitExercise(name: 'Jumping Jacks', timeSeconds: 45, restSeconds: 15),
        CircuitExercise(name: 'High Knees', timeSeconds: 45, restSeconds: 15),
        CircuitExercise(name: 'Butt Kicks', timeSeconds: 45, restSeconds: 15),
        CircuitExercise(name: 'Burpees', timeSeconds: 45, restSeconds: 15),
      ],
    ),
    CircuitWorkout(
      id: 'core_destroyer',
      name: 'CORE DESTROYER',
      duration: '12 min',
      difficulty: 'beginner',
      rounds: 3,
      exercises: [
        CircuitExercise(name: 'Planks', timeSeconds: 45, restSeconds: 15),
        CircuitExercise(name: 'Russian Twists', timeSeconds: 45, restSeconds: 15),
        CircuitExercise(name: 'Leg Raises', timeSeconds: 45, restSeconds: 15),
        CircuitExercise(name: 'Bicycle Crunches', timeSeconds: 45, restSeconds: 15),
        CircuitExercise(name: 'Mountain Climbers', timeSeconds: 45, restSeconds: 15),
      ],
    ),
    CircuitWorkout(
      id: 'arms_arsenal',
      name: 'ARMS ARSENAL',
      duration: '15 min',
      difficulty: 'intermediate',
      rounds: 3,
      exercises: [
        CircuitExercise(name: 'Diamond Push-ups', timeSeconds: 40, restSeconds: 20),
        CircuitExercise(name: 'Close-grip Push-ups', timeSeconds: 40, restSeconds: 20),
        CircuitExercise(name: 'Tricep Dips', timeSeconds: 40, restSeconds: 20),
        CircuitExercise(name: 'Push-ups', timeSeconds: 40, restSeconds: 20),
        CircuitExercise(name: 'Pike Push-ups', timeSeconds: 40, restSeconds: 20),
        CircuitExercise(name: 'Plank to Push-up', timeSeconds: 40, restSeconds: 20),
      ],
    ),
    CircuitWorkout(
      id: 'endurance_builder',
      name: 'ENDURANCE BUILDER',
      duration: '30 min',
      difficulty: 'advanced',
      rounds: 4,
      exercises: [
        CircuitExercise(name: 'Burpees', timeSeconds: 50, restSeconds: 10),
        CircuitExercise(name: 'Jump Squats', timeSeconds: 50, restSeconds: 10),
        CircuitExercise(name: 'Mountain Climbers', timeSeconds: 50, restSeconds: 10),
        CircuitExercise(name: 'High Knees', timeSeconds: 50, restSeconds: 10),
        CircuitExercise(name: 'Bear Crawls', timeSeconds: 50, restSeconds: 10),
      ],
    ),
  ];

  // Training Splits
  static const List<TrainingSplit> trainingSplits = [
    TrainingSplit(
      id: 'ppl',
      name: 'PUSH/PULL/LEGS',
      icon: '🔄',
      days: [
        TrainingSplitDay(
          name: 'PUSH DAY',
          exercises: ['Bench Press', 'Overhead Press', 'Tricep Extensions', 'Lateral Raises', 'Dips'],
        ),
        TrainingSplitDay(
          name: 'PULL DAY',
          exercises: ['Deadlift', 'Pull-ups', 'Bent Rows', 'Face Pulls', 'Bicep Curls'],
        ),
        TrainingSplitDay(
          name: 'LEG DAY',
          exercises: ['Squats', 'Romanian Deadlift', 'Leg Press', 'Leg Curls', 'Calf Raises'],
        ),
      ],
    ),
    TrainingSplit(
      id: 'upper_lower',
      name: 'UPPER/LOWER',
      icon: '⬆️⬇️',
      days: [
        TrainingSplitDay(
          name: 'UPPER BODY',
          exercises: ['Bench Press', 'Bent Rows', 'Overhead Press', 'Pull-ups', 'Dips'],
        ),
        TrainingSplitDay(
          name: 'LOWER BODY',
          exercises: ['Squats', 'Romanian Deadlift', 'Lunges', 'Leg Curls', 'Calf Raises'],
        ),
      ],
    ),
    TrainingSplit(
      id: 'full_body',
      name: 'FULL BODY',
      icon: '💯',
      days: [
        TrainingSplitDay(
          name: 'FULL BODY A',
          exercises: ['Squats', 'Bench Press', 'Bent Rows', 'Overhead Press', 'Planks'],
        ),
        TrainingSplitDay(
          name: 'FULL BODY B',
          exercises: ['Deadlift', 'Pull-ups', 'Dips', 'Lunges', 'Russian Twists'],
        ),
      ],
    ),
  ];

  // At Home Exercises
  static const List<Exercise> atHomeExercises = [
    Exercise(id: 'pushups', name: 'Push-ups', difficulty: 'beginner', equipment: 'bodyweight'),
    Exercise(id: 'pullups', name: 'Pull-ups', difficulty: 'advanced', equipment: 'bodyweight'),
    Exercise(id: 'dips_chest', name: 'Dips', difficulty: 'advanced', equipment: 'bodyweight'),
    Exercise(id: 'lunges', name: 'Lunges', difficulty: 'beginner', equipment: 'bodyweight'),
    Exercise(id: 'squats_bw', name: 'Bodyweight Squats', difficulty: 'beginner', equipment: 'bodyweight'),
    Exercise(id: 'planks', name: 'Planks', difficulty: 'beginner', equipment: 'bodyweight'),
    Exercise(id: 'mountain_climbers', name: 'Mountain Climbers', difficulty: 'intermediate', equipment: 'bodyweight'),
    Exercise(id: 'burpees', name: 'Burpees', difficulty: 'intermediate', equipment: 'bodyweight'),
    Exercise(id: 'pike_pushups', name: 'Pike Push-ups', difficulty: 'intermediate', equipment: 'bodyweight'),
    Exercise(id: 'wall_sits', name: 'Wall Sits', difficulty: 'beginner', equipment: 'bodyweight'),
  ];

  // Cardio Only Exercises
  static const List<Exercise> cardioExercises = [
    Exercise(id: 'burpees', name: 'Burpees', difficulty: 'intermediate', equipment: 'none'),
    Exercise(id: 'jumping_jacks', name: 'Jumping Jacks', difficulty: 'beginner', equipment: 'none'),
    Exercise(id: 'high_knees', name: 'High Knees', difficulty: 'beginner', equipment: 'none'),
    Exercise(id: 'butt_kicks', name: 'Butt Kicks', difficulty: 'beginner', equipment: 'none'),
    Exercise(id: 'box_jumps', name: 'Box Jumps', difficulty: 'advanced', equipment: 'none'),
    Exercise(id: 'jump_rope', name: 'Jump Rope', difficulty: 'intermediate', equipment: 'none'),
    Exercise(id: 'bear_crawls', name: 'Bear Crawls', difficulty: 'intermediate', equipment: 'none'),
    Exercise(id: 'sprawls', name: 'Sprawls', difficulty: 'advanced', equipment: 'none'),
    Exercise(id: 'skaters', name: 'Skaters', difficulty: 'intermediate', equipment: 'none'),
    Exercise(id: 'tuck_jumps', name: 'Tuck Jumps', difficulty: 'advanced', equipment: 'none'),
    Exercise(id: 'star_jumps', name: 'Star Jumps', difficulty: 'beginner', equipment: 'none'),
    Exercise(id: 'lateral_hops', name: 'Lateral Hops', difficulty: 'intermediate', equipment: 'none'),
  ];

  // Main Categories
  static const List<WorkoutCategory> categories = [
    WorkoutCategory(
      id: 'splits',
      name: 'MUSCLE SPLITS',
      icon: '💪',
      description: 'Target specific muscle groups',
    ),
    WorkoutCategory(
      id: 'circuits',
      name: 'CIRCUITS',
      icon: '⚡',
      description: 'High-intensity timed workouts',
    ),
    WorkoutCategory(
      id: 'training_splits',
      name: 'TRAINING SPLITS',
      icon: '🏋️',
      description: 'Classic workout splits',
    ),
    WorkoutCategory(
      id: 'at_home',
      name: 'AT HOME',
      icon: '🏠',
      description: 'No equipment needed',
    ),
    WorkoutCategory(
      id: 'cardio',
      name: 'CARDIO ONLY',
      icon: '🏃',
      description: 'Pure cardio exercises',
    ),
  ];

  static const Map<String, String> muscleSplitInfo = {
    'chest': 'CHEST 🦾',
    'back': 'BACK 🔙',
    'shoulders': 'SHOULDERS 💪',
    'legs': 'LEGS 🦵',
    'arms': 'ARMS 💪',
    'core': 'CORE 🎯',
  };

  // ==================== WORKOUT PRESETS ====================
  
  // GYM MODE - MUSCLE SPLITS (Individual body parts with default 4 exercises selected)
  static final List<WorkoutPreset> gymMuscleSplits = [
    WorkoutPreset(
      id: 'gym_chest',
      name: 'CHEST',
      category: 'gym',
      subcategory: 'muscle_splits',
      icon: '🦾',
      isCircuit: false,
      exercises: [
        WorkoutExercise(id: 'barbell_bench_press', name: 'Barbell Bench Press', sets: 4, reps: 8),
        WorkoutExercise(id: 'incline_db_press', name: 'Incline Dumbbell Press', sets: 3, reps: 10),
        WorkoutExercise(id: 'decline_bench_press', name: 'Decline Bench Press', sets: 3, reps: 10),
        WorkoutExercise(id: 'cable_crossover', name: 'Cable Crossover', sets: 3, reps: 12),
        WorkoutExercise(id: 'machine_chest_fly', name: 'Machine Chest Fly', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'dumbbell_flyes', name: 'Dumbbell Flyes', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'pushups', name: 'Push-Ups', sets: 3, reps: 15, included: false),
        WorkoutExercise(id: 'chest_dips', name: 'Chest Dips', sets: 3, reps: 10, included: false),
      ],
    ),
    WorkoutPreset(
      id: 'gym_back',
      name: 'BACK',
      category: 'gym',
      subcategory: 'muscle_splits',
      icon: '🔙',
      isCircuit: false,
      exercises: [
        WorkoutExercise(id: 'deadlift', name: 'Deadlift', sets: 4, reps: 5),
        WorkoutExercise(id: 'barbell_row', name: 'Barbell Row', sets: 4, reps: 8),
        WorkoutExercise(id: 'lat_pulldown', name: 'Lat Pulldown', sets: 3, reps: 10),
        WorkoutExercise(id: 'seated_cable_row', name: 'Seated Cable Row', sets: 3, reps: 10),
        WorkoutExercise(id: 'tbar_row', name: 'T-Bar Row', sets: 3, reps: 10, included: false),
        WorkoutExercise(id: 'single_arm_db_row', name: 'Single Arm Dumbbell Row', sets: 3, reps: 10, included: false),
        WorkoutExercise(id: 'face_pulls', name: 'Face Pulls', sets: 3, reps: 15, included: false),
        WorkoutExercise(id: 'pullups', name: 'Pull-Ups', sets: 3, reps: 8, included: false),
      ],
    ),
    WorkoutPreset(
      id: 'gym_shoulders',
      name: 'SHOULDERS',
      category: 'gym',
      subcategory: 'muscle_splits',
      icon: '💪',
      isCircuit: false,
      exercises: [
        WorkoutExercise(id: 'overhead_press', name: 'Overhead Press', sets: 4, reps: 8),
        WorkoutExercise(id: 'seated_db_press', name: 'Seated Dumbbell Press', sets: 3, reps: 10),
        WorkoutExercise(id: 'arnold_press', name: 'Arnold Press', sets: 3, reps: 10),
        WorkoutExercise(id: 'lateral_raise', name: 'Lateral Raise', sets: 3, reps: 12),
        WorkoutExercise(id: 'front_raise', name: 'Front Raise', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'reverse_fly', name: 'Reverse Fly', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'cable_lateral_raise', name: 'Cable Lateral Raise', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'barbell_shrugs', name: 'Barbell Shrugs', sets: 3, reps: 12, included: false),
      ],
    ),
    WorkoutPreset(
      id: 'gym_legs',
      name: 'LEGS',
      category: 'gym',
      subcategory: 'muscle_splits',
      icon: '🦵',
      isCircuit: false,
      exercises: [
        WorkoutExercise(id: 'back_squat', name: 'Back Squat', sets: 4, reps: 8),
        WorkoutExercise(id: 'front_squat', name: 'Front Squat', sets: 4, reps: 6),
        WorkoutExercise(id: 'romanian_deadlift', name: 'Romanian Deadlift', sets: 3, reps: 10),
        WorkoutExercise(id: 'leg_press', name: 'Leg Press', sets: 3, reps: 12),
        WorkoutExercise(id: 'bulgarian_split_squat', name: 'Bulgarian Split Squat', sets: 3, reps: 10, included: false),
        WorkoutExercise(id: 'leg_extension', name: 'Leg Extension', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'leg_curl', name: 'Leg Curl', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'hip_thrust', name: 'Hip Thrust (GLUTE FOCUS 🍑)', sets: 4, reps: 10, included: false),
        WorkoutExercise(id: 'glute_kickback', name: 'Glute Kickback Machine (GLUTE FOCUS 🍑)', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'standing_calf_raise', name: 'Standing Calf Raise', sets: 4, reps: 15, included: false),
      ],
    ),
    WorkoutPreset(
      id: 'gym_arms',
      name: 'ARMS',
      category: 'gym',
      subcategory: 'muscle_splits',
      icon: '💪',
      isCircuit: false,
      exercises: [
        WorkoutExercise(id: 'barbell_curl', name: 'Barbell Curl', sets: 3, reps: 10),
        WorkoutExercise(id: 'hammer_curl', name: 'Hammer Curl', sets: 3, reps: 10),
        WorkoutExercise(id: 'preacher_curl', name: 'Preacher Curl', sets: 3, reps: 10),
        WorkoutExercise(id: 'skull_crushers', name: 'Skull Crushers', sets: 3, reps: 10),
        WorkoutExercise(id: 'concentration_curl', name: 'Concentration Curl', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'tricep_pushdown', name: 'Tricep Pushdown', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'overhead_tricep_ext', name: 'Overhead Tricep Extension', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'close_grip_bench', name: 'Close Grip Bench Press', sets: 3, reps: 10, included: false),
        WorkoutExercise(id: 'cable_curl', name: 'Cable Curl', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'tricep_dips', name: 'Tricep Dips', sets: 3, reps: 10, included: false),
      ],
    ),
    WorkoutPreset(
      id: 'gym_core',
      name: 'CORE',
      category: 'gym',
      subcategory: 'muscle_splits',
      icon: '🎯',
      isCircuit: false,
      exercises: [
        WorkoutExercise(id: 'cable_crunch', name: 'Cable Crunch', sets: 3, reps: 15),
        WorkoutExercise(id: 'hanging_leg_raise', name: 'Hanging Leg Raise', sets: 3, reps: 12),
        WorkoutExercise(id: 'ab_wheel_rollout', name: 'Ab Wheel Rollout', sets: 3, reps: 10),
        WorkoutExercise(id: 'russian_twist', name: 'Russian Twist (weighted)', sets: 3, reps: 20),
        WorkoutExercise(id: 'woodchoppers', name: 'Woodchoppers', sets: 3, reps: 12, included: false),
        WorkoutExercise(id: 'decline_situp', name: 'Decline Sit-Up', sets: 3, reps: 15, included: false),
        WorkoutExercise(id: 'plank', name: 'Plank', sets: 3, reps: 45, included: false),
        WorkoutExercise(id: 'side_plank', name: 'Side Plank', sets: 3, reps: 30, included: false),
      ],
    ),
  ];

  // GYM MODE - MUSCLE GROUPINGS (Pre-built combinations)
  static final List<WorkoutPreset> gymMuscleGroupings = [
    WorkoutPreset(
      id: 'gym_upper_body',
      name: 'UPPER BODY',
      category: 'gym',
      subcategory: 'muscle_groupings',
      icon: '💪',
      isCircuit: false,
      duration: '~45 min',
      exercises: [
        WorkoutExercise(id: 'barbell_bench_press', name: 'Barbell Bench Press', sets: 4, reps: 8),
        WorkoutExercise(id: 'barbell_row', name: 'Barbell Row', sets: 4, reps: 8),
        WorkoutExercise(id: 'overhead_press', name: 'Overhead Press', sets: 3, reps: 10),
        WorkoutExercise(id: 'lat_pulldown', name: 'Lat Pulldown', sets: 3, reps: 10),
        WorkoutExercise(id: 'lateral_raise', name: 'Lateral Raise', sets: 3, reps: 12),
        WorkoutExercise(id: 'barbell_curl', name: 'Barbell Curl', sets: 3, reps: 10),
        WorkoutExercise(id: 'tricep_pushdown', name: 'Tricep Pushdown', sets: 3, reps: 12),
      ],
    ),
    WorkoutPreset(
      id: 'gym_lower_body',
      name: 'LOWER BODY',
      category: 'gym',
      subcategory: 'muscle_groupings',
      icon: '🦵',
      isCircuit: false,
      duration: '~50 min',
      exercises: [
        WorkoutExercise(id: 'back_squat', name: 'Back Squat', sets: 4, reps: 8),
        WorkoutExercise(id: 'romanian_deadlift', name: 'Romanian Deadlift', sets: 3, reps: 10),
        WorkoutExercise(id: 'leg_press', name: 'Leg Press', sets: 3, reps: 12),
        WorkoutExercise(id: 'hip_thrust', name: 'Hip Thrust', sets: 4, reps: 10),
        WorkoutExercise(id: 'leg_extension', name: 'Leg Extension', sets: 3, reps: 12),
        WorkoutExercise(id: 'leg_curl', name: 'Leg Curl', sets: 3, reps: 12),
        WorkoutExercise(id: 'standing_calf_raise', name: 'Standing Calf Raise', sets: 4, reps: 15),
      ],
    ),
    WorkoutPreset(
      id: 'gym_push_day',
      name: 'PUSH DAY',
      category: 'gym',
      subcategory: 'muscle_groupings',
      icon: '⬆️',
      isCircuit: false,
      duration: '~40 min',
      exercises: [
        WorkoutExercise(id: 'barbell_bench_press', name: 'Barbell Bench Press', sets: 4, reps: 8),
        WorkoutExercise(id: 'incline_db_press', name: 'Incline Dumbbell Press', sets: 3, reps: 10),
        WorkoutExercise(id: 'overhead_press', name: 'Overhead Press', sets: 3, reps: 10),
        WorkoutExercise(id: 'lateral_raise', name: 'Lateral Raise', sets: 3, reps: 12),
        WorkoutExercise(id: 'tricep_pushdown', name: 'Tricep Pushdown', sets: 3, reps: 12),
        WorkoutExercise(id: 'overhead_tricep_ext', name: 'Overhead Tricep Extension', sets: 3, reps: 12),
      ],
    ),
    WorkoutPreset(
      id: 'gym_pull_day',
      name: 'PULL DAY',
      category: 'gym',
      subcategory: 'muscle_groupings',
      icon: '⬇️',
      isCircuit: false,
      duration: '~45 min',
      exercises: [
        WorkoutExercise(id: 'deadlift', name: 'Deadlift', sets: 4, reps: 5),
        WorkoutExercise(id: 'barbell_row', name: 'Barbell Row', sets: 4, reps: 8),
        WorkoutExercise(id: 'lat_pulldown', name: 'Lat Pulldown', sets: 3, reps: 10),
        WorkoutExercise(id: 'seated_cable_row', name: 'Seated Cable Row', sets: 3, reps: 10),
        WorkoutExercise(id: 'face_pulls', name: 'Face Pulls', sets: 3, reps: 15),
        WorkoutExercise(id: 'barbell_curl', name: 'Barbell Curl', sets: 3, reps: 10),
        WorkoutExercise(id: 'hammer_curl', name: 'Hammer Curl', sets: 3, reps: 10),
      ],
    ),
    WorkoutPreset(
      id: 'gym_full_body',
      name: 'FULL BODY',
      category: 'gym',
      subcategory: 'muscle_groupings',
      icon: '💯',
      isCircuit: false,
      duration: '~50 min',
      exercises: [
        WorkoutExercise(id: 'back_squat', name: 'Back Squat', sets: 4, reps: 8),
        WorkoutExercise(id: 'barbell_bench_press', name: 'Barbell Bench Press', sets: 4, reps: 8),
        WorkoutExercise(id: 'barbell_row', name: 'Barbell Row', sets: 4, reps: 8),
        WorkoutExercise(id: 'overhead_press', name: 'Overhead Press', sets: 3, reps: 10),
        WorkoutExercise(id: 'romanian_deadlift', name: 'Romanian Deadlift', sets: 3, reps: 10),
        WorkoutExercise(id: 'barbell_curl', name: 'Barbell Curl', sets: 2, reps: 12),
        WorkoutExercise(id: 'tricep_pushdown', name: 'Tricep Pushdown', sets: 2, reps: 12),
      ],
    ),
    WorkoutPreset(
      id: 'gym_glutes_legs',
      name: 'GLUTES & LEGS 🍑',
      category: 'gym',
      subcategory: 'muscle_groupings',
      icon: '🍑',
      isCircuit: false,
      duration: '~50 min',
      exercises: [
        WorkoutExercise(id: 'hip_thrust', name: 'Hip Thrust', sets: 4, reps: 10),
        WorkoutExercise(id: 'romanian_deadlift', name: 'Romanian Deadlift', sets: 4, reps: 10),
        WorkoutExercise(id: 'bulgarian_split_squat', name: 'Bulgarian Split Squat', sets: 3, reps: 10),
        WorkoutExercise(id: 'glute_kickback', name: 'Glute Kickback Machine', sets: 3, reps: 12),
        WorkoutExercise(id: 'sumo_squat', name: 'Sumo Squat', sets: 3, reps: 12),
        WorkoutExercise(id: 'cable_pullthrough', name: 'Cable Pull-Through', sets: 3, reps: 12),
        WorkoutExercise(id: 'leg_curl', name: 'Leg Curl', sets: 3, reps: 12),
      ],
    ),
  ];

  // GYM MODE - GYM CIRCUITS
  static final List<WorkoutPreset> gymCircuits = [
    WorkoutPreset(
      id: 'gym_full_body_blast',
      name: 'FULL BODY BLAST',
      category: 'gym',
      subcategory: 'gym_circuits',
      icon: '⚡',
      isCircuit: true,
      rounds: 4,
      duration: '~20 min',
      exercises: [
        WorkoutExercise(id: 'barbell_squat_press', name: 'Barbell Squat to Press', sets: 1, reps: 1, timeSeconds: 45, restSeconds: 15),
        WorkoutExercise(id: 'renegade_rows', name: 'Renegade Rows', sets: 1, reps: 1, timeSeconds: 45, restSeconds: 15),
        WorkoutExercise(id: 'box_jumps', name: 'Box Jumps', sets: 1, reps: 1, timeSeconds: 45, restSeconds: 15),
        WorkoutExercise(id: 'battle_ropes', name: 'Battle Ropes', sets: 1, reps: 1, timeSeconds: 45, restSeconds: 15),
        WorkoutExercise(id: 'burpees', name: 'Burpees', sets: 1, reps: 1, timeSeconds: 45, restSeconds: 15),
      ],
    ),
    WorkoutPreset(
      id: 'gym_upper_burner',
      name: 'UPPER BODY BURNER',
      category: 'gym',
      subcategory: 'gym_circuits',
      icon: '🔥',
      isCircuit: true,
      rounds: 4,
      duration: '~16 min',
      exercises: [
        WorkoutExercise(id: 'pushups', name: 'Push-Ups', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'dumbbell_row', name: 'Dumbbell Row', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'shoulder_press', name: 'Shoulder Press', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'bicep_curls', name: 'Bicep Curls', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'tricep_dips', name: 'Tricep Dips', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
      ],
    ),
    WorkoutPreset(
      id: 'gym_lower_torch',
      name: 'LOWER BODY TORCH',
      category: 'gym',
      subcategory: 'gym_circuits',
      icon: '🔥',
      isCircuit: true,
      rounds: 4,
      duration: '~16 min',
      exercises: [
        WorkoutExercise(id: 'goblet_squats', name: 'Goblet Squats', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'walking_lunges', name: 'Walking Lunges', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'romanian_deadlift', name: 'Romanian Deadlift', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'box_stepups', name: 'Box Step-Ups', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'kettlebell_swings', name: 'Kettlebell Swings', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
      ],
    ),
    WorkoutPreset(
      id: 'gym_core_destroyer',
      name: 'CORE DESTROYER',
      category: 'gym',
      subcategory: 'gym_circuits',
      icon: '💥',
      isCircuit: true,
      rounds: 3,
      duration: '~10 min',
      exercises: [
        WorkoutExercise(id: 'cable_crunch', name: 'Cable Crunch', sets: 1, reps: 1, timeSeconds: 30, restSeconds: 10),
        WorkoutExercise(id: 'hanging_leg_raise', name: 'Hanging Leg Raise', sets: 1, reps: 1, timeSeconds: 30, restSeconds: 10),
        WorkoutExercise(id: 'russian_twist', name: 'Russian Twist', sets: 1, reps: 1, timeSeconds: 30, restSeconds: 10),
        WorkoutExercise(id: 'mountain_climbers', name: 'Mountain Climbers', sets: 1, reps: 1, timeSeconds: 30, restSeconds: 10),
        WorkoutExercise(id: 'plank_hold', name: 'Plank Hold', sets: 1, reps: 1, timeSeconds: 30, restSeconds: 10),
      ],
    ),
  ];

  // GYM MODE - BOOTY BUILDER
  static final List<WorkoutPreset> gymBootyBuilder = [
    WorkoutPreset(
      id: 'gym_glute_sculpt',
      name: 'GLUTE SCULPT',
      category: 'gym',
      subcategory: 'booty_builder',
      icon: '🍑',
      isCircuit: false,
      duration: '~45 min',
      exercises: [
        WorkoutExercise(id: 'hip_thrust', name: 'Hip Thrust', sets: 4, reps: 12),
        WorkoutExercise(id: 'romanian_deadlift', name: 'Romanian Deadlift', sets: 3, reps: 12),
        WorkoutExercise(id: 'cable_kickback', name: 'Cable Kickback', sets: 3, reps: 15),
        WorkoutExercise(id: 'sumo_squat', name: 'Sumo Squat', sets: 3, reps: 12),
        WorkoutExercise(id: 'glute_bridge_single', name: 'Glute Bridge (single leg)', sets: 3, reps: 10),
        WorkoutExercise(id: 'cable_pullthrough', name: 'Cable Pull-Through', sets: 3, reps: 15),
      ],
    ),
    WorkoutPreset(
      id: 'gym_peach_pump',
      name: 'PEACH PUMP',
      category: 'gym',
      subcategory: 'booty_builder',
      icon: '🍑',
      isCircuit: false,
      duration: '~40 min',
      exercises: [
        WorkoutExercise(id: 'barbell_hip_thrust', name: 'Barbell Hip Thrust', sets: 4, reps: 10),
        WorkoutExercise(id: 'bulgarian_split_squat', name: 'Bulgarian Split Squat', sets: 3, reps: 10),
        WorkoutExercise(id: 'sumo_deadlift', name: 'Sumo Deadlift', sets: 3, reps: 12),
        WorkoutExercise(id: 'leg_press_high', name: 'Leg Press (feet high)', sets: 3, reps: 12),
        WorkoutExercise(id: 'donkey_kicks_cable', name: 'Donkey Kicks (cable)', sets: 3, reps: 15),
      ],
    ),
  ];

  // HOME MODE - BODYWEIGHT BASICS
  static final List<WorkoutPreset> homeBodyweightBasics = [
    WorkoutPreset(
      id: 'home_full_body',
      name: 'FULL BODY',
      category: 'home',
      subcategory: 'bodyweight_basics',
      icon: '💪',
      isCircuit: false,
      duration: '~30 min',
      exercises: [
        WorkoutExercise(id: 'pushups', name: 'Push-Ups', sets: 3, reps: 15),
        WorkoutExercise(id: 'air_squats', name: 'Air Squats', sets: 3, reps: 20),
        WorkoutExercise(id: 'lunges', name: 'Lunges', sets: 3, reps: 12),
        WorkoutExercise(id: 'superman_raises', name: 'Superman Raises', sets: 3, reps: 15),
        WorkoutExercise(id: 'glute_bridge', name: 'Glute Bridge', sets: 3, reps: 15),
        WorkoutExercise(id: 'plank', name: 'Plank', sets: 3, reps: 45),
        WorkoutExercise(id: 'mountain_climbers', name: 'Mountain Climbers', sets: 3, reps: 20),
      ],
    ),
    WorkoutPreset(
      id: 'home_upper_body',
      name: 'UPPER BODY',
      category: 'home',
      subcategory: 'bodyweight_basics',
      icon: '🦾',
      isCircuit: false,
      duration: '~25 min',
      exercises: [
        WorkoutExercise(id: 'pushups', name: 'Push-Ups', sets: 4, reps: 15),
        WorkoutExercise(id: 'diamond_pushups', name: 'Diamond Push-Ups', sets: 3, reps: 12),
        WorkoutExercise(id: 'wide_pushups', name: 'Wide Push-Ups', sets: 3, reps: 12),
        WorkoutExercise(id: 'pike_pushups', name: 'Pike Push-Ups', sets: 3, reps: 10),
        WorkoutExercise(id: 'tricep_dips_chair', name: 'Tricep Dips (chair)', sets: 3, reps: 12),
        WorkoutExercise(id: 'plank_shoulder_taps', name: 'Plank Shoulder Taps', sets: 3, reps: 20),
      ],
    ),
    WorkoutPreset(
      id: 'home_lower_body',
      name: 'LOWER BODY',
      category: 'home',
      subcategory: 'bodyweight_basics',
      icon: '🦵',
      isCircuit: false,
      duration: '~30 min',
      exercises: [
        WorkoutExercise(id: 'air_squats', name: 'Air Squats', sets: 4, reps: 20),
        WorkoutExercise(id: 'lunges', name: 'Lunges', sets: 3, reps: 12),
        WorkoutExercise(id: 'glute_bridge', name: 'Glute Bridge', sets: 4, reps: 15),
        WorkoutExercise(id: 'single_leg_glute_bridge', name: 'Single Leg Glute Bridge', sets: 3, reps: 10),
        WorkoutExercise(id: 'stepups_chair', name: 'Step-Ups (chair)', sets: 3, reps: 12),
        WorkoutExercise(id: 'wall_sit', name: 'Wall Sit', sets: 3, reps: 45),
        WorkoutExercise(id: 'calf_raises', name: 'Calf Raises', sets: 3, reps: 20),
      ],
    ),
    WorkoutPreset(
      id: 'home_core',
      name: 'CORE',
      category: 'home',
      subcategory: 'bodyweight_basics',
      icon: '🎯',
      isCircuit: false,
      duration: '~20 min',
      exercises: [
        WorkoutExercise(id: 'plank', name: 'Plank', sets: 3, reps: 45),
        WorkoutExercise(id: 'side_plank', name: 'Side Plank', sets: 3, reps: 30),
        WorkoutExercise(id: 'bicycle_crunches', name: 'Bicycle Crunches', sets: 3, reps: 20),
        WorkoutExercise(id: 'leg_raises', name: 'Leg Raises', sets: 3, reps: 15),
        WorkoutExercise(id: 'russian_twist', name: 'Russian Twist', sets: 3, reps: 20),
        WorkoutExercise(id: 'mountain_climbers', name: 'Mountain Climbers', sets: 3, reps: 20),
        WorkoutExercise(id: 'dead_bug', name: 'Dead Bug', sets: 3, reps: 12),
      ],
    ),
  ];

  // HOME MODE - HIIT CIRCUITS
  static final List<WorkoutPreset> homeHIITCircuits = [
    WorkoutPreset(
      id: 'home_10min_quick_burn',
      name: '10 MIN QUICK BURN',
      category: 'home',
      subcategory: 'hiit_circuits',
      icon: '⚡',
      isCircuit: true,
      rounds: 2,
      duration: '10 min',
      exercises: [
        WorkoutExercise(id: 'burpees', name: 'Burpees', sets: 1, reps: 1, timeSeconds: 30, restSeconds: 10),
        WorkoutExercise(id: 'jump_squats', name: 'Jump Squats', sets: 1, reps: 1, timeSeconds: 30, restSeconds: 10),
        WorkoutExercise(id: 'pushups', name: 'Push-Ups', sets: 1, reps: 1, timeSeconds: 30, restSeconds: 10),
        WorkoutExercise(id: 'high_knees', name: 'High Knees', sets: 1, reps: 1, timeSeconds: 30, restSeconds: 10),
        WorkoutExercise(id: 'mountain_climbers', name: 'Mountain Climbers', sets: 1, reps: 1, timeSeconds: 30, restSeconds: 10),
      ],
    ),
    WorkoutPreset(
      id: 'home_20min_destroyer',
      name: '20 MIN DESTROYER',
      category: 'home',
      subcategory: 'hiit_circuits',
      icon: '💥',
      isCircuit: true,
      rounds: 4,
      duration: '20 min',
      exercises: [
        WorkoutExercise(id: 'burpees', name: 'Burpees', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'jump_lunges', name: 'Jump Lunges', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'pushups', name: 'Push-Ups', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'squat_jumps', name: 'Squat Jumps', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
        WorkoutExercise(id: 'plank_jacks', name: 'Plank Jacks', sets: 1, reps: 1, timeSeconds: 40, restSeconds: 20),
      ],
    ),
    WorkoutPreset(
      id: 'home_tabata_torture',
      name: 'TABATA TORTURE',
      category: 'home',
      subcategory: 'hiit_circuits',
      icon: '🔥',
      isCircuit: true,
      rounds: 8,
      duration: '16 min',
      exercises: [
        WorkoutExercise(id: 'burpees', name: 'Burpees', sets: 1, reps: 1, timeSeconds: 20, restSeconds: 10),
        WorkoutExercise(id: 'mountain_climbers', name: 'Mountain Climbers', sets: 1, reps: 1, timeSeconds: 20, restSeconds: 10),
        WorkoutExercise(id: 'jump_squats', name: 'Jump Squats', sets: 1, reps: 1, timeSeconds: 20, restSeconds: 10),
        WorkoutExercise(id: 'pushups', name: 'Push-Ups', sets: 1, reps: 1, timeSeconds: 20, restSeconds: 10),
      ],
    ),
    WorkoutPreset(
      id: 'home_cardio_blast',
      name: 'CARDIO BLAST',
      category: 'home',
      subcategory: 'hiit_circuits',
      icon: '🏃',
      isCircuit: true,
      rounds: 3,
      duration: '15 min',
      exercises: [
        WorkoutExercise(id: 'jumping_jacks', name: 'Jumping Jacks', sets: 1, reps: 1, timeSeconds: 45, restSeconds: 15),
        WorkoutExercise(id: 'high_knees', name: 'High Knees', sets: 1, reps: 1, timeSeconds: 45, restSeconds: 15),
        WorkoutExercise(id: 'butt_kicks', name: 'Butt Kicks', sets: 1, reps: 1, timeSeconds: 45, restSeconds: 15),
        WorkoutExercise(id: 'skaters', name: 'Skaters', sets: 1, reps: 1, timeSeconds: 45, restSeconds: 15),
        WorkoutExercise(id: 'burpees', name: 'Burpees', sets: 1, reps: 1, timeSeconds: 45, restSeconds: 15),
      ],
    ),
  ];

  // HOME MODE - HOME BOOTY
  static final List<WorkoutPreset> homeBooty = [
    WorkoutPreset(
      id: 'home_glute_activation',
      name: 'GLUTE ACTIVATION',
      category: 'home',
      subcategory: 'home_booty',
      icon: '🍑',
      isCircuit: false,
      duration: '~25 min',
      exercises: [
        WorkoutExercise(id: 'glute_bridge', name: 'Glute Bridge', sets: 3, reps: 20),
        WorkoutExercise(id: 'single_leg_glute_bridge', name: 'Single Leg Glute Bridge', sets: 3, reps: 12),
        WorkoutExercise(id: 'donkey_kicks', name: 'Donkey Kicks', sets: 3, reps: 15),
        WorkoutExercise(id: 'fire_hydrants', name: 'Fire Hydrants', sets: 3, reps: 15),
        WorkoutExercise(id: 'clamshells', name: 'Clamshells', sets: 3, reps: 15),
        WorkoutExercise(id: 'frog_pumps', name: 'Frog Pumps', sets: 3, reps: 20),
      ],
    ),
    WorkoutPreset(
      id: 'home_booty_burner',
      name: 'BOOTY BURNER',
      category: 'home',
      subcategory: 'home_booty',
      icon: '🔥',
      isCircuit: false,
      duration: '~30 min',
      exercises: [
        WorkoutExercise(id: 'sumo_squat_pulse', name: 'Sumo Squat Pulse', sets: 3, reps: 20),
        WorkoutExercise(id: 'curtsy_lunges', name: 'Curtsy Lunges', sets: 3, reps: 12),
        WorkoutExercise(id: 'glute_bridge_hold', name: 'Glute Bridge Hold', sets: 3, reps: 30),
        WorkoutExercise(id: 'donkey_kick_pulses', name: 'Donkey Kick Pulses', sets: 3, reps: 20),
        WorkoutExercise(id: 'squat_to_kickback', name: 'Squat to Kick Back', sets: 3, reps: 12),
        WorkoutExercise(id: 'single_leg_deadlift', name: 'Single Leg Deadlift', sets: 3, reps: 10),
      ],
    ),
    WorkoutPreset(
      id: 'home_band_booty',
      name: 'BAND BOOTY',
      category: 'home',
      subcategory: 'home_booty',
      icon: '🍑',
      isCircuit: false,
      duration: '~30 min',
      exercises: [
        WorkoutExercise(id: 'banded_squat', name: 'Banded Squat', sets: 3, reps: 15),
        WorkoutExercise(id: 'banded_glute_bridge', name: 'Banded Glute Bridge', sets: 3, reps: 15),
        WorkoutExercise(id: 'banded_clamshell', name: 'Banded Clamshell', sets: 3, reps: 15),
        WorkoutExercise(id: 'banded_kickback', name: 'Banded Kickback', sets: 3, reps: 15),
        WorkoutExercise(id: 'banded_lateral_walk', name: 'Banded Lateral Walk', sets: 3, reps: 12),
        WorkoutExercise(id: 'banded_fire_hydrant', name: 'Banded Fire Hydrant', sets: 3, reps: 12),
      ],
    ),
  ];

  // HOME MODE - RECOVERY & MOBILITY
  static final List<WorkoutPreset> homeRecovery = [
    WorkoutPreset(
      id: 'home_full_body_stretch',
      name: 'FULL BODY STRETCH',
      category: 'home',
      subcategory: 'recovery',
      icon: '🧘',
      isCircuit: false,
      duration: '~20 min',
      exercises: [
        WorkoutExercise(id: 'cat_cow', name: 'Cat-Cow', sets: 2, reps: 10),
        WorkoutExercise(id: 'worlds_greatest_stretch', name: "World's Greatest Stretch", sets: 2, reps: 5),
        WorkoutExercise(id: 'pigeon_pose', name: 'Pigeon Pose', sets: 2, reps: 30),
        WorkoutExercise(id: 'hamstring_stretch', name: 'Hamstring Stretch', sets: 2, reps: 30),
        WorkoutExercise(id: 'quad_stretch', name: 'Quad Stretch', sets: 2, reps: 30),
        WorkoutExercise(id: 'chest_doorway_stretch', name: 'Chest Doorway Stretch', sets: 2, reps: 30),
        WorkoutExercise(id: 'childs_pose', name: "Child's Pose", sets: 2, reps: 30),
      ],
    ),
    WorkoutPreset(
      id: 'home_hip_opener',
      name: 'HIP OPENER',
      category: 'home',
      subcategory: 'recovery',
      icon: '🧘',
      isCircuit: false,
      duration: '~15 min',
      exercises: [
        WorkoutExercise(id: '90_90_stretch', name: '90/90 Stretch', sets: 2, reps: 30),
        WorkoutExercise(id: 'pigeon_pose', name: 'Pigeon Pose', sets: 2, reps: 30),
        WorkoutExercise(id: 'frog_stretch', name: 'Frog Stretch', sets: 2, reps: 30),
        WorkoutExercise(id: 'hip_flexor_stretch', name: 'Hip Flexor Stretch', sets: 2, reps: 30),
        WorkoutExercise(id: 'happy_baby', name: 'Happy Baby', sets: 2, reps: 30),
        WorkoutExercise(id: 'butterfly_stretch', name: 'Butterfly Stretch', sets: 2, reps: 30),
      ],
    ),
  ];

  // Combined list of all workout presets
  static List<WorkoutPreset> get allWorkoutPresets => [
    ...gymMuscleSplits,
    ...gymMuscleGroupings,
    ...gymCircuits,
    ...gymBootyBuilder,
    ...homeBodyweightBasics,
    ...homeHIITCircuits,
    ...homeBooty,
    ...homeRecovery,
  ];
}

