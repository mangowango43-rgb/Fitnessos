import 'exercise_model.dart';

enum SessionStatus {
  complete,
  skipped,
  planned,
}

class WorkoutSession {
  final String id;
  final String name;
  final DateTime date;
  final int? durationMinutes;
  final SessionStatus status;
  final List<Exercise> exercises;

  const WorkoutSession({
    required this.id,
    required this.name,
    required this.date,
    this.durationMinutes,
    required this.status,
    required this.exercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status.name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      durationMinutes: json['durationMinutes'],
      status: SessionStatus.values.firstWhere((e) => e.name == json['status']),
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e))
          .toList(),
    );
  }

  String get statusLabel {
    switch (status) {
      case SessionStatus.complete:
        return 'Complete';
      case SessionStatus.skipped:
        return 'Skipped';
      case SessionStatus.planned:
        return 'Planned';
    }
  }

  String get dateRelative {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return '1 day ago';
    if (difference < 7) return '$difference days ago';
    if (difference < 14) return '1 week ago';
    return '${(difference / 7).floor()} weeks ago';
  }
}

