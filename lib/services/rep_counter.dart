import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

/// =============================================================================
/// THE UNICORN ENGINE - HYBRID DETECTION
/// =============================================================================
/// 
/// 3 CORE PATTERNS:
/// - SQUAT (Knee Chain): Proportion method + shoulder-width ruler from front
/// - HINGE (Hip Chain): Angle method (hip angle)
/// - PUSH (Elbow Chain): DUAL VALIDATION - angle OR distance
/// 
/// If we nail these 3, all 120+ exercises work.
/// =============================================================================

enum RepState { ready, down, up }

enum MovementPattern { squat, hinge, push, pull, curl }

class ExerciseRule {
  final String id;
  final String name;
  final MovementPattern pattern;
  
  // For PROPORTION tracking (Squat pattern)
  final PoseLandmarkType targetA;
  final PoseLandmarkType targetB;
  final double triggerPercent;  // e.g., 0.78 = 78% of baseline
  final double resetPercent;    // e.g., 0.92 = 92% of baseline
  
  // For ANGLE tracking (Hinge/Push patterns)
  final PoseLandmarkType? jointA;
  final PoseLandmarkType? jointVertex;
  final PoseLandmarkType? jointB;
  final double triggerAngle;    // e.g., 90 degrees
  final double resetAngle;      // e.g., 160 degrees
  
  final String cueGood;
  final String cueBad;

  const ExerciseRule({
    required this.id,
    required this.name,
    required this.pattern,
    required this.targetA,
    required this.targetB,
    this.triggerPercent = 0.78,
    this.resetPercent = 0.92,
    this.jointA,
    this.jointVertex,
    this.jointB,
    this.triggerAngle = 90,
    this.resetAngle = 160,
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
  
  // Baseline values
  double _baselineTarget = 0;
  double _baselineRuler = 0;
  
  // Current values for UI
  double _currentPercentage = 100;
  double _currentAngle = 180;
  double _smoothedPercentage = 100;
  double _smoothedAngle = 180;
  
  // Anti-ghost
  static const double _smoothingFactor = 0.3;
  DateTime? _intentTimer;
  static const int _intentDelayMs = 150;
  
  RepCounter(this.rule);
  
  bool get isLocked => _baselineCaptured;
  int get repCount => _repCount;
  String get feedback => _feedback;
  double get currentPercentage => _currentPercentage;
  RepState get state => _state;

  /// 3D Angle calculation using dot product
  double _calculateAngle(PoseLandmark a, PoseLandmark v, PoseLandmark b) {
    double v1x = a.x - v.x, v1y = a.y - v.y, v1z = a.z - v.z;
    double v2x = b.x - v.x, v2y = b.y - v.y, v2z = b.z - v.z;
    
    double dot = (v1x * v2x) + (v1y * v2y) + (v1z * v2z);
    double mag1 = math.sqrt(v1x * v1x + v1y * v1y + v1z * v1z);
    double mag2 = math.sqrt(v2x * v2x + v2y * v2y + v2z * v2z);
    
    if (mag1 < 0.001 || mag2 < 0.001) return 180;
    
    double cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180 / math.pi;
  }

  /// 3D Distance calculation
  double _dist3D(PoseLandmark a, PoseLandmark b) {
    return math.sqrt(
      math.pow(b.x - a.x, 2) + 
      math.pow(b.y - a.y, 2) + 
      math.pow(b.z - a.z, 2)
    );
  }

  void captureBaseline(List<PoseLandmark> landmarks) {
    final map = {for (var lm in landmarks) lm.type: lm};
    
    final tA = map[rule.targetA];
    final tB = map[rule.targetB];
    
    if (tA == null || tB == null) {
      _feedback = "Body not in frame";
      return;
    }
    
    _baselineTarget = _dist3D(tA, tB);
    
    // SHOULDER-WIDTH RULER for front view (the fix that made squats work)
    final lSh = map[PoseLandmarkType.leftShoulder];
    final rSh = map[PoseLandmarkType.rightShoulder];
    
    if (lSh != null && rSh != null && lSh.likelihood > 0.6 && rSh.likelihood > 0.6) {
      _baselineRuler = _dist3D(lSh, rSh);
    } else {
      // Fallback to target distance as ruler
      _baselineRuler = _baselineTarget;
    }
    
    if (_baselineRuler < 0.01 || _baselineTarget < 0.01) {
      _feedback = "Move back";
      return;
    }
    
    _smoothedPercentage = 100;
    _smoothedAngle = 180;
    _baselineCaptured = true;
    _state = RepState.ready;
    _feedback = "LOCKED";
  }

  bool processFrame(List<PoseLandmark> landmarks) {
    if (!_baselineCaptured) {
      _feedback = "Waiting for lock";
      return false;
    }
    
    final map = {for (var lm in landmarks) lm.type: lm};
    
    final tA = map[rule.targetA];
    final tB = map[rule.targetB];
    
    if (tA == null || tB == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    // Calculate current distance
    double currentTarget = _dist3D(tA, tB);
    
    // Get shoulder-width ruler (front view fix)
    double currentRuler = _baselineRuler;
    final lSh = map[PoseLandmarkType.leftShoulder];
    final rSh = map[PoseLandmarkType.rightShoulder];
    if (lSh != null && rSh != null && lSh.likelihood > 0.6 && rSh.likelihood > 0.6) {
      currentRuler = _dist3D(lSh, rSh);
    }
    
    if (currentRuler < 0.01) currentRuler = _baselineRuler;
    
    // Calculate proportion (normalized by ruler)
    double baselineRatio = _baselineTarget / _baselineRuler;
    double currentRatio = currentTarget / currentRuler;
    double rawPercentage = (currentRatio / baselineRatio) * 100;
    
    _smoothedPercentage = (_smoothingFactor * rawPercentage) + ((1 - _smoothingFactor) * _smoothedPercentage);
    _currentPercentage = _smoothedPercentage.clamp(0, 150);
    
    // Calculate angle if joints are defined
    double rawAngle = 180;
    if (rule.jointA != null && rule.jointVertex != null && rule.jointB != null) {
      final jA = map[rule.jointA];
      final jV = map[rule.jointVertex];
      final jB = map[rule.jointB];
      
      if (jA != null && jV != null && jB != null) {
        rawAngle = _calculateAngle(jA, jV, jB);
      }
    }
    _smoothedAngle = (_smoothingFactor * rawAngle) + ((1 - _smoothingFactor) * _smoothedAngle);
    _currentAngle = _smoothedAngle;
    
    // Determine if "down" position based on pattern
    bool isDown = _checkIsDown();
    bool isReset = _checkIsReset();
    
    switch (_state) {
      case RepState.ready:
      case RepState.up:
        if (isDown) {
          _intentTimer ??= DateTime.now();
          if (DateTime.now().difference(_intentTimer!).inMilliseconds > _intentDelayMs) {
            _state = RepState.down;
            _feedback = rule.cueGood;
            _intentTimer = null;
          }
        } else {
          _intentTimer = null;
          if (!isReset) {
            _feedback = rule.cueBad;
          } else {
            _feedback = "";
          }
        }
        return false;

      case RepState.down:
        if (isReset) {
          _state = RepState.up;
          _repCount++;
          _feedback = "";
          return true;
        }
        return false;
    }
  }

  /// Check if user is in "down" position
  bool _checkIsDown() {
    switch (rule.pattern) {
      case MovementPattern.squat:
        // Proportion only: hip-to-ankle drops to 78% of baseline
        return _currentPercentage <= (rule.triggerPercent * 100);
        
      case MovementPattern.hinge:
        // Angle only: hip angle closes
        return _currentAngle <= rule.triggerAngle;
        
      case MovementPattern.push:
        // DUAL VALIDATION: Either angle OR proportion triggers
        bool angleTriggered = _currentAngle <= rule.triggerAngle;
        bool proportionTriggered = _currentPercentage <= (rule.triggerPercent * 100);
        return angleTriggered || proportionTriggered;
        
      case MovementPattern.pull:
        // Angle: elbow closes
        return _currentAngle <= rule.triggerAngle;
        
      case MovementPattern.curl:
        // Angle: elbow closes tight
        return _currentAngle <= rule.triggerAngle;
    }
  }

  /// Check if user has returned to start position
  bool _checkIsReset() {
    switch (rule.pattern) {
      case MovementPattern.squat:
        return _currentPercentage >= (rule.resetPercent * 100);
        
      case MovementPattern.hinge:
        return _currentAngle >= rule.resetAngle;
        
      case MovementPattern.push:
        // DUAL: Both must reset (more strict on reset to prevent ghost reps)
        bool angleReset = _currentAngle >= rule.resetAngle;
        bool proportionReset = _currentPercentage >= (rule.resetPercent * 100);
        return angleReset && proportionReset;
        
      case MovementPattern.pull:
        return _currentAngle >= rule.resetAngle;
        
      case MovementPattern.curl:
        return _currentAngle >= rule.resetAngle;
    }
  }

  void reset() {
    _repCount = 0;
    _state = RepState.ready;
    _feedback = "";
    _intentTimer = null;
  }
}

/// =============================================================================
/// EXERCISE LIBRARY - ALL 120+ MAPPED TO 5 PATTERNS
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
    
    // =========================================================================
    // SQUAT PATTERN - Proportion method (hip-to-ankle with shoulder-width ruler)
    // Trigger: 78% of baseline (parallel depth)
    // =========================================================================
    ..._squat(['squats', 'air_squats', 'goblet_squats', 'front_squat', 'back_squat', 'sumo_squat'], 
        0.78, 0.92, "Depth!", "Hit parallel!"),
    ..._squat(['jump_squats', 'box_jumps', 'banded_squat'], 
        0.80, 0.92, "Explode!", "Lower!"),
    ..._squat(['wall_sits'], 
        0.80, 0.85, "Hold!", "90 degrees!"),
    ..._squat(['lunges', 'walking_lunges', 'reverse_lunges', 'curtsy_lunges', 'jump_lunges'], 
        0.78, 0.92, "Great step!", "Deeper!"),
    ..._squat(['bulgarian_split_squat', 'step_ups'], 
        0.78, 0.92, "Strong!", "Full depth!"),
    ..._squat(['leg_press', 'leg_extensions', 'leg_curls', 'calf_raises'],
        0.78, 0.92, "Push!", "Full range!"),

    // =========================================================================
    // HINGE PATTERN - Angle method (hip angle: shoulder-hip-knee)
    // Trigger: Hip angle closes to ~100-110°
    // =========================================================================
    ..._hinge(['deadlift', 'sumo_deadlift'], 
        105, 165, "Lockout!", "Hips forward!"),
    ..._hinge(['romanian_deadlift', 'single_leg_deadlift', 'stiff_leg_deadlift'], 
        100, 160, "Hamstrings!", "Flat back!"),
    ..._hinge(['kettlebell_swings', 'cable_pullthrough'], 
        110, 170, "Snap!", "Hips drive!"),
    ..._hinge(['glute_bridge', 'hip_thrust', 'single_leg_glute_bridge', 'banded_glute_bridge', 'frog_pumps'], 
        160, 110, "Squeeze!", "Hips up!"),  // Note: reversed - hips OPEN
    ..._hinge(['good_mornings'],
        100, 160, "Feel it!", "Hinge!"),

    // =========================================================================
    // PUSH PATTERN - DUAL VALIDATION (angle OR proportion)
    // Angle: Elbow closes to ~90°
    // Proportion: Shoulder-to-wrist drops to ~75%
    // =========================================================================
    ..._push(['pushups', 'push_ups', 'wide_pushups', 'diamond_pushups', 'close_grip_push_ups'], 
        95, 155, 0.75, 0.90, "Perfect!", "Go lower!"),
    ..._push(['bench_press', 'incline_press', 'decline_press', 'dumbbell_press', 'close_grip_bench'], 
        90, 150, 0.70, 0.88, "Good depth!", "Touch chest!"),
    ..._push(['tricep_dips', 'tricep_dips_chair', 'dips_chest'], 
        90, 155, 0.75, 0.90, "Nice dip!", "Get to 90!"),
    ..._push(['overhead_press', 'shoulder_press', 'arnold_press', 'seated_db_press', 'pike_push_ups'], 
        155, 90, 0.75, 0.90, "Lockout!", "Press up!"),  // Note: reversed - arms EXTEND
    ..._push(['plank_to_pushup'],
        95, 155, 0.75, 0.90, "Up!", "Down!"),
    ..._push(['chest_flys', 'cable_crossovers', 'dumbbell_flyes'],
        95, 155, 0.70, 0.88, "Squeeze!", "Together!"),

    // =========================================================================
    // PULL PATTERN - Angle method (elbow closes)
    // =========================================================================
    ..._pull(['pull_ups', 'pullups', 'chin_ups'], 
        75, 155, "Chin up!", "Full hang!"),
    ..._pull(['lat_pulldowns', 'lat_pulldown'], 
        80, 150, "Squeeze!", "Full stretch!"),
    ..._pull(['bent_over_rows', 'barbell_row', 'pendlay_row'], 
        80, 150, "Pull!", "Squeeze lats!"),
    ..._pull(['cable_rows', 'seated_cable_row', 't_bar_rows'], 
        80, 145, "Row!", "Full extension!"),
    ..._pull(['single_arm_db_row', 'dumbbell_row', 'renegade_rows'], 
        75, 150, "Pull high!", "Stretch!"),
    ..._pull(['face_pulls', 'reverse_flys'],
        85, 150, "Back!", "Pull wide!"),

    // =========================================================================
    // CURL PATTERN - Angle method (elbow closes tight)
    // =========================================================================
    ..._curl(['bicep_curls', 'hammer_curls', 'barbell_curl', 'ez_bar_curl'], 
        50, 145, "Full curl!", "Squeeze!"),
    ..._curl(['preacher_curls', 'concentration_curls', 'cable_curls', 'incline_curls'], 
        45, 140, "Peak!", "Control!"),
    ..._curl(['tricep_extensions', 'overhead_tricep', 'tricep_pushdown', 'skull_crushers', 'tricep_kickbacks'], 
        150, 85, "Lockout!", "Extend!"),  // Note: reversed - arm EXTENDS

    // =========================================================================
    // ADDITIONAL EXERCISES - Mapped to closest pattern
    // =========================================================================
    
    // Core (use squat pattern - proportion based)
    ..._squat(['sit_ups', 'situps', 'crunches', 'decline_sit_up'], 
        0.70, 0.90, "Crunch!", "Squeeze abs!"),
    ..._squat(['leg_raises', 'hanging_leg_raise'],
        0.70, 0.90, "Legs up!", "Control!"),
    ..._squat(['mountain_climbers', 'bicycle_crunches'],
        0.75, 0.90, "Fast!", "Knees up!"),
    ..._squat(['russian_twists', 'woodchoppers'],
        0.80, 0.92, "Twist!", "Rotate!"),
    ..._squat(['plank', 'plank_hold', 'side_plank'],
        0.95, 0.98, "Hold!", "Stay flat!"),
    ..._squat(['superman_raises', 'superman', 'dead_bug'],
        0.80, 0.92, "Fly!", "Extend!"),

    // Cardio (use squat pattern)
    ..._squat(['burpees', 'sprawls'], 
        0.65, 0.90, "Explode!", "Chest down!"),
    ..._squat(['jumping_jacks', 'star_jumps'],
        0.80, 0.92, "Jump!", "Arms up!"),
    ..._squat(['high_knees', 'butt_kicks', 'tuck_jumps'],
        0.70, 0.90, "Higher!", "Knees up!"),
    ..._squat(['bear_crawls'],
        0.80, 0.92, "Crawl!", "Stay low!"),
    ..._squat(['skaters', 'lateral_hops'],
        0.80, 0.92, "Jump!", "Side to side!"),

    // Booty (use hinge pattern)
    ..._hinge(['donkey_kicks', 'donkey_kick_pulses', 'banded_kickback'], 
        155, 100, "Kick!", "Squeeze glute!"),
    ..._squat(['fire_hydrants', 'banded_fire_hydrant', 'clamshells', 'banded_clamshell'],
        0.80, 0.92, "Open!", "Control!"),

    // Shoulders (use push pattern)
    ..._push(['lateral_raises', 'front_raises', 'cable_lateral_raise'],
        150, 90, 0.80, 0.92, "Arms up!", "To shoulders!"),
    ..._push(['rear_delt_flys', 'upright_rows'],
        100, 150, 0.75, 0.90, "Pull!", "Elbows high!"),
    ..._push(['shrugs'],
        170, 160, 0.92, 0.97, "High!", "Squeeze!"),

    // Stretches (use squat pattern - just tracking position)
    ..._squat(['childs_pose', 'cat_cow', 'worlds_greatest_stretch'],
        0.70, 0.90, "Breathe!", "Deep!"),
    ..._squat(['hamstring_stretch', 'quad_stretch', 'hip_flexor_stretch'],
        0.75, 0.90, "Hold!", "Stretch!"),
    ..._squat(['pigeon_pose', 'butterfly_stretch', 'frog_stretch', '90_90_stretch'],
        0.75, 0.90, "Relax!", "Open!"),
  };

  // =========================================================================
  // PATTERN GENERATORS
  // =========================================================================

  /// SQUAT pattern: Hip-to-Ankle proportion with shoulder-width ruler
  static Map<String, ExerciseRule> _squat(List<String> ids, double trigger, double reset, String good, String bad) {
    return {
      for (var id in ids) id: ExerciseRule(
        id: id,
        name: _formatName(id),
        pattern: MovementPattern.squat,
        targetA: _hp,
        targetB: _ak,
        triggerPercent: trigger,
        resetPercent: reset,
        cueGood: good,
        cueBad: bad,
      )
    };
  }

  /// HINGE pattern: Hip angle (Shoulder-Hip-Knee)
  static Map<String, ExerciseRule> _hinge(List<String> ids, double trigger, double reset, String good, String bad) {
    return {
      for (var id in ids) id: ExerciseRule(
        id: id,
        name: _formatName(id),
        pattern: MovementPattern.hinge,
        targetA: _sh,
        targetB: _ak,
        jointA: _sh,
        jointVertex: _hp,
        jointB: _kn,
        triggerAngle: trigger,
        resetAngle: reset,
        cueGood: good,
        cueBad: bad,
      )
    };
  }

  /// PUSH pattern: DUAL VALIDATION (Elbow angle OR Shoulder-to-Wrist proportion)
  static Map<String, ExerciseRule> _push(List<String> ids, double trigAngle, double resetAngle, double trigPct, double resetPct, String good, String bad) {
    return {
      for (var id in ids) id: ExerciseRule(
        id: id,
        name: _formatName(id),
        pattern: MovementPattern.push,
        targetA: _sh,
        targetB: _wr,
        triggerPercent: trigPct,
        resetPercent: resetPct,
        jointA: _sh,
        jointVertex: _el,
        jointB: _wr,
        triggerAngle: trigAngle,
        resetAngle: resetAngle,
        cueGood: good,
        cueBad: bad,
      )
    };
  }

  /// PULL pattern: Elbow angle (Shoulder-Elbow-Wrist)
  static Map<String, ExerciseRule> _pull(List<String> ids, double trigger, double reset, String good, String bad) {
    return {
      for (var id in ids) id: ExerciseRule(
        id: id,
        name: _formatName(id),
        pattern: MovementPattern.pull,
        targetA: _sh,
        targetB: _wr,
        jointA: _sh,
        jointVertex: _el,
        jointB: _wr,
        triggerAngle: trigger,
        resetAngle: reset,
        cueGood: good,
        cueBad: bad,
      )
    };
  }

  /// CURL pattern: Elbow angle tight
  static Map<String, ExerciseRule> _curl(List<String> ids, double trigger, double reset, String good, String bad) {
    return {
      for (var id in ids) id: ExerciseRule(
        id: id,
        name: _formatName(id),
        pattern: MovementPattern.curl,
        targetA: _sh,
        targetB: _wr,
        jointA: _sh,
        jointVertex: _el,
        jointB: _wr,
        triggerAngle: trigger,
        resetAngle: reset,
        cueGood: good,
        cueBad: bad,
      )
    };
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
