class WorkoutTemplate {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<WorkoutExercise> exercises;
  
  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.exercises,
  });
}

class WorkoutExercise {
  final String exerciseId;
  final String name;
  final int sets;
  final String reps; // "8" or "8-10" or "AMRAP"
  final int? restSeconds;
  final String? notes;
  
  WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    this.restSeconds = 90,
    this.notes,
  });
}

class WorkoutTemplates {
  static final pushDay = WorkoutTemplate(
    id: 'push',
    name: 'Push Day',
    emoji: '🔥',
    description: 'Chest, Shoulders, Triceps',
    exercises: [
      WorkoutExercise(
        exerciseId: 'bench_press',
        name: 'Bench Press',
        sets: 4,
        reps: '8',
        restSeconds: 120,
      ),
      WorkoutExercise(
        exerciseId: 'incline_db_press',
        name: 'Incline Dumbbell Press',
        sets: 3,
        reps: '10',
        restSeconds: 90,
      ),
      WorkoutExercise(
        exerciseId: 'shoulder_press',
        name: 'Shoulder Press',
        sets: 3,
        reps: '10',
        restSeconds: 90,
      ),
      WorkoutExercise(
        exerciseId: 'lateral_raise',
        name: 'Lateral Raises',
        sets: 3,
        reps: '12',
        restSeconds: 60,
      ),
      WorkoutExercise(
        exerciseId: 'tricep_pushdown',
        name: 'Tricep Pushdowns',
        sets: 3,
        reps: '12',
        restSeconds: 60,
      ),
    ],
  );
  
  static final pullDay = WorkoutTemplate(
    id: 'pull',
    name: 'Pull Day',
    emoji: '💪',
    description: 'Back, Biceps, Rear Delts',
    exercises: [
      WorkoutExercise(
        exerciseId: 'deadlift',
        name: 'Deadlift',
        sets: 4,
        reps: '6',
        restSeconds: 180,
      ),
      WorkoutExercise(
        exerciseId: 'pull_ups',
        name: 'Pull-ups',
        sets: 3,
        reps: '8-10',
        restSeconds: 120,
      ),
      WorkoutExercise(
        exerciseId: 'barbell_row',
        name: 'Barbell Row',
        sets: 3,
        reps: '10',
        restSeconds: 90,
      ),
      WorkoutExercise(
        exerciseId: 'face_pull',
        name: 'Face Pulls',
        sets: 3,
        reps: '15',
        restSeconds: 60,
      ),
      WorkoutExercise(
        exerciseId: 'bicep_curl',
        name: 'Bicep Curls',
        sets: 3,
        reps: '12',
        restSeconds: 60,
      ),
    ],
  );
  
  static final legDay = WorkoutTemplate(
    id: 'legs',
    name: 'Leg Day',
    emoji: '🦵',
    description: 'Quads, Hamstrings, Glutes',
    exercises: [
      WorkoutExercise(
        exerciseId: 'squat',
        name: 'Back Squat',
        sets: 4,
        reps: '8',
        restSeconds: 150,
      ),
      WorkoutExercise(
        exerciseId: 'romanian_deadlift',
        name: 'Romanian Deadlift',
        sets: 3,
        reps: '10',
        restSeconds: 120,
      ),
      WorkoutExercise(
        exerciseId: 'leg_press',
        name: 'Leg Press',
        sets: 3,
        reps: '12',
        restSeconds: 90,
      ),
      WorkoutExercise(
        exerciseId: 'leg_curl',
        name: 'Leg Curls',
        sets: 3,
        reps: '12',
        restSeconds: 60,
      ),
      WorkoutExercise(
        exerciseId: 'calf_raise',
        name: 'Calf Raises',
        sets: 4,
        reps: '15',
        restSeconds: 45,
      ),
    ],
  );
  
  static List<WorkoutTemplate> getAll() {
    return [pushDay, pullDay, legDay];
  }
}
