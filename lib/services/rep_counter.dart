import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

enum RepState { ready, down, up }

class ExerciseRule {
  final String id;
  final String name;
  final PoseLandmarkType targetA;
  final PoseLandmarkType targetB;
  final PoseLandmarkType rulerA;
  final PoseLandmarkType rulerB;
  final bool targetShrinks;
  final double triggerPercent;
  final double resetPercent;
  final String cueGood;
  final String cueBad;

  const ExerciseRule({
    required this.id,
    required this.name,
    required this.targetA,
    required this.targetB,
    required this.rulerA,
    required this.rulerB,
    this.targetShrinks = true,
    this.triggerPercent = 0.78, // Calibrated for "Front-on" forgiveness
    this.resetPercent = 0.92,
    this.cueGood = "Good!",
    this.cueBad = "Keep going!",
  });
}

class RepCounter {
  final ExerciseRule rule;
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  
  double _baselineRatio = 0;
  double _smoothedRatio = 0;
  double _currentPercentage = 100;
  static const double _smoothingFactor = 0.3;
  
  RepCounter(this.rule);
  
  bool get isLocked => _baselineCaptured;
  int get repCount => _repCount;
  String get feedback => _feedback;
  double get currentPercentage => _currentPercentage;
  RepState get state => _state;

  // 3D Distance Fix: Essential for High/Low angles
  double _distance3D(PoseLandmark a, PoseLandmark b) {
    return math.sqrt(
      math.pow(b.x - a.x, 2) + 
      math.pow(b.y - a.y, 2) + 
      math.pow(b.z - a.z, 2)
    );
  }

  void captureBaseline(List<PoseLandmark> landmarks) {
    final points = _extractPoints(landmarks);
    if (points == null) {
      _feedback = "Position body in frame";
      return;
    }
    
    double targetDist = _distance3D(points.targetA, points.targetB);
    double rulerDist = _distance3D(points.rulerA, points.rulerB);
    
    if (rulerDist < 0.01) return;
    
    _baselineRatio = targetDist / rulerDist;
    _smoothedRatio = _baselineRatio;
    _baselineCaptured = true;
    _state = RepState.ready;
    _feedback = "LOCKED";
  }

  bool processFrame(List<PoseLandmark> landmarks) {
    if (!_baselineCaptured) return false;
    
    final points = _extractPoints(landmarks);
    if (points == null) return false;
    
    double currentTarget = _distance3D(points.targetA, points.targetB);
    double currentRuler = _distance3D(points.rulerA, points.rulerB);
    
    if (currentRuler < 0.01) return false;
    
    double rawRatio = currentTarget / currentRuler;
    _smoothedRatio = (_smoothingFactor * rawRatio) + ((1 - _smoothingFactor) * _smoothedRatio);
    
    if (rule.targetShrinks) {
      _currentPercentage = (_smoothedRatio / _baselineRatio) * 100;
    } else {
      _currentPercentage = (_baselineRatio / _smoothedRatio) * 100;
    }
    
    _currentPercentage = _currentPercentage.clamp(0, 150);
    
    final trigger = rule.triggerPercent * 100;
    final reset = rule.resetPercent * 100;
    
    switch (_state) {
      case RepState.ready:
      case RepState.up:
        if (_currentPercentage <= trigger) {
          _state = RepState.down;
          _feedback = rule.cueGood;
        }
        return false;
      case RepState.down:
        if (_currentPercentage >= reset) {
          _state = RepState.up;
          _repCount++;
          _feedback = "";
          return true;
        }
        return false;
    }
  }

  _Points? _extractPoints(List<PoseLandmark> landmarks) {
    final map = {for (var lm in landmarks) lm.type: lm};
    
    // AUTO-DETECT PERSPECTIVE
    double lShVis = map[PoseLandmarkType.leftShoulder]?.likelihood ?? 0;
    double rShVis = map[PoseLandmarkType.rightShoulder]?.likelihood ?? 0;
    bool isFrontView = lShVis > 0.7 && rShVis > 0.7;
    
    // Choose dynamic ruler
    PoseLandmark? rA, rB;
    if (isFrontView) {
      // Use Horizontal Ruler for Front-on to prevent ratio collapse
      rA = map[PoseLandmarkType.leftShoulder];
      rB = map[PoseLandmarkType.rightShoulder];
    } else {
      rA = map[rule.rulerA];
      rB = map[rule.rulerB];
    }

    final tA = map[rule.targetA];
    final tB = map[rule.targetB];

    if (tA == null || tB == null || rA == null || rB == null) return null;
    return _Points(targetA: tA, targetB: tB, rulerA: rA, rulerB: rB);
  }

  void reset() {
    _repCount = 0;
    _state = RepState.ready;
    _feedback = "";
  }
}

class _Points {
  final PoseLandmark targetA, targetB, rulerA, rulerB;
  _Points({required this.targetA, required this.targetB, required this.rulerA, required this.rulerB});
}
class ExerciseRules {
  // Simplified constants
  static const _sh = PoseLandmarkType.leftShoulder;
  static const _rsh = PoseLandmarkType.rightShoulder;
  static const _el = PoseLandmarkType.leftElbow;
  static const _rel = PoseLandmarkType.rightElbow;
  static const _wr = PoseLandmarkType.leftWrist;
  static const _rwr = PoseLandmarkType.rightWrist;
  static const _hp = PoseLandmarkType.leftHip;
  static const _rhp = PoseLandmarkType.rightHip;
  static const _kn = PoseLandmarkType.leftKnee;
  static const _rkn = PoseLandmarkType.rightKnee;
  static const _ak = PoseLandmarkType.leftAnkle;
  static const _rak = PoseLandmarkType.rightAnkle;

  // GLOBAL CALIBRATION:
  // Leg/Squat: 0.78 Trigger (Parallel depth)
  // Push/Press: 0.75 Trigger (Full range)
  // Arms: 0.65 Trigger (Deep curl)
  
  static final Map<String, ExerciseRule> _rules = {
    // CHEST
    'bench_press': ExerciseRule(id: 'bench_press', name: 'Bench Press', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, triggerPercent: 0.75, resetPercent: 0.90),
    'pushups': ExerciseRule(id: 'pushups', name: 'Push-ups', targetA: _sh, targetB: _hp, rulerA: _sh, rulerB: _rsh, triggerPercent: 0.75, resetPercent: 0.90),
    'wide_pushups': ExerciseRule(id: 'wide_pushups', name: 'Wide Push-ups', targetA: _sh, targetB: _hp, rulerA: _sh, rulerB: _rsh, triggerPercent: 0.75, resetPercent: 0.90),
    'diamond_pushups': ExerciseRule(id: 'diamond_pushups', name: 'Diamond Push-ups', targetA: _sh, targetB: _hp, rulerA: _sh, rulerB: _rsh, triggerPercent: 0.75, resetPercent: 0.90),
    'dips_chest': ExerciseRule(id: 'dips_chest', name: 'Chest Dips', targetA: _sh, targetB: _el, rulerA: _sh, rulerB: _rsh, triggerPercent: 0.75, resetPercent: 0.90),
    'cable_crossovers': ExerciseRule(id: 'cable_crossovers', name: 'Cable Crossovers', targetA: _wr, targetB: _rwr, rulerA: _sh, rulerB: _rsh, triggerPercent: 0.70, resetPercent: 0.90),

    // LEGS
    'squats': ExerciseRule(id: 'squats', name: 'Squats', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, triggerPercent: 0.78, resetPercent: 0.92),
    'air_squats': ExerciseRule(id: 'air_squats', name: 'Air Squats', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, triggerPercent: 0.78, resetPercent: 0.92),
    'lunges': ExerciseRule(id: 'lunges', name: 'Lunges', targetA: _hp, targetB: _kn, rulerA: _sh, rulerB: _hp, triggerPercent: 0.78, resetPercent: 0.92),
    'bulgarian_split_squat': ExerciseRule(id: 'bulgarian_split_squat', name: 'Bulgarian Split Squat', targetA: _hp, targetB: _kn, rulerA: _sh, rulerB: _hp, triggerPercent: 0.78, resetPercent: 0.92),
    'deadlift': ExerciseRule(id: 'deadlift', name: 'Deadlift', targetA: _sh, targetB: _ak, rulerA: _sh, rulerB: _hp, triggerPercent: 0.85, resetPercent: 0.95),
    'romanian_deadlift': ExerciseRule(id: 'romanian_deadlift', name: 'Romanian Deadlift', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.75, resetPercent: 0.92),

    // ARMS
    'bicep_curls': ExerciseRule(id: 'bicep_curls', name: 'Bicep Curls', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _el, triggerPercent: 0.65, resetPercent: 0.88),
    'hammer_curls': ExerciseRule(id: 'hammer_curls', name: 'Hammer Curls', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _el, triggerPercent: 0.65, resetPercent: 0.88),
    'tricep_pushdown': ExerciseRule(id: 'tricep_pushdown', name: 'Tricep Pushdown', targetA: _el, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: false, triggerPercent: 0.75, resetPercent: 0.90),
    'skull_crushers': ExerciseRule(id: 'skull_crushers', name: 'Skull Crushers', targetA: _el, targetB: _wr, rulerA: _sh, rulerB: _el, triggerPercent: 0.70, resetPercent: 0.90),

    // CORE
    'sit_ups': ExerciseRule(id: 'sit_ups', name: 'Sit-ups', targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, triggerPercent: 0.75, resetPercent: 0.90),
    'crunches': ExerciseRule(id: 'crunches', name: 'Crunches', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, triggerPercent: 0.78, resetPercent: 0.92),
    'leg_raises': ExerciseRule(id: 'leg_raises', name: 'Leg Raises', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, triggerPercent: 0.75, resetPercent: 0.90),

    // ... [This pattern applies to all 120]
  };

  static ExerciseRule? getRule(String id) {
    final normalized = id.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return _rules[normalized];
  }
}
