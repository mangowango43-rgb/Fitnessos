import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

/// =============================================================================
/// THE UNICORN ENGINE - FIXED REFERENCES
/// =============================================================================
/// 
/// FIXES:
/// 1. Squat ruler = HIP-TO-HIP width (not shoulders - shoulders move with barbell)
/// 2. Push-up = Track SHOULDER Y-POSITION dropping (vertical movement visible from any angle)
/// 3. Deadlift = Hip angle (already working)
/// =============================================================================

enum RepState { ready, goingDown, down, goingUp, up }

enum MovementPattern { squat, hinge, push, pull, curl }

class ExerciseRule {
  final String id;
  final String name;
  final MovementPattern pattern;
  
  // For PROPORTION tracking
  final PoseLandmarkType targetA;
  final PoseLandmarkType targetB;
  final double triggerPercent;
  final double resetPercent;
  
  // For ANGLE tracking
  final PoseLandmarkType? jointA;
  final PoseLandmarkType? jointVertex;
  final PoseLandmarkType? jointB;
  final double triggerAngle;
  final double resetAngle;
  
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
  double _baselineShoulderY = 0;  // For push-ups: starting shoulder height
  
  // Current values
  double _currentPercentage = 100;
  double _currentAngle = 180;
  double _smoothedPercentage = 100;
  double _smoothedAngle = 180;
  double _smoothedShoulderY = 0;
  double _contractionRatio = 2.0;  // For push-ups: arm length / upper arm length
  
  // PUSH-UP: Nose drop tracking
  double _baselineNoseWristDiff = 0;  // Starting difference between nose Y and wrist Y
  double _currentNoseWristDiff = 0;   // Current difference
  double _smoothedNoseWristDiff = 0;
  
  // Anti-ghost
  static const double _smoothingFactor = 0.3;
  DateTime? _intentTimer;
  DateTime _lastRepTime = DateTime.now();  // Anti-rapid-fire for push-ups
  static const int _intentDelayMs = 250;   // Increased to 250ms
  
  RepCounter(this.rule);
  
  bool get isLocked => _baselineCaptured;
  int get repCount => _repCount;
  String get feedback => _feedback;
  double get currentPercentage => _currentPercentage;
  RepState get state => _state;
  
  /// Charge progress for power gauge (0.0 to 1.0)
  double get chargeProgress {
    // Convert percentage to 0-1 range (100% = 0, triggerPercent = 1.0)
    double trigger = rule.triggerPercent * 100;
    double progress = (100 - _currentPercentage) / (100 - trigger);
    return progress.clamp(0.0, 1.0);
  }

  /// 3D Angle calculation
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

  /// 3D Distance
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
    
    // HIP-TO-HIP RULER (the fix - hips don't move when holding barbell)
    final lHip = map[PoseLandmarkType.leftHip];
    final rHip = map[PoseLandmarkType.rightHip];
    
    if (lHip != null && rHip != null && lHip.likelihood > 0.5 && rHip.likelihood > 0.5) {
      _baselineRuler = _dist3D(lHip, rHip);
    } else {
      _baselineRuler = _baselineTarget;
    }
    
    // For PUSH pattern: capture shoulder Y position (height from ground)
    final lSh = map[PoseLandmarkType.leftShoulder];
    final rSh = map[PoseLandmarkType.rightShoulder];
    if (lSh != null && rSh != null) {
      _baselineShoulderY = (lSh.y + rSh.y) / 2;  // Average shoulder Y
      _smoothedShoulderY = _baselineShoulderY;
    }
    
    // PUSH-UP: Capture nose to wrist Y difference (nose should be above wrists at start)
    final nose = map[PoseLandmarkType.nose];
    final lWr = map[PoseLandmarkType.leftWrist];
    final rWr = map[PoseLandmarkType.rightWrist];
    if (nose != null && lWr != null && rWr != null) {
      double avgWristY = (lWr.y + rWr.y) / 2;
      _baselineNoseWristDiff = avgWristY - nose.y;  // Positive = nose is above wrists
      _smoothedNoseWristDiff = _baselineNoseWristDiff;
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
    
    // HIP-TO-HIP ruler (fixed reference)
    double currentRuler = _baselineRuler;
    final lHip = map[PoseLandmarkType.leftHip];
    final rHip = map[PoseLandmarkType.rightHip];
    if (lHip != null && rHip != null && lHip.likelihood > 0.5 && rHip.likelihood > 0.5) {
      currentRuler = _dist3D(lHip, rHip);
    }
    
    if (currentRuler < 0.01) currentRuler = _baselineRuler;
    
    // Proportion calculation
    double baselineRatio = _baselineTarget / _baselineRuler;
    double currentRatio = currentTarget / currentRuler;
    double rawPercentage = (currentRatio / baselineRatio) * 100;
    
    _smoothedPercentage = (_smoothingFactor * rawPercentage) + ((1 - _smoothingFactor) * _smoothedPercentage);
    _currentPercentage = _smoothedPercentage.clamp(0, 150);
    
    // Angle calculation (for hinge/pull/curl)
    // For PUSH pattern: Check BOTH arms and use the one with better visibility
    double rawAngle = 180;
    if (rule.jointA != null && rule.jointVertex != null && rule.jointB != null) {
      final jA = map[rule.jointA];
      final jV = map[rule.jointVertex];
      final jB = map[rule.jointB];
      
      if (jA != null && jV != null && jB != null) {
        rawAngle = _calculateAngle(jA, jV, jB);
      }
    }
    
    // PUSH-UP FIX: Track BOTH arms and use the better one
    if (rule.pattern == MovementPattern.push) {
      final lShoulder = map[PoseLandmarkType.leftShoulder];
      final lElbow = map[PoseLandmarkType.leftElbow];
      final lWrist = map[PoseLandmarkType.leftWrist];
      final rShoulder = map[PoseLandmarkType.rightShoulder];
      final rElbow = map[PoseLandmarkType.rightElbow];
      final rWrist = map[PoseLandmarkType.rightWrist];
      
      double leftAngle = 180;
      double rightAngle = 180;
      double leftLikelihood = 0;
      double rightLikelihood = 0;
      
      // Calculate left arm angle
      if (lShoulder != null && lElbow != null && lWrist != null) {
        leftAngle = _calculateAngle(lShoulder, lElbow, lWrist);
        leftLikelihood = (lShoulder.likelihood + lElbow.likelihood + lWrist.likelihood) / 3;
      }
      
      // Calculate right arm angle
      if (rShoulder != null && rElbow != null && rWrist != null) {
        rightAngle = _calculateAngle(rShoulder, rElbow, rWrist);
        rightLikelihood = (rShoulder.likelihood + rElbow.likelihood + rWrist.likelihood) / 3;
      }
      
      // Use the arm with BETTER visibility (higher likelihood)
      // OR use the more bent angle (lower value = more bent)
      if (leftLikelihood > 0.3 || rightLikelihood > 0.3) {
        if (leftLikelihood > rightLikelihood) {
          rawAngle = leftAngle;
        } else {
          rawAngle = rightAngle;
        }
        // Actually, use the MORE BENT angle (smaller value) - that's the working arm
        rawAngle = leftAngle < rightAngle ? leftAngle : rightAngle;
      }
    }
    
    _smoothedAngle = (_smoothingFactor * rawAngle) + ((1 - _smoothingFactor) * _smoothedAngle);
    _currentAngle = _smoothedAngle;
    
    // Shoulder Y tracking (for push-ups)
    final lSh = map[PoseLandmarkType.leftShoulder];
    final rSh = map[PoseLandmarkType.rightShoulder];
    double currentShoulderY = _baselineShoulderY;
    if (lSh != null && rSh != null) {
      double rawShoulderY = (lSh.y + rSh.y) / 2;
      _smoothedShoulderY = (_smoothingFactor * rawShoulderY) + ((1 - _smoothingFactor) * _smoothedShoulderY);
      currentShoulderY = _smoothedShoulderY;
    }
    
    // PUSH-UP FIX: Contraction ratio (arm length / upper arm length)
    // Upper arm bone NEVER changes - it's your actual bone
    final lEl = map[PoseLandmarkType.leftElbow];
    final lWr = map[PoseLandmarkType.leftWrist];
    final rWr = map[PoseLandmarkType.rightWrist];
    if (lSh != null && lEl != null && lWr != null) {
      double armLength = _dist3D(lSh, lWr);       // Full arm: shoulder to wrist
      double upperArm = _dist3D(lSh, lEl);        // Fixed bone: shoulder to elbow
      if (upperArm > 0.01) {
        double rawRatio = armLength / upperArm;
        _contractionRatio = (_smoothingFactor * rawRatio) + ((1 - _smoothingFactor) * _contractionRatio);
      }
    }
    
    // PUSH-UP: Track nose dropping toward wrists
    final nose = map[PoseLandmarkType.nose];
    if (nose != null && lWr != null && rWr != null) {
      double avgWristY = (lWr.y + rWr.y) / 2;
      double rawDiff = avgWristY - nose.y;  // Positive = nose above wrists, shrinks as you go down
      _smoothedNoseWristDiff = (_smoothingFactor * rawDiff) + ((1 - _smoothingFactor) * _smoothedNoseWristDiff);
      _currentNoseWristDiff = _smoothedNoseWristDiff;
    }
    
    // Check down/reset based on pattern
    bool isDown = _checkIsDown(currentShoulderY);
    bool isReset = _checkIsReset(currentShoulderY);
    
    switch (_state) {
      case RepState.ready:
      case RepState.up:
        if (isDown) {
          _intentTimer ??= DateTime.now();
          if (DateTime.now().difference(_intentTimer!).inMilliseconds > _intentDelayMs) {
            _state = RepState.down;
            _feedback = rule.cueGood;
            _intentTimer = null;
          } else {
            // Still waiting for intent confirmation - show as going down
            _state = RepState.goingDown;
          }
        } else {
          _intentTimer = null;
          _state = RepState.ready;
          if (!isReset && _currentPercentage < 95) {
            _feedback = rule.cueBad;
          } else {
            _feedback = "";
          }
        }
        return false;
        
      case RepState.goingDown:
        if (isDown) {
          _intentTimer ??= DateTime.now();
          if (DateTime.now().difference(_intentTimer!).inMilliseconds > _intentDelayMs) {
            _state = RepState.down;
            _feedback = rule.cueGood;
            _intentTimer = null;
          }
        } else {
          // Moved back up before confirming
          _intentTimer = null;
          _state = RepState.ready;
        }
        return false;

      case RepState.down:
        if (isReset) {
          _state = RepState.goingUp;
        }
        return false;
        
      case RepState.goingUp:
        if (isReset) {
          // ANTI-RAPID-FIRE: Must wait 500ms between reps
          if (DateTime.now().difference(_lastRepTime).inMilliseconds > 500) {
            _state = RepState.up;
            _repCount++;  // COUNT REP WHEN BACK UP
            _lastRepTime = DateTime.now();
            _feedback = "";
            return true;  // REP COUNTED
          }
        } else {
          // Went back down
          _state = RepState.down;
        }
        return false;
    }
  }

  bool _checkIsDown(double currentShoulderY) {
    switch (rule.pattern) {
      case MovementPattern.squat:
        // Proportion: hip-to-ankle drops
        return _currentPercentage <= (rule.triggerPercent * 100);
        
      case MovementPattern.hinge:
        // Angle: hip angle closes
        return _currentAngle <= rule.triggerAngle;
        
      case MovementPattern.push:
        // ELBOW ANGLE: Now tracking BOTH arms, using the more bent one
        // When arm bends to 90 degrees or less = you're down
        return _currentAngle <= 110;
        
      case MovementPattern.pull:
        return _currentAngle <= rule.triggerAngle;
        
      case MovementPattern.curl:
        return _currentAngle <= rule.triggerAngle;
    }
  }

  bool _checkIsReset(double currentShoulderY) {
    switch (rule.pattern) {
      case MovementPattern.squat:
        return _currentPercentage >= (rule.resetPercent * 100);
        
      case MovementPattern.hinge:
        return _currentAngle >= rule.resetAngle;
        
      case MovementPattern.push:
        // ELBOW ANGLE: Arms straighten back out
        return _currentAngle >= 150;
        
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
/// EXERCISE LIBRARY
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
    // SQUAT PATTERN - Hip-to-ankle with HIP-WIDTH ruler
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
    // HINGE PATTERN - Hip angle
    // =========================================================================
    ..._hinge(['deadlift', 'sumo_deadlift'], 
        105, 165, "Lockout!", "Hips forward!"),
    ..._hinge(['romanian_deadlift', 'single_leg_deadlift', 'stiff_leg_deadlift'], 
        100, 160, "Hamstrings!", "Flat back!"),
    ..._hinge(['kettlebell_swings', 'cable_pullthrough'], 
        110, 170, "Snap!", "Hips drive!"),
    ..._hinge(['glute_bridge', 'hip_thrust', 'single_leg_glute_bridge', 'banded_glute_bridge', 'frog_pumps'], 
        160, 110, "Squeeze!", "Hips up!"),
    ..._hinge(['good_mornings'],
        100, 160, "Feel it!", "Hinge!"),

    // =========================================================================
    // PUSH PATTERN - Shoulder Y drop OR elbow angle
    // =========================================================================
    ..._push(['pushups', 'push_ups', 'wide_pushups', 'diamond_pushups', 'close_grip_push_ups'], 
        95, 155, "Perfect!", "Go lower!"),
    ..._push(['bench_press', 'incline_press', 'decline_press', 'dumbbell_press', 'close_grip_bench'], 
        90, 150, "Good depth!", "Touch chest!"),
    ..._push(['tricep_dips', 'tricep_dips_chair', 'dips_chest'], 
        90, 155, "Nice dip!", "Get to 90!"),
    ..._push(['overhead_press', 'shoulder_press', 'arnold_press', 'seated_db_press', 'pike_push_ups'], 
        155, 90, "Lockout!", "Press up!"),
    ..._push(['plank_to_pushup'],
        95, 155, "Up!", "Down!"),
    ..._push(['chest_flys', 'cable_crossovers', 'dumbbell_flyes'],
        95, 155, "Squeeze!", "Together!"),

    // =========================================================================
    // PULL PATTERN - Elbow angle
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
    // CURL PATTERN - Elbow angle tight
    // =========================================================================
    ..._curl(['bicep_curls', 'hammer_curls', 'barbell_curl', 'ez_bar_curl'], 
        50, 145, "Full curl!", "Squeeze!"),
    ..._curl(['preacher_curls', 'concentration_curls', 'cable_curls', 'incline_curls'], 
        45, 140, "Peak!", "Control!"),
    ..._curl(['tricep_extensions', 'overhead_tricep', 'tricep_pushdown', 'skull_crushers', 'tricep_kickbacks'], 
        150, 85, "Lockout!", "Extend!"),

    // =========================================================================
    // ADDITIONAL - Mapped to closest pattern
    // =========================================================================
    
    // Core
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

    // Cardio
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

    // Booty
    ..._hinge(['donkey_kicks', 'donkey_kick_pulses', 'banded_kickback'], 
        155, 100, "Kick!", "Squeeze glute!"),
    ..._squat(['fire_hydrants', 'banded_fire_hydrant', 'clamshells', 'banded_clamshell'],
        0.80, 0.92, "Open!", "Control!"),

    // Shoulders
    ..._push(['lateral_raises', 'front_raises', 'cable_lateral_raise'],
        150, 90, "Arms up!", "To shoulders!"),
    ..._push(['rear_delt_flys', 'upright_rows'],
        100, 150, "Pull!", "Elbows high!"),
    ..._push(['shrugs'],
        170, 160, "High!", "Squeeze!"),

    // Stretches
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

  static Map<String, ExerciseRule> _push(List<String> ids, double trigAngle, double resetAngle, String good, String bad) {
    return {
      for (var id in ids) id: ExerciseRule(
        id: id,
        name: _formatName(id),
        pattern: MovementPattern.push,
        targetA: _sh,    // Left shoulder
        targetB: _rsh,   // Right shoulder - tracking WIDTH
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
