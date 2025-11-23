enum ExerciseDifficulty {
  easy,
  medium,
  hard,
}

class Exercise {
  final String id;
  final String name;
  final int sets;
  final String reps;
  final String muscles;
  final ExerciseDifficulty difficulty;

  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.muscles,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sets': sets,
      'reps': reps,
      'muscles': muscles,
      'difficulty': difficulty.name,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      muscles: json['muscles'],
      difficulty: ExerciseDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
      ),
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case ExerciseDifficulty.easy:
        return 'Easy';
      case ExerciseDifficulty.medium:
        return 'Medium';
      case ExerciseDifficulty.hard:
        return 'Hard';
    }
  }
}

