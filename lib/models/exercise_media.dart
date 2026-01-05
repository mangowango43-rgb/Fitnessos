/// =============================================================================
/// EXERCISE MEDIA MODEL
/// =============================================================================
/// Stores animation URLs and metadata for exercises
/// =============================================================================

class ExerciseMedia {
  final String exerciseId;
  final String name;
  final String gifUrl;
  final String? thumbnailUrl;
  final String bodyPart;
  final String equipment;
  final String? target;
  
  const ExerciseMedia({
    required this.exerciseId,
    required this.name,
    required this.gifUrl,
    this.thumbnailUrl,
    required this.bodyPart,
    required this.equipment,
    this.target,
  });
  
  factory ExerciseMedia.fromJson(Map<String, dynamic> json) {
    return ExerciseMedia(
      exerciseId: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      gifUrl: json['gifUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      bodyPart: json['bodyPart'] ?? '',
      equipment: json['equipment'] ?? '',
      target: json['target'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': exerciseId,
      'name': name,
      'gifUrl': gifUrl,
      'thumbnailUrl': thumbnailUrl,
      'bodyPart': bodyPart,
      'equipment': equipment,
      'target': target,
    };
  }
}

/// Fallback animations based on movement pattern
class PatternFallbacks {
  static const Map<String, String> fallbackGifs = {
    'push': 'https://v2.exercisedb.io/image/sqSdY3OsCl6RtG',
    'squat': 'https://v2.exercisedb.io/image/8eAEYmIo5oIEZL',
    'hinge': 'https://v2.exercisedb.io/image/TRXJ8mRXv92ybU',
    'pull': 'https://v2.exercisedb.io/image/eEhTIZWvYXNnP8',
    'curl': 'https://v2.exercisedb.io/image/Ys7qEDj8hSNTFw',
  };
  
  static String getFallback(String pattern) {
    return fallbackGifs[pattern.toLowerCase()] ?? fallbackGifs['push']!;
  }
}

