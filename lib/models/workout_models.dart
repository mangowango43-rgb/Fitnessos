class WorkoutExercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final int? timeSeconds;      // For circuits
  final int? restSeconds;      // For circuits
  final bool included;         // For editor

  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    this.timeSeconds,
    this.restSeconds,
    this.included = true,
  });

  WorkoutExercise copyWith({
    String? id,
    String? name,
    int? sets,
    int? reps,
    int? timeSeconds,
    int? restSeconds,
    bool? included,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      included: included ?? this.included,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sets': sets,
      'reps': reps,
      'timeSeconds': timeSeconds,
      'restSeconds': restSeconds,
      'included': included,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      timeSeconds: json['timeSeconds'] as int?,
      restSeconds: json['restSeconds'] as int?,
      included: json['included'] as bool? ?? true,
    );
  }
}

class WorkoutPreset {
  final String id;
  final String name;
  final String category;       // 'gym' or 'home'
  final String subcategory;    // 'muscle_splits', 'muscle_groupings', 'circuits', 'booty_builder', etc.
  final List<WorkoutExercise> exercises;
  final int? rounds;           // For circuits
  final String? duration;      // Estimated time
  final bool isCircuit;
  final String? icon;          // Optional icon for display

  const WorkoutPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.exercises,
    this.rounds,
    this.duration,
    required this.isCircuit,
    this.icon,
  });

  int get estimatedMinutes {
    if (duration != null && duration!.isNotEmpty) {
      // Parse duration string like "45 min" or "~45 min"
      final match = RegExp(r'\d+').firstMatch(duration!);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 0;
      }
    }
    
    // Calculate from exercises
    int totalMinutes = 0;
    for (final exercise in exercises) {
      if (exercise.timeSeconds != null && exercise.restSeconds != null) {
        // Circuit workout
        totalMinutes += ((exercise.timeSeconds! + exercise.restSeconds!) * (rounds ?? 1)) ~/ 60;
      } else {
        // Regular workout: assume ~2 min per set
        totalMinutes += exercise.sets * 2;
      }
    }
    return totalMinutes;
  }

  WorkoutPreset copyWith({
    String? id,
    String? name,
    String? category,
    String? subcategory,
    List<WorkoutExercise>? exercises,
    int? rounds,
    String? duration,
    bool? isCircuit,
    String? icon,
  }) {
    return WorkoutPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      exercises: exercises ?? this.exercises,
      rounds: rounds ?? this.rounds,
      duration: duration ?? this.duration,
      isCircuit: isCircuit ?? this.isCircuit,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'rounds': rounds,
      'duration': duration,
      'isCircuit': isCircuit,
      'icon': icon,
    };
  }

  factory WorkoutPreset.fromJson(Map<String, dynamic> json) {
    return WorkoutPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      rounds: json['rounds'] as int?,
      duration: json['duration'] as String?,
      isCircuit: json['isCircuit'] as bool,
      icon: json['icon'] as String?,
    );
  }
}

class LockedWorkout {
  final String id;
  final String name;
  final List<WorkoutExercise> exercises;
  final DateTime lockedAt;
  final int estimatedMinutes;
  final bool isCircuit;
  final int? rounds;

  const LockedWorkout({
    required this.id,
    required this.name,
    required this.exercises,
    required this.lockedAt,
    required this.estimatedMinutes,
    required this.isCircuit,
    this.rounds,
  });

  factory LockedWorkout.fromPreset(WorkoutPreset preset, {List<WorkoutExercise>? customExercises}) {
    final includedExercises = (customExercises ?? preset.exercises)
        .where((e) => e.included)
        .toList();
    
    return LockedWorkout(
      id: preset.id,
      name: preset.name,
      exercises: includedExercises,
      lockedAt: DateTime.now(),
      estimatedMinutes: preset.estimatedMinutes,
      isCircuit: preset.isCircuit,
      rounds: preset.rounds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'lockedAt': lockedAt.toIso8601String(),
      'estimatedMinutes': estimatedMinutes,
      'isCircuit': isCircuit,
      'rounds': rounds,
    };
  }

  factory LockedWorkout.fromJson(Map<String, dynamic> json) {
    return LockedWorkout(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      lockedAt: DateTime.parse(json['lockedAt'] as String),
      estimatedMinutes: json['estimatedMinutes'] as int,
      isCircuit: json['isCircuit'] as bool,
      rounds: json['rounds'] as int?,
    );
  }
}

