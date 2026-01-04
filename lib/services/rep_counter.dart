import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

/// =============================================================================
/// ANGLE-BASED REP COUNTER - PROPER BIOMECHANICS
/// =============================================================================
/// 
/// Uses JOINT ANGLES not arbitrary proportions.
/// A push-up is elbow going from 180° to 90°. That's a fact.
/// A squat is knee going from 180° to 90°. That's a fact.
/// =============================================================================

enum RepState { ready, down, up }

enum TrackingMethod { angle, proportion }

class ExerciseRule {
  final String id;
  final String name;
  final TrackingMethod method;
  
  // For ANGLE tracking: 3 points define the angle (vertex is middle point)
  final PoseLandmarkType? anglePointA;  // First point
  final PoseLandmarkType? angleVertex;   // Joint (where angle is measured)
  final PoseLandmarkType? anglePointB;  // Third point
  
  // For PROPORTION tracking (backup for exercises where angles don't work)
  final PoseLandmarkType? targetA;
  final PoseLandmarkType? targetB;
  final PoseLandmarkType? rulerA;
  final PoseLandmarkType? rulerB;
  final bool targetShrinks;
  
  // Thresholds
  final double triggerAngle;    // Angle to hit for "down" position (degrees)
  final double resetAngle;      // Angle to return to for rep complete (degrees)
  final double triggerPercent;  // For proportion method
  final double resetPercent;    // For proportion method
  
  final String cueGood;
  final String cueBad;

  const ExerciseRule({
    required this.id,
    required this.name,
    this.method = TrackingMethod.angle,
    // Angle points
    this.anglePointA,
    this.angleVertex,
    this.anglePointB,
    // Proportion points
    this.targetA,
    this.targetB,
    this.rulerA,
    this.rulerB,
    this.targetShrinks = true,
    // Angle thresholds (degrees)
    this.triggerAngle = 90,
    this.resetAngle = 150,
    // Proportion thresholds
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
  
  // For angle tracking
  double _currentAngle = 180;
  double _smoothedAngle = 180;
  
  // For proportion tracking
  double _baselineRatio = 0;
  double _smoothedRatio = 0;
  double _currentPercentage = 100;
  
  // Anti-ghost rep
  static const double _smoothingFactor = 0.3;
  DateTime? _intentTimer;
  static const int _intentDelayMs = 120;
  
  RepCounter(this.rule);
  
  bool get isLocked => _baselineCaptured;
  int get repCount => _repCount;
  String get feedback => _feedback;
  double get currentPercentage => rule.method == TrackingMethod.angle 
      ? _angleToPercentage(_smoothedAngle) 
      : _currentPercentage;
  RepState get state => _state;
  double get currentAngle => _smoothedAngle;

  /// Calculate angle between three points (in degrees)
  /// Vertex is the middle point where angle is measured
  double _calculateAngle(PoseLandmark a, PoseLandmark vertex, PoseLandmark b) {
    // Vector from vertex to point A
    double vaX = a.x - vertex.x;
    double vaY = a.y - vertex.y;
    double vaZ = a.z - vertex.z;
    
    // Vector from vertex to point B
    double vbX = b.x - vertex.x;
    double vbY = b.y - vertex.y;
    double vbZ = b.z - vertex.z;
    
    // Dot product
    double dot = vaX * vbX + vaY * vbY + vaZ * vbZ;
    
    // Magnitudes
    double magA = math.sqrt(vaX * vaX + vaY * vaY + vaZ * vaZ);
    double magB = math.sqrt(vbX * vbX + vbY * vbY + vbZ * vbZ);
    
    if (magA < 0.001 || magB < 0.001) return 180;
    
    // Angle in radians, then convert to degrees
    double cosAngle = (dot / (magA * magB)).clamp(-1.0, 1.0);
    double angleRad = math.acos(cosAngle);
    return angleRad * 180 / math.pi;
  }

  /// Convert angle to percentage for UI (180° = 100%, triggerAngle = 0%)
  double _angleToPercentage(double angle) {
    double range = 180 - rule.triggerAngle;
    if (range <= 0) return 100;
    double progress = (180 - angle) / range * 100;
    return progress.clamp(0, 150);
  }

  /// 3D distance for proportion method
  double _dist3D(PoseLandmark a, PoseLandmark b) {
    return math.sqrt(
      math.pow(b.x - a.x, 2) + 
      math.pow(b.y - a.y, 2) + 
      math.pow(b.z - a.z, 2)
    );
  }

  void captureBaseline(List<PoseLandmark> landmarks) {
    final map = {for (var lm in landmarks) lm.type: lm};
    
    if (rule.method == TrackingMethod.angle) {
      // For angle method, just verify points are visible
      final a = map[rule.anglePointA];
      final v = map[rule.angleVertex];
      final b = map[rule.anglePointB];
      
      if (a == null || v == null || b == null) {
        _feedback = "Body not in frame";
        return;
      }
      
      _smoothedAngle = _calculateAngle(a, v, b);
      _baselineCaptured = true;
      _state = RepState.ready;
      _feedback = "LOCKED";
      
    } else {
      // Proportion method
      final tA = map[rule.targetA];
      final tB = map[rule.targetB];
      final rA = map[rule.rulerA];
      final rB = map[rule.rulerB];
      
      if (tA == null || tB == null || rA == null || rB == null) {
        _feedback = "Body not in frame";
        return;
      }
      
      double targetDist = _dist3D(tA, tB);
      double rulerDist = _dist3D(rA, rB);
      
      if (rulerDist < 0.01) {
        _feedback = "Move back";
        return;
      }
      
      _baselineRatio = targetDist / rulerDist;
      _smoothedRatio = _baselineRatio;
      _baselineCaptured = true;
      _state = RepState.ready;
      _feedback = "LOCKED";
    }
  }

  bool processFrame(List<PoseLandmark> landmarks) {
    if (!_baselineCaptured) {
      _feedback = "Waiting for lock";
      return false;
    }
    
    final map = {for (var lm in landmarks) lm.type: lm};
    
    if (rule.method == TrackingMethod.angle) {
      return _processAngle(map);
    } else {
      return _processProportion(map);
    }
  }

  bool _processAngle(Map<PoseLandmarkType, PoseLandmark> map) {
    final a = map[rule.anglePointA];
    final v = map[rule.angleVertex];
    final b = map[rule.anglePointB];
    
    if (a == null || v == null || b == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    double rawAngle = _calculateAngle(a, v, b);
    _smoothedAngle = (_smoothingFactor * rawAngle) + ((1 - _smoothingFactor) * _smoothedAngle);
    _currentAngle = _smoothedAngle;
    
    switch (_state) {
      case RepState.ready:
      case RepState.up:
        // Going DOWN: angle decreases (180 -> 90)
        if (_smoothedAngle <= rule.triggerAngle) {
          _intentTimer ??= DateTime.now();
          if (DateTime.now().difference(_intentTimer!).inMilliseconds > _intentDelayMs) {
            _state = RepState.down;
            _feedback = rule.cueGood;
            _intentTimer = null;
          }
        } else {
          _intentTimer = null;
          if (_smoothedAngle < rule.resetAngle) {
            _feedback = rule.cueBad;
          } else {
            _feedback = "";
          }
        }
        return false;

      case RepState.down:
        // Coming UP: angle increases (90 -> 180)
        if (_smoothedAngle >= rule.resetAngle) {
          _state = RepState.up;
          _repCount++;
          _feedback = "";
          return true;
        }
        return false;
    }
  }

  bool _processProportion(Map<PoseLandmarkType, PoseLandmark> map) {
    // Use shoulder width as ruler for front view
    double lShVis = map[PoseLandmarkType.leftShoulder]?.likelihood ?? 0;
    double rShVis = map[PoseLandmarkType.rightShoulder]?.likelihood ?? 0;
    bool isFrontView = lShVis > 0.6 && rShVis > 0.6;
    
    PoseLandmark? rA, rB;
    if (isFrontView) {
      rA = map[PoseLandmarkType.leftShoulder];
      rB = map[PoseLandmarkType.rightShoulder];
    } else {
      rA = map[rule.rulerA];
      rB = map[rule.rulerB];
    }
    
    final tA = map[rule.targetA];
    final tB = map[rule.targetB];
    
    if (tA == null || tB == null || rA == null || rB == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    double currentTarget = _dist3D(tA, tB);
    double currentRuler = _dist3D(rA, rB);
    
    if (currentRuler < 0.01) return false;
    
    double rawRatio = currentTarget / currentRuler;
    _smoothedRatio = (_smoothingFactor * rawRatio) + ((1 - _smoothingFactor) * _smoothedRatio);
    
    _currentPercentage = rule.targetShrinks 
        ? (_smoothedRatio / _baselineRatio) * 100 
        : (_baselineRatio / _smoothedRatio) * 100;
    
    _currentPercentage = _currentPercentage.clamp(0, 150);
    
    final trigger = rule.triggerPercent * 100;
    final reset = rule.resetPercent * 100;

    switch (_state) {
      case RepState.ready:
      case RepState.up:
        if (_currentPercentage <= trigger) {
          _intentTimer ??= DateTime.now();
          if (DateTime.now().difference(_intentTimer!).inMilliseconds > _intentDelayMs) {
            _state = RepState.down;
            _feedback = rule.cueGood;
            _intentTimer = null;
          }
        } else {
          _intentTimer = null;
          if (_currentPercentage < reset) {
            _feedback = rule.cueBad;
          } else {
            _feedback = "";
          }
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

  void reset() {
    _repCount = 0;
    _state = RepState.ready;
    _feedback = "";
    _intentTimer = null;
  }
}

/// =============================================================================
/// EXERCISE LIBRARY - BIOMECHANICALLY CORRECT
/// =============================================================================

class ExerciseRules {
  // Landmarks
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
    // PUSH EXERCISES - Track ELBOW ANGLE
    // Elbow: 180° (straight arm) -> 90° (bent) -> back to 160°
    // =========================================================================
    ...{
      for (var id in ['pushups', 'push_ups', 'wide_pushups', 'diamond_pushups', 'close_grip_push_ups'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,      // Shoulder
          angleVertex: _el,      // Elbow (the joint we measure)
          anglePointB: _wr,      // Wrist
          triggerAngle: 90,      // Arms bent to 90°
          resetAngle: 160,       // Arms extended back to 160°
          cueGood: "Perfect!",
          cueBad: "Lower!",
        ),
    },
    
    ...{
      for (var id in ['bench_press', 'incline_press', 'decline_press', 'close_grip_bench', 'dumbbell_press'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,
          angleVertex: _el,
          anglePointB: _wr,
          triggerAngle: 85,      // Touch chest = deeper bend
          resetAngle: 155,
          cueGood: "Good depth!",
          cueBad: "Touch chest!",
        ),
    },
    
    ...{
      for (var id in ['tricep_dips', 'tricep_dips_chair', 'dips_chest'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,
          angleVertex: _el,
          anglePointB: _wr,
          triggerAngle: 90,      // 90° at bottom
          resetAngle: 160,
          cueGood: "Nice dip!",
          cueBad: "Get to 90!",
        ),
    },

    // =========================================================================
    // SQUAT EXERCISES - Track KNEE ANGLE
    // Knee: 180° (standing) -> 90° (parallel) -> back to 160°
    // =========================================================================
    ...{
      for (var id in ['squats', 'air_squats', 'goblet_squats', 'front_squat', 'back_squat'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _hp,      // Hip
          angleVertex: _kn,      // Knee (the joint we measure)
          anglePointB: _ak,      // Ankle
          triggerAngle: 100,     // Parallel = ~100° (not full 90 for normal people)
          resetAngle: 160,       // Standing
          cueGood: "Depth!",
          cueBad: "Hit parallel!",
        ),
    },
    
    ...{
      for (var id in ['sumo_squat', 'jump_squats', 'banded_squat', 'box_jumps'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _hp,
          angleVertex: _kn,
          anglePointB: _ak,
          triggerAngle: 105,     // Slightly easier threshold
          resetAngle: 155,
          cueGood: "Explode!",
          cueBad: "Lower!",
        ),
    },
    
    ...{
      for (var id in ['wall_sits'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _hp,
          angleVertex: _kn,
          anglePointB: _ak,
          triggerAngle: 95,      // Hold at 90°
          resetAngle: 100,       // Barely move to "reset" (it's isometric)
          cueGood: "Hold!",
          cueBad: "90 degrees!",
        ),
    },

    // =========================================================================
    // LUNGE EXERCISES - Track FRONT KNEE ANGLE
    // =========================================================================
    ...{
      for (var id in ['lunges', 'walking_lunges', 'reverse_lunges', 'curtsy_lunges', 'jump_lunges'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _hp,
          angleVertex: _kn,
          anglePointB: _ak,
          triggerAngle: 100,     // Front knee at ~90°
          resetAngle: 155,
          cueGood: "Great step!",
          cueBad: "Deeper!",
        ),
    },
    
    ...{
      for (var id in ['bulgarian_split_squat', 'step_ups'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _hp,
          angleVertex: _kn,
          anglePointB: _ak,
          triggerAngle: 95,
          resetAngle: 160,
          cueGood: "Strong!",
          cueBad: "Full depth!",
        ),
    },

    // =========================================================================
    // CURL EXERCISES - Track ELBOW ANGLE (closing)
    // Elbow: 170° (arm straight) -> 40° (full curl) -> back to 140°
    // =========================================================================
    ...{
      for (var id in ['bicep_curls', 'hammer_curls', 'barbell_curl', 'cable_curls', 'preacher_curls', 'concentration_curls'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,      // Shoulder
          angleVertex: _el,      // Elbow
          anglePointB: _wr,      // Wrist
          triggerAngle: 45,      // Full curl = elbow closed to ~45°
          resetAngle: 140,       // Arm extended back out
          cueGood: "Full curl!",
          cueBad: "Squeeze!",
        ),
    },

    // =========================================================================
    // TRICEP EXTENSIONS - Track ELBOW ANGLE (opening)
    // Start bent ~70°, extend to ~160°
    // =========================================================================
    ...{
      for (var id in ['tricep_extensions', 'overhead_tricep', 'tricep_pushdown', 'skull_crushers'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,
          angleVertex: _el,
          anglePointB: _wr,
          triggerAngle: 155,     // Arm extended (opposite of curl)
          resetAngle: 80,        // Arm bent to start again
          cueGood: "Lockout!",
          cueBad: "Extend!",
        ),
    },

    // =========================================================================
    // PULL EXERCISES - Track ELBOW ANGLE (closing from above)
    // =========================================================================
    ...{
      for (var id in ['pull_ups', 'pullups', 'lat_pulldowns', 'lat_pulldown', 'chin_ups'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,
          angleVertex: _el,
          anglePointB: _wr,
          triggerAngle: 70,      // Arms pulled in
          resetAngle: 150,       // Arms extended
          cueGood: "Chin up!",
          cueBad: "Full pull!",
        ),
    },
    
    ...{
      for (var id in ['bent_over_rows', 'cable_rows', 't_bar_rows', 'single_arm_db_row', 'renegade_rows'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,
          angleVertex: _el,
          anglePointB: _wr,
          triggerAngle: 75,
          resetAngle: 145,
          cueGood: "Squeeze!",
          cueBad: "Pull higher!",
        ),
    },

    // =========================================================================
    // SHOULDER PRESS - Track ELBOW ANGLE (opening upward)
    // =========================================================================
    ...{
      for (var id in ['overhead_press', 'shoulder_press', 'arnold_press', 'seated_db_press', 'pike_push_ups'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,
          angleVertex: _el,
          anglePointB: _wr,
          triggerAngle: 160,     // Arms extended overhead
          resetAngle: 90,        // Arms at shoulder level
          cueGood: "Lockout!",
          cueBad: "Press up!",
        ),
    },

    // =========================================================================
    // LATERAL RAISES - Use PROPORTION (angle doesn't work well here)
    // =========================================================================
    ...{
      for (var id in ['lateral_raises', 'front_raises', 'cable_lateral_raise'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.proportion,
          targetA: _wr,
          targetB: _hp,
          rulerA: _sh,
          rulerB: _hp,
          targetShrinks: false,  // Distance increases as arms go up
          triggerPercent: 1.3,   // Arms raised = wrist moves away from hip
          resetPercent: 1.1,
          cueGood: "Arms up!",
          cueBad: "To shoulders!",
        ),
    },

    // =========================================================================
    // HINGE EXERCISES - Track HIP ANGLE
    // Hip: 180° (standing) -> 90° (bent over) -> back to 160°
    // =========================================================================
    ...{
      for (var id in ['deadlift', 'sumo_deadlift', 'romanian_deadlift', 'single_leg_deadlift'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,      // Shoulder
          angleVertex: _hp,      // Hip (the hinge point)
          anglePointB: _kn,      // Knee
          triggerAngle: 100,     // Hip hinged
          resetAngle: 165,       // Standing tall
          cueGood: "Lockout!",
          cueBad: "Hips forward!",
        ),
    },
    
    ...{
      for (var id in ['kettlebell_swings', 'cable_pullthrough'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,
          angleVertex: _hp,
          anglePointB: _kn,
          triggerAngle: 110,
          resetAngle: 170,
          cueGood: "Snap!",
          cueBad: "Hips drive!",
        ),
    },

    // =========================================================================
    // CORE - CRUNCH/SIT-UP - Track HIP ANGLE (torso to thigh)
    // =========================================================================
    ...{
      for (var id in ['sit_ups', 'situps', 'crunches', 'decline_sit_up', 'cable_crunch'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,      // Shoulder
          angleVertex: _hp,      // Hip
          anglePointB: _kn,      // Knee
          triggerAngle: 70,      // Crunched up
          resetAngle: 130,       // Lying back
          cueGood: "Squeeze!",
          cueBad: "Crunch up!",
        ),
    },

    // =========================================================================
    // LEG RAISES - Track HIP ANGLE (legs to torso)
    // =========================================================================
    ...{
      for (var id in ['leg_raises', 'hanging_leg_raise'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,
          angleVertex: _hp,
          anglePointB: _ak,
          triggerAngle: 90,      // Legs up to 90°
          resetAngle: 150,       // Legs down
          cueGood: "Legs up!",
          cueBad: "Higher!",
        ),
    },

    // =========================================================================
    // MOUNTAIN CLIMBERS - Track KNEE coming to chest (proportion)
    // =========================================================================
    ...{
      for (var id in ['mountain_climbers', 'bicycle_crunches'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.proportion,
          targetA: _kn,
          targetB: _sh,
          rulerA: _sh,
          rulerB: _hp,
          targetShrinks: true,
          triggerPercent: 0.70,
          resetPercent: 0.90,
          cueGood: "Fast!",
          cueBad: "Knees up!",
        ),
    },

    // =========================================================================
    // PLANK - Track body alignment (proportion - should stay straight)
    // =========================================================================
    ...{
      for (var id in ['plank', 'plank_hold', 'side_plank'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.proportion,
          targetA: _sh,
          targetB: _ak,
          rulerA: _sh,
          rulerB: _hp,
          targetShrinks: false,
          triggerPercent: 0.95,  // Almost no movement needed
          resetPercent: 0.98,
          cueGood: "Hold!",
          cueBad: "Stay flat!",
        ),
    },

    // =========================================================================
    // GLUTE BRIDGE / HIP THRUST - Track HIP EXTENSION
    // =========================================================================
    ...{
      for (var id in ['glute_bridge', 'single_leg_glute_bridge', 'hip_thrust', 'glute_bridge_hold', 'banded_glute_bridge', 'frog_pumps'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,      // Shoulder (on ground)
          angleVertex: _hp,      // Hip (what we're thrusting)
          anglePointB: _kn,      // Knee
          triggerAngle: 170,     // Hips fully extended (flat line)
          resetAngle: 120,       // Hips dropped
          cueGood: "Squeeze!",
          cueBad: "Hips up!",
        ),
    },

    // =========================================================================
    // DONKEY KICKS / FIRE HYDRANTS - Track LEG ANGLE
    // =========================================================================
    ...{
      for (var id in ['donkey_kicks', 'donkey_kick_pulses', 'banded_kickback'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _sh,
          angleVertex: _hp,
          anglePointB: _kn,
          triggerAngle: 160,     // Leg kicked back
          resetAngle: 100,       // Knee tucked
          cueGood: "Kick!",
          cueBad: "Squeeze glute!",
        ),
    },
    
    ...{
      for (var id in ['fire_hydrants', 'banded_fire_hydrant', 'clamshells', 'banded_clamshell'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.proportion,
          targetA: _kn,
          targetB: _rkn,
          rulerA: _hp,
          rulerB: _rhp,
          targetShrinks: false,  // Knees move apart
          triggerPercent: 1.4,
          resetPercent: 1.1,
          cueGood: "Open!",
          cueBad: "Wider!",
        ),
    },

    // =========================================================================
    // CARDIO - BURPEES (full body - use proportion)
    // =========================================================================
    ...{
      for (var id in ['burpees', 'sprawls'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.proportion,
          targetA: _sh,
          targetB: _ak,
          rulerA: _sh,
          rulerB: _hp,
          targetShrinks: true,
          triggerPercent: 0.65,
          resetPercent: 0.90,
          cueGood: "Explode!",
          cueBad: "Chest down!",
        ),
    },
    
    ...{
      for (var id in ['jumping_jacks', 'star_jumps'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.proportion,
          targetA: _wr,
          targetB: _rwr,
          rulerA: _sh,
          rulerB: _rsh,
          targetShrinks: false,
          triggerPercent: 2.5,   // Arms spread wide
          resetPercent: 1.5,
          cueGood: "Jump!",
          cueBad: "Arms wide!",
        ),
    },
    
    ...{
      for (var id in ['high_knees', 'butt_kicks', 'tuck_jumps'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.angle,
          anglePointA: _hp,
          angleVertex: _kn,
          anglePointB: _ak,
          triggerAngle: 60,      // Knee very bent (high)
          resetAngle: 140,
          cueGood: "Higher!",
          cueBad: "Knees up!",
        ),
    },

    // =========================================================================
    // SUPERMAN / DEAD BUG
    // =========================================================================
    ...{
      for (var id in ['superman_raises', 'superman', 'dead_bug'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.proportion,
          targetA: _wr,
          targetB: _ak,
          rulerA: _sh,
          rulerB: _hp,
          targetShrinks: false,
          triggerPercent: 1.3,
          resetPercent: 1.1,
          cueGood: "Fly!",
          cueBad: "Extend!",
        ),
    },

    // =========================================================================
    // STRETCHES - Generally use proportion or just validate position
    // =========================================================================
    ...{
      for (var id in ['childs_pose', 'cat_cow', 'worlds_greatest_stretch'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.proportion,
          targetA: _sh,
          targetB: _hp,
          rulerA: _hp,
          rulerB: _kn,
          targetShrinks: true,
          triggerPercent: 0.70,
          resetPercent: 0.90,
          cueGood: "Breathe!",
          cueBad: "Deeper!",
        ),
    },
    
    ...{
      for (var id in ['hamstring_stretch', 'quad_stretch', 'hip_flexor_stretch', 'pigeon_pose', 'butterfly_stretch', 'frog_stretch', '90_90_stretch'])
        id: ExerciseRule(
          id: id,
          name: _formatName(id),
          method: TrackingMethod.proportion,
          targetA: _sh,
          targetB: _ak,
          rulerA: _sh,
          rulerB: _hp,
          targetShrinks: true,
          triggerPercent: 0.75,
          resetPercent: 0.90,
          cueGood: "Hold!",
          cueBad: "Stretch!",
        ),
    },
  };

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
