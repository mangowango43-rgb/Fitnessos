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
    this.triggerPercent = 0.78,
    this.resetPercent = 0.92,
    this.cueGood = "Good!",
    this.cueBad = "Deeper!",
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

  /// 3D DISTANCE: Fixes depth issues and high/low camera angles
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
    
    // PERSPECTIVE SWITCH: If facing front, use shoulder width as stable ruler
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

  bool _isLowerBody(String id) {
    return ['squats', 'lunges', 'leg_press', 'box_jumps', 'step_ups', 'jump', 'glute', 'hip_thrust', 'deadlift'].any((e) => id.contains(e));
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

/// =============================================================================
/// THE LIBRARY: ALL 120+ EXERCISES
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
    // LEGS
    ..._g(['squats', 'air_squats', 'sumo_squat', 'goblet_squats', 'front_squat', 'jump_squats', 'wall_sits', 'banded_squat', 'sumo_squat_pulse', 'box_jumps'], 
        _hp, _ak, _sh, _hp, 0.78, 0.92, true, "Depth!", "Hit parallel!"),
    ..._g(['lunges', 'walking_lunges', 'bulgarian_split_squat', 'step_ups', 'curtsy_lunges', 'jump_lunges'], 
        _hp, _kn, _sh, _hp, 0.78, 0.92, true, "Great step!", "Deep lunge!"),
    ..._g(['leg_press', 'leg_extensions', 'leg_curls', 'calf_raises'],
        _hp, _ak, _sh, _hp, 0.78, 0.92, true, "Push!", "Full range!"),

    // CHEST
    ..._g(['bench_press', 'incline_press', 'decline_press'], 
        _sh, _wr, _sh, _rsh, 0.75, 0.90, true, "Good depth!", "Touch chest!"),
    ..._g(['pushups', 'push_ups', 'wide_pushups', 'diamond_pushups', 'close_grip_push_ups'], 
        _sh, _hp, _sh, _rsh, 0.75, 0.90, true, "Perfect!", "Go lower!"),
    ..._g(['dips_chest', 'tricep_dips', 'tricep_dips_chair'],
        _sh, _el, _sh, _rsh, 0.75, 0.90, true, "Nice dip!", "Get to 90!"),
    ..._g(['chest_flys', 'cable_crossovers', 'dumbbell_flyes'],
        _wr, _rwr, _sh, _rsh, 0.75, 0.90, true, "Squeeze!", "Together!"),

    // BACK
    ..._g(['pull_ups', 'pullups', 'lat_pulldowns', 'lat_pulldown'], 
        _sh, _el, _sh, _rsh, 0.70, 0.90, true, "Chin over!", "Full stretch!"),
    ..._g(['bent_over_rows', 'cable_rows', 't_bar_rows', 'single_arm_db_row', 'renegade_rows'], 
        _sh, _wr, _sh, _hp, 0.70, 0.90, true, "Nice pull!", "Squeeze lats!"),
    ..._g(['face_pulls', 'reverse_flys'],
        _el, _rel, _sh, _rsh, 0.70, 0.90, false, "Great!", "Pull wide!"),
    ..._g(['shrugs'],
        _sh, _hp, _hp, _kn, 0.92, 0.97, true, "High!", "Full shrug!"),

    // SHOULDERS
    ..._g(['overhead_press', 'shoulder_press', 'arnold_press', 'seated_db_press'],
        _sh, _wr, _sh, _hp, 0.75, 0.90, false, "Sky high!", "Lock out!"),
    ..._g(['lateral_raises', 'front_raises', 'cable_lateral_raise'],
        _wr, _hp, _sh, _hp, 0.75, 0.90, false, "Perfect!", "To shoulders!"),
    ..._g(['rear_delt_flys', 'upright_rows'],
        _el, _hp, _sh, _hp, 0.75, 0.90, true, "Wide!", "Pull higher!"),
    ..._g(['pike_push_ups', 'plank_shoulder_taps'],
        _sh, _wr, _sh, _hp, 0.75, 0.90, true, "Strong!", "Control!"),

    // ARMS
    ..._g(['bicep_curls', 'hammer_curls', 'preacher_curls', 'concentration_curls', 'cable_curls', 'barbell_curl'], 
        _sh, _wr, _sh, _el, 0.65, 0.88, true, "Full curl!", "No swinging!"),
    ..._g(['skull_crushers'],
        _el, _wr, _sh, _el, 0.65, 0.88, true, "Perfect!", "To forehead!"),
    ..._g(['tricep_extensions', 'overhead_tricep', 'tricep_pushdown'], 
        _el, _wr, _sh, _el, 0.75, 0.90, false, "Strong!", "Full extend!"),

    // HINGE
    ..._g(['deadlift', 'sumo_deadlift'], 
        _sh, _ak, _sh, _hp, 0.82, 0.94, false, "Lockout!", "Hips forward!"),
    ..._g(['romanian_deadlift', 'single_leg_deadlift', 'cable_pullthrough'], 
        _sh, _hp, _hp, _kn, 0.82, 0.94, false, "Hamstrings!", "Flat back!"),
    ..._g(['kettlebell_swings'],
        _wr, _hp, _sh, _hp, 0.82, 0.94, false, "Swing!", "Hips drive!"),

    // CORE
    ..._g(['sit_ups', 'situps', 'crunches', 'decline_sit_up', 'cable_crunch'], 
        _sh, _hp, _hp, _kn, 0.75, 0.92, true, "Core strong!", "Squeeze abs!"),
    ..._g(['leg_raises', 'hanging_leg_raise'],
        _hp, _ak, _sh, _hp, 0.75, 0.92, true, "Legs high!", "Lower slow!"),
    ..._g(['mountain_climbers', 'bicycle_crunches'],
        _kn, _sh, _sh, _hp, 0.75, 0.92, true, "Fast feet!", "Knees to chest!"),
    ..._g(['russian_twists', 'woodchoppers'],
        _wr, _hp, _sh, _hp, 0.75, 0.92, false, "Twist!", "Rotate!"),
    ..._g(['plank', 'plank_hold', 'side_plank'],
        _sh, _ak, _sh, _hp, 0.95, 0.98, false, "Flat back!", "Don't sag!"),
    ..._g(['dead_bug', 'superman_raises', 'superman'],
        _wr, _ak, _sh, _hp, 0.75, 0.92, false, "Slow!", "Arms up!"),

    // CARDIO
    ..._g(['burpees', 'sprawls'], 
        _sh, _ak, _sh, _hp, 0.70, 0.92, true, "Explode!", "Full extension!"),
    ..._g(['jumping_jacks', 'star_jumps'],
        _wr, _rwr, _sh, _rsh, 0.70, 0.92, false, "Jump!", "Arms high!"),
    ..._g(['high_knees', 'butt_kicks', 'tuck_jumps'],
        _kn, _hp, _sh, _hp, 0.70, 0.92, true, "Knees up!", "Higher!"),
    ..._g(['jump_rope', 'skaters', 'lateral_hops'],
        _ak, _rak, _hp, _rhp, 0.70, 0.92, false, "Bounce!", "Light feet!"),
    ..._g(['plank_jacks'],
        _ak, _rak, _sh, _rsh, 0.70, 0.92, false, "Jump!", "Feet wide!"),
    ..._g(['bear_crawls'],
        _sh, _hp, _hp, _kn, 0.85, 0.95, true, "Crawl!", "Low hips!"),

    // HOME BOOTY
    ..._g(['glute_bridge', 'single_leg_glute_bridge', 'hip_thrust', 'glute_bridge_hold', 'banded_glute_bridge'], 
        _sh, _kn, _hp, _kn, 0.78, 0.92, false, "Squeeze!", "Hips up!"),
    ..._g(['donkey_kicks', 'donkey_kick_pulses', 'banded_kickback'],
        _kn, _ak, _hp, _kn, 0.78, 0.92, false, "Kick!", "Squeeze glute!"),
    ..._g(['fire_hydrants', 'banded_fire_hydrant'],
        _kn, _hp, _sh, _hp, 0.78, 0.92, false, "Lift!", "Open hip!"),
    ..._g(['clamshells', 'banded_clamshell'],
        _kn, _rkn, _hp, _rhp, 0.78, 0.92, false, "Open!", "Keep feet together!"),
    ..._g(['frog_pumps'],
        _sh, _kn, _hp, _kn, 0.78, 0.92, false, "Pump!", "Hips up!"),
    ..._g(['squat_to_kickback'],
        _hp, _ak, _sh, _hp, 0.78, 0.92, true, "Kick!", "Full squat!"),
    ..._g(['banded_lateral_walk'],
        _ak, _rak, _hp, _rhp, 0.78, 0.92, false, "Step!", "Stay low!"),

    // STRETCHING
    ..._g(['cat_cow'],
        _sh, _hp, _hp, _kn, 0.70, 0.90, false, "Flow!", "Arch back!"),
    ..._g(['worlds_greatest_stretch'],
        _sh, _kn, _hp, _kn, 0.70, 0.90, true, "Deep!", "Rotate!"),
    ..._g(['pigeon_pose', '90_90_stretch'],
        _sh, _hp, _hp, _kn, 0.85, 0.95, true, "Hold!", "Square hips!"),
    ..._g(['hamstring_stretch'],
        _sh, _ak, _sh, _hp, 0.70, 0.90, true, "Feel it!", "Reach!"),
    ..._g(['quad_stretch'],
        _ak, _hp, _hp, _kn, 0.70, 0.90, true, "Pull!", "Leg behind!"),
    ..._g(['childs_pose'],
        _sh, _kn, _hp, _kn, 0.70, 0.90, true, "Breathe!", "Sit back!"),
    ..._g(['hip_flexor_stretch'],
        _sh, _kn, _hp, _kn, 0.70, 0.90, true, "Push!", "Lunge forward!"),
    ..._g(['butterfly_stretch', 'frog_stretch'],
        _kn, _rkn, _hp, _rhp, 0.70, 0.90, false, "Relax!", "Knees wide!"),
    ..._g(['happy_baby'],
        _ak, _sh, _hp, _kn, 0.70, 0.90, true, "Relax!", "Knees wide!"),
    ..._g(['chest_doorway_stretch'],
        _wr, _sh, _sh, _hp, 0.70, 0.90, false, "Open!", "Lean in!"),
  };

  static Map<String, ExerciseRule> _g(List<String> ids, PoseLandmarkType tA, PoseLandmarkType tB, PoseLandmarkType rA, PoseLandmarkType rB, double trig, double res, bool shrinks, String good, String bad) {
    return {for (var id in ids) id: ExerciseRule(id: id, name: _formatName(id), targetA: tA, targetB: tB, rulerA: rA, rulerB: rB, targetShrinks: shrinks, triggerPercent: trig, resetPercent: res, cueGood: good, cueBad: bad)};
  }

  static String _formatName(String id) {
    return id.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  static ExerciseRule? getRule(String id) {
    final normalized = id.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return _rules[normalized];
  }

  static bool hasRule(String id) => getRule(id) != null;
  static int get exerciseCount => _rules.length;
  static List<String> get allIds => _rules.keys.toList();
}
