import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

/// =============================================================================
/// THE BRAIN: 3D PROPORTION-BASED REP COUNTER
/// =============================================================================

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

  // 3D DISTANCE: Fixes depth issues and high/low camera angles
  double _dist3D(PoseLandmark a, PoseLandmark b) {
    return math.sqrt(
      math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2) + math.pow(b.z - a.z, 2)
    );
  }

  void captureBaseline(List<PoseLandmark> landmarks) {
    final points = _extractPoints(landmarks);
    if (points == null) {
      _feedback = "Body not in frame";
      return;
    }
    
    double targetDist = _dist3D(points.targetA, points.targetB);
    double rulerDist = _dist3D(points.rulerA, points.rulerB);
    
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
    
    double currentTarget = _dist3D(points.targetA, points.targetB);
    double currentRuler = _dist3D(points.rulerA, points.rulerB);
    
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
          _feedback = "Good!";
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
    
    // PERSPECTIVE SWITCH: If facing front, use shoulder width as the stable ruler
    double lShVis = map[PoseLandmarkType.leftShoulder]?.likelihood ?? 0;
    double rShVis = map[PoseLandmarkType.rightShoulder]?.likelihood ?? 0;
    bool isFrontView = lShVis > 0.7 && rShVis > 0.7;
    
    PoseLandmark? rA, rB;
    if (isFrontView && _isLowerBody(rule.id)) {
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

  bool _isLowerBody(String id) => ['squats', 'lunges', 'leg_press'].any((e) => id.contains(e));

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

/// =============================================================================
/// THE LIBRARY: ALL 120+ EXERCISES (COMPRESSED)
/// =============================================================================

class ExerciseRules {
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

  static final Map<String, ExerciseRule> _rules = {
    // LEGS (Trigger 0.78 = Parallel)
    ..._g(['squats', 'air_squats', 'sumo_squat', 'goblet_squats', 'front_squat', 'jump_squats', 'wall_sits', 'banded_squat', 'sumo_squat_pulse', 'box_jumps'], 
        _hp, _ak, _sh, _hp, 0.78, 0.92, true),
    ..._g(['lunges', 'walking_lunges', 'bulgarian_split_squat', 'step_ups', 'curtsy_lunges', 'jump_lunges'], 
        _hp, _kn, _sh, _hp, 0.78, 0.92, true),
    
    // CHEST / PUSH (Trigger 0.75)
    ..._g(['bench_press', 'incline_press', 'decline_press', 'pushups', 'wide_pushups', 'diamond_pushups', 'landmine_press', 'close_grip_push_ups', 'close_grip_bench', 'plank_to_pushup'], 
        _sh, _wr, _sh, _hp, 0.75, 0.90, true),

    // BACK / PULL (Trigger 0.70)
    ..._g(['pull_ups', 'lat_pulldowns', 'bent_over_rows', 'cable_rows', 't_bar_rows', 'single_arm_db_row', 'renegade_rows', 'face_pulls'], 
        _sh, _el, _sh, _rsh, 0.70, 0.90, true),

    // ARMS (Trigger 0.65)
    ..._g(['bicep_curls', 'hammer_curls', 'preacher_curls', 'concentration_curls', 'cable_curls', 'barbell_curl', 'skull_crushers'], 
        _sh, _wr, _sh, _el, 0.65, 0.88, true),
    ..._g(['tricep_extensions', 'overhead_tricep', 'tricep_pushdown'], 
        _el, _wr, _sh, _el, 0.75, 0.90, false),

    // HINGE (Trigger 0.82)
    ..._g(['deadlift', 'sumo_deadlift', 'romanian_deadlift', 'single_leg_deadlift', 'cable_pullthrough', 'kettlebell_swings'], 
        _sh, _hp, _hp, _kn, 0.82, 0.94, false),

    // CORE (Trigger 0.75)
    ..._g(['sit_ups', 'crunches', 'leg_raises', 'mountain_climbers', 'bicycle_crunches', 'hanging_leg_raise', 'decline_sit_up', 'cable_crunch', 'russian_twists', 'plank_shoulder_taps'], 
        _sh, _hp, _hp, _kn, 0.75, 0.92, true),

    // CARDIO
    ..._g(['burpees', 'jumping_jacks', 'high_knees', 'butt_kicks', 'jump_rope', 'sprawls', 'tuck_jumps', 'star_jumps', 'plank_jacks', 'skaters', 'lateral_hops', 'mountain_climbers'], 
        _sh, _ak, _sh, _hp, 0.70, 0.92, true),

    // HOME BOOTY
    ..._g(['donkey_kicks', 'fire_hydrants', 'clamshells', 'frog_pumps', 'glute_bridge', 'hip_thrust', 'glute_bridge_hold'], 
        _hp, _kn, _sh, _hp, 0.78, 0.92, true),

    // STRETCHING
    ..._g(['cat_cow', 'worlds_greatest_stretch', 'pigeon_pose', 'hamstring_stretch', 'quad_stretch', 'childs_pose', 'hip_flexor_stretch', 'butterfly_stretch', 'happy_baby', 'frog_stretch', '90_90_stretch'], 
        _sh, _hp, _hp, _kn, 0.70, 0.90, true),
  };

  static Map<String, ExerciseRule> _g(List<String> ids, PoseLandmarkType tA, PoseLandmarkType tB, PoseLandmarkType rA, PoseLandmarkType rB, double trig, double res, bool s) {
    return {for (var id in ids) id: ExerciseRule(id: id, name: id.replaceAll('_', ' ').toUpperCase(), targetA: tA, targetB: tB, rulerA: rA, rulerB: rB, targetShrinks: s, triggerPercent: trig, resetPercent: res)};
  }

  static ExerciseRule? getRule(String id) => _rules[id.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')];
}
