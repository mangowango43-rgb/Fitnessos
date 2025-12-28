class WorkoutVideo {
  final String id;
  final String videoPath;
  final String? thumbnailPath;
  final String workoutName;
  final DateTime recordedAt;
  final int durationSeconds;
  final int repsCompleted;
  final int setsCompleted;

  const WorkoutVideo({
    required this.id,
    required this.videoPath,
    this.thumbnailPath,
    required this.workoutName,
    required this.recordedAt,
    required this.durationSeconds,
    required this.repsCompleted,
    required this.setsCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'workoutName': workoutName,
      'recordedAt': recordedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'repsCompleted': repsCompleted,
      'setsCompleted': setsCompleted,
    };
  }

  factory WorkoutVideo.fromJson(Map<String, dynamic> json) {
    return WorkoutVideo(
      id: json['id'] as String,
      videoPath: json['videoPath'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      workoutName: json['workoutName'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      durationSeconds: json['durationSeconds'] as int,
      repsCompleted: json['repsCompleted'] as int,
      setsCompleted: json['setsCompleted'] as int,
    );
  }
}

