/// Rep quality classification for gaming mechanics
enum RepQuality {
  perfect,  // Form score >= 85%
  good,     // Form score 60-84%
  miss,     // Form score < 60%
}

/// Data model for a single rep
class RepData {
  final RepQuality quality;
  final double formScore;
  final double angle;
  final DateTime timestamp;

  const RepData({
    required this.quality,
    required this.formScore,
    required this.angle,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'quality': quality.name,
    'formScore': formScore,
    'angle': angle,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RepData.fromJson(Map<String, dynamic> json) => RepData(
    quality: RepQuality.values.firstWhere((e) => e.name == json['quality']),
    formScore: json['formScore'],
    angle: json['angle'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

/// Data model for a complete set
class SetData {
  final List<RepData> reps;
  final int perfectCount;
  final int goodCount;
  final int missCount;
  final int maxCombo;
  final DateTime startTime;
  final DateTime endTime;

  SetData({
    required this.reps,
    required this.perfectCount,
    required this.goodCount,
    required this.missCount,
    required this.maxCombo,
    required this.startTime,
    required this.endTime,
  });

  int get totalReps => reps.length;
  double get averageFormScore => reps.isEmpty 
      ? 0.0 
      : reps.map((r) => r.formScore).reduce((a, b) => a + b) / reps.length;
  
  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
    'reps': reps.map((r) => r.toJson()).toList(),
    'perfectCount': perfectCount,
    'goodCount': goodCount,
    'missCount': missCount,
    'maxCombo': maxCombo,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
  };
}

/// Helper function to classify rep based on form score
RepQuality classifyRep(double formScore) {
  if (formScore >= 85) return RepQuality.perfect;
  if (formScore >= 60) return RepQuality.good;
  return RepQuality.miss;
}

