import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

/// =============================================================================
/// PROPORTION-BASED REP COUNTER
/// =============================================================================
/// 
/// Uses RATIOS between body parts instead of angles.
/// Works regardless of phone position/angle because proportions stay constant.

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
    this.triggerPercent = 0.60,
    this.resetPercent = 0.85,
    this.cueGood = "Good!",
    this.cueBad = "Go deeper!",
  });
}

class RepCounter {
  final ExerciseRule rule;
  
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  
  double _baselineTarget = 0;
  double _baselineRuler = 0;
  double _baselineRatio = 0;
  double _currentRatio = 0;
  double _smoothedRatio = 0;
  double _currentPercentage = 100;
  
  static const double _smoothingFactor = 0.3;
  
  RepCounter(this.rule);
  
  bool get isLocked => _baselineCaptured;
  int get repCount => _repCount;
  String get feedback => _feedback;
  double get currentPercentage => _currentPercentage;
  RepState get state => _state;
  
  void captureBaseline(List<PoseLandmark> landmarks) {
    final points = _extractPoints(landmarks);
    if (points == null) {
      _feedback = "Can't see full body";
      return;
    }
    
    _baselineTarget = _distance(points.targetA, points.targetB);
    _baselineRuler = _distance(points.rulerA, points.rulerB);
    
    if (_baselineRuler < 0.01) {
      _feedback = "Move back a bit";
      return;
    }
    
    _baselineRatio = _baselineTarget / _baselineRuler;
    _smoothedRatio = _baselineRatio;
    _baselineCaptured = true;
    _state = RepState.ready;
    _feedback = "LOCKED";
  }
  
  bool processFrame(List<PoseLandmark> landmarks) {
    if (!_baselineCaptured) {
      _feedback = "Waiting for lock";
      return false;
    }
    
    final points = _extractPoints(landmarks);
    if (points == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    final currentTarget = _distance(points.targetA, points.targetB);
    final currentRuler = _distance(points.rulerA, points.rulerB);
    
    if (currentRuler < 0.01) return false;
    
    final rawRatio = currentTarget / currentRuler;
    _smoothedRatio = (_smoothingFactor * rawRatio) + ((1 - _smoothingFactor) * _smoothedRatio);
    _currentRatio = _smoothedRatio;
    
    if (rule.targetShrinks) {
      _currentPercentage = (_currentRatio / _baselineRatio) * 100;
    } else {
      _currentPercentage = (_baselineRatio / _currentRatio) * 100;
    }
    
    _currentPercentage = _currentPercentage.clamp(0, 150);
    
    final triggerThreshold = rule.triggerPercent * 100;
    final resetThreshold = rule.resetPercent * 100;
    
    switch (_state) {
      case RepState.ready:
      case RepState.up:
        if (_currentPercentage <= triggerThreshold) {
          _state = RepState.down;
          _feedback = rule.cueGood;
        } else if (_currentPercentage > triggerThreshold && _currentPercentage < resetThreshold) {
          _feedback = rule.cueBad;
        }
        return false;
        
      case RepState.down:
        if (_currentPercentage >= resetThreshold) {
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
  }
  
  _Points? _extractPoints(List<PoseLandmark> landmarks) {
    final map = {for (var lm in landmarks) lm.type: lm};
    
    final targetA = map[rule.targetA];
    final targetB = map[rule.targetB];
    final rulerA = map[rule.rulerA];
    final rulerB = map[rule.rulerB];
    
    if (targetA == null || targetB == null || rulerA == null || rulerB == null) {
      return null;
    }
    
    const minConfidence = 0.3;
    if (targetA.likelihood < minConfidence || targetB.likelihood < minConfidence ||
        rulerA.likelihood < minConfidence || rulerB.likelihood < minConfidence) {
      return null;
    }
    
    return _Points(
      targetA: Offset(targetA.x, targetA.y),
      targetB: Offset(targetB.x, targetB.y),
      rulerA: Offset(rulerA.x, rulerA.y),
      rulerB: Offset(rulerB.x, rulerB.y),
    );
  }
  
  double _distance(Offset a, Offset b) {
    return math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
  }
}

class _Points {
  final Offset targetA, targetB, rulerA, rulerB;
  _Points({required this.targetA, required this.targetB, required this.rulerA, required this.rulerB});
}

class Offset {
  final double x, y;
  Offset(this.x, this.y);
}

/// =============================================================================
/// ALL 120+ EXERCISE RULES
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

  // CHEST
  static const benchPress = ExerciseRule(id: 'bench_press', name: 'Bench Press', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Good depth!", cueBad: "Touch chest!");
  static const inclinePress = ExerciseRule(id: 'incline_press', name: 'Incline Press', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Nice!", cueBad: "Lower!");
  static const declinePress = ExerciseRule(id: 'decline_press', name: 'Decline Press', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Strong!", cueBad: "Full range!");
  static const pushUps = ExerciseRule(id: 'pushups', name: 'Push-ups', targetA: _sh, targetB: _hp, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Perfect!", cueBad: "Go lower!");
  static const widePushUps = ExerciseRule(id: 'wide_pushups', name: 'Wide Push-ups', targetA: _sh, targetB: _hp, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Wide!", cueBad: "Chest down!");
  static const diamondPushUps = ExerciseRule(id: 'diamond_pushups', name: 'Diamond Push-ups', targetA: _sh, targetB: _hp, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Diamond!", cueBad: "Deep!");
  static const dipsChest = ExerciseRule(id: 'dips_chest', name: 'Chest Dips', targetA: _sh, targetB: _el, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Nice dip!", cueBad: "Get to 90!");
  static const cableCrossovers = ExerciseRule(id: 'cable_crossovers', name: 'Cable Crossovers', targetA: _wr, targetB: _rwr, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Squeeze!", cueBad: "Together!");
  static const chestFlys = ExerciseRule(id: 'chest_flys', name: 'Chest Flys', targetA: _wr, targetB: _rwr, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Squeeze!", cueBad: "Arms together!");
  static const machineChestFly = ExerciseRule(id: 'machine_chest_fly', name: 'Machine Chest Fly', targetA: _wr, targetB: _rwr, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Squeeze!", cueBad: "Control!");
  static const dumbbellFlyes = ExerciseRule(id: 'dumbbell_flyes', name: 'Dumbbell Flyes', targetA: _wr, targetB: _rwr, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Stretch!", cueBad: "Slight bend!");
  static const landminePress = ExerciseRule(id: 'landmine_press', name: 'Landmine Press', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Press!", cueBad: "Extend!");

  // BACK
  static const deadlift = ExerciseRule(id: 'deadlift', name: 'Deadlift', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Lockout!", cueBad: "Hips forward!");
  static const sumoDeadlift = ExerciseRule(id: 'sumo_deadlift', name: 'Sumo Deadlift', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Wide!", cueBad: "Hips through!");
  static const bentOverRows = ExerciseRule(id: 'bent_over_rows', name: 'Bent-Over Rows', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Nice pull!", cueBad: "Squeeze lats!");
  static const pullUps = ExerciseRule(id: 'pull_ups', name: 'Pull-ups', targetA: _sh, targetB: _el, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Chin over!", cueBad: "Full stretch!");
  static const latPulldowns = ExerciseRule(id: 'lat_pulldowns', name: 'Lat Pulldowns', targetA: _sh, targetB: _el, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Lats!", cueBad: "Pull to chest!");
  static const cableRows = ExerciseRule(id: 'cable_rows', name: 'Cable Rows', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Perfect!", cueBad: "Full row!");
  static const tBarRows = ExerciseRule(id: 't_bar_rows', name: 'T-Bar Rows', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Nice!", cueBad: "Squeeze!");
  static const facePulls = ExerciseRule(id: 'face_pulls', name: 'Face Pulls', targetA: _el, targetB: _rel, rulerA: _sh, rulerB: _rsh, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Great!", cueBad: "To ears!");
  static const reverseFlys = ExerciseRule(id: 'reverse_flys', name: 'Reverse Flys', targetA: _wr, targetB: _rwr, rulerA: _sh, rulerB: _rsh, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Back!", cueBad: "Arms wide!");
  static const shrugs = ExerciseRule(id: 'shrugs', name: 'Shrugs', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.75, resetPercent: 0.90, cueGood: "High!", cueBad: "Full shrug!");
  static const singleArmDbRow = ExerciseRule(id: 'single_arm_db_row', name: 'Single Arm DB Row', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Pull!", cueBad: "Elbow high!");
  static const renegadeRows = ExerciseRule(id: 'renegade_rows', name: 'Renegade Rows', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Stable!", cueBad: "Pull high!");

  // SHOULDERS
  static const overheadPress = ExerciseRule(id: 'overhead_press', name: 'Overhead Press', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Sky high!", cueBad: "Lock out!");
  static const arnoldPress = ExerciseRule(id: 'arnold_press', name: 'Arnold Press', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Twist!", cueBad: "Full reach!");
  static const lateralRaises = ExerciseRule(id: 'lateral_raises', name: 'Lateral Raises', targetA: _wr, targetB: _hp, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Perfect!", cueBad: "To shoulders!");
  static const frontRaises = ExerciseRule(id: 'front_raises', name: 'Front Raises', targetA: _wr, targetB: _hp, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Strong!", cueBad: "Arm parallel!");
  static const rearDeltFlys = ExerciseRule(id: 'rear_delt_flys', name: 'Rear Delt Flys', targetA: _wr, targetB: _rwr, rulerA: _sh, rulerB: _rsh, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Wide!", cueBad: "Full spread!");
  static const uprightRows = ExerciseRule(id: 'upright_rows', name: 'Upright Rows', targetA: _el, targetB: _hp, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "High elbows!", cueBad: "Pull higher!");
  static const pikePushUps = ExerciseRule(id: 'pike_push_ups', name: 'Pike Push-ups', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Deep pike!", cueBad: "Go lower!");
  static const seatedDbPress = ExerciseRule(id: 'seated_db_press', name: 'Seated DB Press', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Press!", cueBad: "Full extension!");
  static const cableLateralRaise = ExerciseRule(id: 'cable_lateral_raise', name: 'Cable Lateral Raise', targetA: _wr, targetB: _hp, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Perfect!", cueBad: "To shoulders!");
  static const plankShoulderTaps = ExerciseRule(id: 'plank_shoulder_taps', name: 'Plank Shoulder Taps', targetA: _wr, targetB: _sh, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Stable!", cueBad: "Don't rock!");

  // LEGS
  static const squats = ExerciseRule(id: 'squats', name: 'Squats', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Depth!", cueBad: "Hit parallel!");
  static const airSquats = ExerciseRule(id: 'air_squats', name: 'Air Squats', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Nice squat!", cueBad: "Go lower!");
  static const sumoSquat = ExerciseRule(id: 'sumo_squat', name: 'Sumo Squat', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Wide!", cueBad: "Deeper!");
  static const gobletSquats = ExerciseRule(id: 'goblet_squats', name: 'Goblet Squats', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Good form!", cueBad: "Chest up!");
  static const frontSquat = ExerciseRule(id: 'front_squat', name: 'Front Squat', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Upright!", cueBad: "Elbows up!");
  static const jumpSquats = ExerciseRule(id: 'jump_squats', name: 'Jump Squats', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Explode!", cueBad: "Deeper!");
  static const lunges = ExerciseRule(id: 'lunges', name: 'Lunges', targetA: _hp, targetB: _kn, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Great step!", cueBad: "Deep lunge!");
  static const walkingLunges = ExerciseRule(id: 'walking_lunges', name: 'Walking Lunges', targetA: _hp, targetB: _kn, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Keep moving!", cueBad: "Deep lunge!");
  static const bulgarianSplitSquat = ExerciseRule(id: 'bulgarian_split_squat', name: 'Bulgarian Split Squat', targetA: _hp, targetB: _kn, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Balance!", cueBad: "Go deeper!");
  static const romanianDeadlift = ExerciseRule(id: 'romanian_deadlift', name: 'Romanian Deadlift', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Hamstrings!", cueBad: "Flat back!");
  static const legPress = ExerciseRule(id: 'leg_press', name: 'Leg Press', targetA: _hp, targetB: _kn, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Push!", cueBad: "Deep press!");
  static const legExtensions = ExerciseRule(id: 'leg_extensions', name: 'Leg Extensions', targetA: _kn, targetB: _ak, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Lock!", cueBad: "Full extension!");
  static const legCurls = ExerciseRule(id: 'leg_curls', name: 'Leg Curls', targetA: _kn, targetB: _ak, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Squeeze!", cueBad: "Heels to glutes!");
  static const calfRaises = ExerciseRule(id: 'calf_raises', name: 'Calf Raises', targetA: _kn, targetB: _ak, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Toes up!", cueBad: "Push high!");
  static const stepUps = ExerciseRule(id: 'step_ups', name: 'Step-ups', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Step tall!", cueBad: "Full step!");
  static const gluteBridge = ExerciseRule(id: 'glute_bridge', name: 'Glute Bridge', targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Squeeze!", cueBad: "Hips up!");
  static const singleLegGluteBridge = ExerciseRule(id: 'single_leg_glute_bridge', name: 'Single Leg Glute Bridge', targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "One leg!", cueBad: "Hips up!");
  static const hipThrust = ExerciseRule(id: 'hip_thrust', name: 'Hip Thrust', targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Thrust!", cueBad: "Full extension!");
  static const wallSits = ExerciseRule(id: 'wall_sits', name: 'Wall Sits', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Hold it!", cueBad: "90 degrees!");
  static const kettlebellSwings = ExerciseRule(id: 'kettlebell_swings', name: 'Kettlebell Swings', targetA: _wr, targetB: _hp, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Swing!", cueBad: "Hips drive!");
  static const cablePullthrough = ExerciseRule(id: 'cable_pullthrough', name: 'Cable Pullthrough', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Squeeze!", cueBad: "Hips forward!");

  // ARMS
  static const bicepCurls = ExerciseRule(id: 'bicep_curls', name: 'Bicep Curls', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Full curl!", cueBad: "No swinging!");
  static const hammerCurls = ExerciseRule(id: 'hammer_curls', name: 'Hammer Curls', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Nice grip!", cueBad: "Squeeze!");
  static const preacherCurls = ExerciseRule(id: 'preacher_curls', name: 'Preacher Curls', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Clean!", cueBad: "Stretch out!");
  static const concentrationCurls = ExerciseRule(id: 'concentration_curls', name: 'Concentration Curls', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Focus!", cueBad: "Full squeeze!");
  static const cableCurls = ExerciseRule(id: 'cable_curls', name: 'Cable Curls', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Tension!", cueBad: "Full curl!");
  static const barbellCurl = ExerciseRule(id: 'barbell_curl', name: 'Barbell Curl', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Squeeze!", cueBad: "No swinging!");
  static const tricepExtensions = ExerciseRule(id: 'tricep_extensions', name: 'Tricep Extensions', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Strong!", cueBad: "Full extend!");
  static const skullCrushers = ExerciseRule(id: 'skull_crushers', name: 'Skull Crushers', targetA: _el, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Perfect!", cueBad: "To forehead!");
  static const overheadTricepExtension = ExerciseRule(id: 'overhead_tricep', name: 'Overhead Tricep', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Reach high!", cueBad: "Lock out!");
  static const tricepPushdown = ExerciseRule(id: 'tricep_pushdown', name: 'Tricep Pushdown', targetA: _el, targetB: _wr, rulerA: _sh, rulerB: _el, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Push!", cueBad: "Full extension!");
  static const tricepDips = ExerciseRule(id: 'tricep_dips', name: 'Tricep Dips', targetA: _sh, targetB: _el, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Strong!", cueBad: "Get to 90!");
  static const tricepDipsChair = ExerciseRule(id: 'tricep_dips_chair', name: 'Tricep Dips (Chair)', targetA: _sh, targetB: _el, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Strong!", cueBad: "Get to 90!");
  static const closeGripPushUps = ExerciseRule(id: 'close_grip_push_ups', name: 'Close-grip Push-ups', targetA: _sh, targetB: _hp, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Triceps!", cueBad: "Deep push!");
  static const closeGripBench = ExerciseRule(id: 'close_grip_bench', name: 'Close Grip Bench', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Triceps!", cueBad: "Elbows in!");

  // CORE
  static const sitUps = ExerciseRule(id: 'sit_ups', name: 'Sit-ups', targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Core strong!", cueBad: "All the way!");
  static const crunches = ExerciseRule(id: 'crunches', name: 'Crunches', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.75, resetPercent: 0.92, cueGood: "Nice crunch!", cueBad: "Squeeze abs!");
  static const plank = ExerciseRule(id: 'plank', name: 'Plank', targetA: _sh, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.95, resetPercent: 0.92, cueGood: "Flat back!", cueBad: "Don't sag!");
  static const sidePlank = ExerciseRule(id: 'side_plank', name: 'Side Plank', targetA: _sh, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.95, resetPercent: 0.92, cueGood: "Hip up!", cueBad: "Stay straight!");
  static const legRaises = ExerciseRule(id: 'leg_raises', name: 'Leg Raises', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Legs high!", cueBad: "Lower slow!");
  static const russianTwists = ExerciseRule(id: 'russian_twists', name: 'Russian Twists', targetA: _wr, targetB: _hp, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Twist!", cueBad: "Feet up!");
  static const mountainClimbers = ExerciseRule(id: 'mountain_climbers', name: 'Mountain Climbers', targetA: _kn, targetB: _sh, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Fast feet!", cueBad: "Knees to chest!");
  static const bicycleCrunches = ExerciseRule(id: 'bicycle_crunches', name: 'Bicycle Crunches', targetA: _el, targetB: _kn, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Cycle!", cueBad: "Touch elbows!");
  static const hangingLegRaise = ExerciseRule(id: 'hanging_leg_raise', name: 'Hanging Leg Raise', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "High legs!", cueBad: "Full raise!");
  static const abWheelRollout = ExerciseRule(id: 'ab_wheel_rollout', name: 'Ab Wheel Rollout', targetA: _sh, targetB: _wr, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Roll deep!", cueBad: "Tight core!");
  static const woodchoppers = ExerciseRule(id: 'woodchoppers', name: 'Woodchoppers', targetA: _wr, targetB: _hp, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Full swing!", cueBad: "Rotate!");
  static const declineSitUp = ExerciseRule(id: 'decline_sit_up', name: 'Decline Sit-Up', targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Great crunch!", cueBad: "Full sit!");
  static const cableCrunch = ExerciseRule(id: 'cable_crunch', name: 'Cable Crunch', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.75, resetPercent: 0.92, cueGood: "Crunch!", cueBad: "Feel the abs!");
  static const deadBug = ExerciseRule(id: 'dead_bug', name: 'Dead Bug', targetA: _wr, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Slow!", cueBad: "Back flat!");
  static const supermanRaises = ExerciseRule(id: 'superman_raises', name: 'Superman Raises', targetA: _wr, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Fly!", cueBad: "Arms and legs up!");

  // CARDIO
  static const burpees = ExerciseRule(id: 'burpees', name: 'Burpees', targetA: _sh, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Explode!", cueBad: "Full extension!");
  static const jumpingJacks = ExerciseRule(id: 'jumping_jacks', name: 'Jumping Jacks', targetA: _wr, targetB: _rwr, rulerA: _sh, rulerB: _rsh, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Jump!", cueBad: "Arms high!");
  static const highKnees = ExerciseRule(id: 'high_knees', name: 'High Knees', targetA: _kn, targetB: _hp, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Knees up!", cueBad: "Higher!");
  static const buttKicks = ExerciseRule(id: 'butt_kicks', name: 'Butt Kicks', targetA: _ak, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Kick!", cueBad: "Heels to butt!");
  static const boxJumps = ExerciseRule(id: 'box_jumps', name: 'Box Jumps', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Jump!", cueBad: "Explode up!");
  static const jumpRope = ExerciseRule(id: 'jump_rope', name: 'Jump Rope', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Bounce!", cueBad: "Light feet!");
  static const bearCrawls = ExerciseRule(id: 'bear_crawls', name: 'Bear Crawls', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.75, resetPercent: 0.92, cueGood: "Crawl!", cueBad: "Low hips!");
  static const sprawls = ExerciseRule(id: 'sprawls', name: 'Sprawls', targetA: _sh, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Fast!", cueBad: "Hit the ground!");
  static const skaters = ExerciseRule(id: 'skaters', name: 'Skaters', targetA: _ak, targetB: _rak, rulerA: _hp, rulerB: _rhp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Glide!", cueBad: "Wide jumps!");
  static const tuckJumps = ExerciseRule(id: 'tuck_jumps', name: 'Tuck Jumps', targetA: _kn, targetB: _sh, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Tuck!", cueBad: "Knees high!");
  static const starJumps = ExerciseRule(id: 'star_jumps', name: 'Star Jumps', targetA: _wr, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Spread!", cueBad: "Wide!");
  static const lateralHops = ExerciseRule(id: 'lateral_hops', name: 'Lateral Hops', targetA: _ak, targetB: _rak, rulerA: _hp, rulerB: _rhp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Hop!", cueBad: "Side to side!");
  static const plankJacks = ExerciseRule(id: 'plank_jacks', name: 'Plank Jacks', targetA: _ak, targetB: _rak, rulerA: _sh, rulerB: _rsh, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Jump!", cueBad: "Feet wide!");
  static const jumpLunges = ExerciseRule(id: 'jump_lunges', name: 'Jump Lunges', targetA: _hp, targetB: _kn, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Switch!", cueBad: "Explode!");
  static const plankToPushup = ExerciseRule(id: 'plank_to_pushup', name: 'Plank to Push-up', targetA: _sh, targetB: _hp, rulerA: _sh, rulerB: _rsh, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Up!", cueBad: "Full extension!");

  // HOME BOOTY
  static const donkeyKicks = ExerciseRule(id: 'donkey_kicks', name: 'Donkey Kicks', targetA: _kn, targetB: _ak, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Kick!", cueBad: "Squeeze glute!");
  static const fireHydrants = ExerciseRule(id: 'fire_hydrants', name: 'Fire Hydrants', targetA: _kn, targetB: _hp, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Lift!", cueBad: "Open hip!");
  static const clamshells = ExerciseRule(id: 'clamshells', name: 'Clamshells', targetA: _kn, targetB: _rkn, rulerA: _hp, rulerB: _rhp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Open!", cueBad: "Keep feet together!");
  static const frogPumps = ExerciseRule(id: 'frog_pumps', name: 'Frog Pumps', targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Pump!", cueBad: "Hips up!");
  static const sumoSquatPulse = ExerciseRule(id: 'sumo_squat_pulse', name: 'Sumo Squat Pulse', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.75, resetPercent: 0.90, cueGood: "Pulse!", cueBad: "Stay low!");
  static const curtsyLunges = ExerciseRule(id: 'curtsy_lunges', name: 'Curtsy Lunges', targetA: _hp, targetB: _kn, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Cross!", cueBad: "Deep curtsy!");
  static const gluteBridgeHold = ExerciseRule(id: 'glute_bridge_hold', name: 'Glute Bridge Hold', targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Hold!", cueBad: "Hips high!");
  static const donkeyKickPulses = ExerciseRule(id: 'donkey_kick_pulses', name: 'Donkey Kick Pulses', targetA: _kn, targetB: _ak, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.75, resetPercent: 0.90, cueGood: "Pulse!", cueBad: "Small pulses!");
  static const squatToKickback = ExerciseRule(id: 'squat_to_kickback', name: 'Squat to Kickback', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Kick!", cueBad: "Full squat!");
  static const singleLegDeadlift = ExerciseRule(id: 'single_leg_deadlift', name: 'Single Leg Deadlift', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.92, cueGood: "Balance!", cueBad: "Flat back!");

  // BANDED
  static const bandedSquat = ExerciseRule(id: 'banded_squat', name: 'Banded Squat', targetA: _hp, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Push out!", cueBad: "Knees out!");
  static const bandedGluteBridge = ExerciseRule(id: 'banded_glute_bridge', name: 'Banded Glute Bridge', targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Squeeze!", cueBad: "Hips up!");
  static const bandedClamshell = ExerciseRule(id: 'banded_clamshell', name: 'Banded Clamshell', targetA: _kn, targetB: _rkn, rulerA: _hp, rulerB: _rhp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Open!", cueBad: "Fight the band!");
  static const bandedKickback = ExerciseRule(id: 'banded_kickback', name: 'Banded Kickback', targetA: _kn, targetB: _ak, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Kick!", cueBad: "Squeeze glute!");
  static const bandedLateralWalk = ExerciseRule(id: 'banded_lateral_walk', name: 'Banded Lateral Walk', targetA: _ak, targetB: _rak, rulerA: _hp, rulerB: _rhp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Step!", cueBad: "Stay low!");
  static const bandedFireHydrant = ExerciseRule(id: 'banded_fire_hydrant', name: 'Banded Fire Hydrant', targetA: _kn, targetB: _hp, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Lift!", cueBad: "Fight the band!");

  // STRETCHES
  static const catCow = ExerciseRule(id: 'cat_cow', name: 'Cat-Cow', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Flow!", cueBad: "Arch back!");
  static const worldsGreatestStretch = ExerciseRule(id: 'worlds_greatest_stretch', name: "World's Greatest Stretch", targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Deep!", cueBad: "Rotate!");
  static const pigeonPose = ExerciseRule(id: 'pigeon_pose', name: 'Pigeon Pose', targetA: _sh, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.75, resetPercent: 0.92, cueGood: "Hold!", cueBad: "Square hips!");
  static const hamstringStretch = ExerciseRule(id: 'hamstring_stretch', name: 'Hamstring Stretch', targetA: _sh, targetB: _ak, rulerA: _sh, rulerB: _hp, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Feel it!", cueBad: "Reach!");
  static const quadStretch = ExerciseRule(id: 'quad_stretch', name: 'Quad Stretch', targetA: _ak, targetB: _hp, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Pull!", cueBad: "Leg behind!");
  static const childsPose = ExerciseRule(id: 'childs_pose', name: "Child's Pose", targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Breathe!", cueBad: "Sit back!");
  static const chestDoorwayStretch = ExerciseRule(id: 'chest_doorway_stretch', name: 'Chest Doorway Stretch', targetA: _wr, targetB: _sh, rulerA: _sh, rulerB: _hp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Open!", cueBad: "Lean in!");
  static const stretch9090 = ExerciseRule(id: '90_90_stretch', name: '90/90 Stretch', targetA: _kn, targetB: _ak, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.75, resetPercent: 0.92, cueGood: "Hold!", cueBad: "Square torso!");
  static const frogStretch = ExerciseRule(id: 'frog_stretch', name: 'Frog Stretch', targetA: _kn, targetB: _rkn, rulerA: _hp, rulerB: _rhp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Relax!", cueBad: "Knees wide!");
  static const hipFlexorStretch = ExerciseRule(id: 'hip_flexor_stretch', name: 'Hip Flexor Stretch', targetA: _sh, targetB: _kn, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Push!", cueBad: "Lunge forward!");
  static const butterflyStretch = ExerciseRule(id: 'butterfly_stretch', name: 'Butterfly Stretch', targetA: _kn, targetB: _rkn, rulerA: _hp, rulerB: _rhp, targetShrinks: false, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Relax!", cueBad: "Knees down!");
  static const happyBaby = ExerciseRule(id: 'happy_baby', name: 'Happy Baby', targetA: _ak, targetB: _sh, rulerA: _hp, rulerB: _kn, targetShrinks: true, triggerPercent: 0.70, resetPercent: 0.90, cueGood: "Relax!", cueBad: "Knees wide!");

  // LOOKUP MAP
  static final Map<String, ExerciseRule> _rules = {
    'bench_press': benchPress, 'barbell_bench_press': benchPress, 'incline_press': inclinePress, 'incline_db_press': inclinePress,
    'decline_press': declinePress, 'decline_bench_press': declinePress, 'pushups': pushUps, 'push_ups': pushUps, 'push-ups': pushUps,
    'wide_pushups': widePushUps, 'wide_push_ups': widePushUps, 'diamond_pushups': diamondPushUps, 'diamond_push_ups': diamondPushUps,
    'dips_chest': dipsChest, 'chest_dips': dipsChest, 'cable_crossover': cableCrossovers, 'cable_crossovers': cableCrossovers,
    'chest_flys': chestFlys, 'machine_chest_fly': machineChestFly, 'dumbbell_flyes': dumbbellFlyes, 'landmine_press': landminePress,
    'deadlift': deadlift, 'sumo_deadlift': sumoDeadlift, 'bent_over_rows': bentOverRows, 'bent_rows': bentOverRows, 'barbell_row': bentOverRows,
    'pull_ups': pullUps, 'pullups': pullUps, 'lat_pulldown': latPulldowns, 'lat_pulldowns': latPulldowns, 'cable_rows': cableRows,
    'seated_cable_row': cableRows, 't_bar_rows': tBarRows, 'tbar_row': tBarRows, 'tbar_rows': tBarRows, 'face_pulls': facePulls,
    'reverse_flys': reverseFlys, 'reverse_fly': reverseFlys, 'shrugs': shrugs, 'barbell_shrugs': shrugs, 'single_arm_db_row': singleArmDbRow,
    'dumbbell_row': singleArmDbRow, 'renegade_rows': renegadeRows, 'overhead_press': overheadPress, 'shoulder_press': overheadPress,
    'arnold_press': arnoldPress, 'lateral_raises': lateralRaises, 'lateral_raise': lateralRaises, 'front_raises': frontRaises,
    'front_raise': frontRaises, 'rear_delt_flys': rearDeltFlys, 'upright_rows': uprightRows, 'pike_push_ups': pikePushUps,
    'pike_pushups': pikePushUps, 'seated_db_press': seatedDbPress, 'cable_lateral_raise': cableLateralRaise, 'plank_shoulder_taps': plankShoulderTaps,
    'squats': squats, 'back_squat': squats, 'air_squats': airSquats, 'squats_bw': airSquats, 'sumo_squat': sumoSquat,
    'goblet_squats': gobletSquats, 'front_squat': frontSquat, 'jump_squats': jumpSquats, 'squat_jumps': jumpSquats, 'lunges': lunges,
    'lunge': lunges, 'walking_lunges': walkingLunges, 'bulgarian_split_squat': bulgarianSplitSquat, 'bulgarian_split': bulgarianSplitSquat,
    'romanian_deadlift': romanianDeadlift, 'rdl': romanianDeadlift, 'leg_press': legPress, 'leg_press_high': legPress,
    'leg_extensions': legExtensions, 'leg_extension': legExtensions, 'leg_curls': legCurls, 'leg_curl': legCurls, 'calf_raises': calfRaises,
    'standing_calf_raise': calfRaises, 'step_ups': stepUps, 'stepups_chair': stepUps, 'box_stepups': stepUps, 'box_step_ups': stepUps,
    'glute_bridge': gluteBridge, 'single_leg_glute_bridge': singleLegGluteBridge, 'glute_bridge_single': singleLegGluteBridge,
    'hip_thrust': hipThrust, 'barbell_hip_thrust': hipThrust, 'wall_sits': wallSits, 'wall_sit': wallSits, 'kettlebell_swings': kettlebellSwings,
    'cable_pullthrough': cablePullthrough, 'bicep_curls': bicepCurls, 'hammer_curls': hammerCurls, 'preacher_curls': preacherCurls,
    'concentration_curls': concentrationCurls, 'cable_curls': cableCurls, 'barbell_curl': barbellCurl, 'tricep_extensions': tricepExtensions,
    'skull_crushers': skullCrushers, 'overhead_tricep': overheadTricepExtension, 'overhead_tricep_extension': overheadTricepExtension,
    'tricep_pushdown': tricepPushdown, 'tricep_dips': tricepDips, 'tricep_dips_chair': tricepDipsChair, 'close_grip_push_ups': closeGripPushUps,
    'close_grip_pushups': closeGripPushUps, 'close_grip_bench': closeGripBench, 'sit_ups': sitUps, 'situps': sitUps, 'crunches': crunches,
    'plank': plank, 'plank_hold': plank, 'side_plank': sidePlank, 'side_planks': sidePlank, 'leg_raises': legRaises,
    'russian_twists': russianTwists, 'russian_twist': russianTwists, 'mountain_climbers': mountainClimbers, 'bicycle_crunches': bicycleCrunches,
    'hanging_leg_raise': hangingLegRaise, 'ab_wheel_rollout': abWheelRollout, 'woodchoppers': woodchoppers, 'decline_sit_up': declineSitUp,
    'decline_situp': declineSitUp, 'cable_crunch': cableCrunch, 'dead_bug': deadBug, 'superman_raises': supermanRaises, 'superman': supermanRaises,
    'burpees': burpees, 'jumping_jacks': jumpingJacks, 'high_knees': highKnees, 'butt_kicks': buttKicks, 'box_jumps': boxJumps,
    'jump_rope': jumpRope, 'bear_crawls': bearCrawls, 'sprawls': sprawls, 'skaters': skaters, 'tuck_jumps': tuckJumps, 'star_jumps': starJumps,
    'lateral_hops': lateralHops, 'plank_jacks': plankJacks, 'jump_lunges': jumpLunges, 'plank_to_pushup': plankToPushup,
    'donkey_kicks': donkeyKicks, 'fire_hydrants': fireHydrants, 'clamshells': clamshells, 'frog_pumps': frogPumps,
    'sumo_squat_pulse': sumoSquatPulse, 'curtsy_lunges': curtsyLunges, 'glute_bridge_hold': gluteBridgeHold,
    'donkey_kick_pulses': donkeyKickPulses, 'squat_to_kickback': squatToKickback, 'single_leg_deadlift': singleLegDeadlift,
    'donkey_kicks_cable': donkeyKicks, 'banded_squat': bandedSquat, 'banded_glute_bridge': bandedGluteBridge,
    'banded_clamshell': bandedClamshell, 'banded_kickback': bandedKickback, 'banded_lateral_walk': bandedLateralWalk,
    'banded_fire_hydrant': bandedFireHydrant, 'cat_cow': catCow, 'worlds_greatest_stretch': worldsGreatestStretch,
    'pigeon_pose': pigeonPose, 'hamstring_stretch': hamstringStretch, 'quad_stretch': quadStretch, 'childs_pose': childsPose,
    'chest_doorway_stretch': chestDoorwayStretch, '90_90_stretch': stretch9090, 'frog_stretch': frogStretch,
    'hip_flexor_stretch': hipFlexorStretch, 'butterfly_stretch': butterflyStretch, 'happy_baby': happyBaby,
  };

  static ExerciseRule? getRule(String id) {
    final normalized = id.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return _rules[normalized];
  }

  static bool hasRule(String id) => getRule(id) != null;
  static int get exerciseCount => _rules.length;
  static List<String> get allIds => _rules.keys.toList();
}
