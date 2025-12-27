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
}

