import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Rep state - simple and clean
enum RepState {
  ready,    // Waiting for first movement
  down,     // User is in the "contracted" position
  up,       // User returned to start position - REP COUNTED
}

/// PROPORTION-BASED REP COUNTER
/// 
/// This doesn't use angles. It uses RATIOS.
/// No matter where the phone is (floor, shelf, tilted), ratios stay the same.
/// 
/// The logic:
/// 1. Capture baseline when user is standing ready
/// 2. Track how much the target distance SHRINKS (or expands) relative to the ruler
/// 3. When it hits the threshold → rep triggered
/// 4. When it returns → rep counted
class RepCounter {
  final ExerciseRule rule;
  
  // State
  RepState _state = RepState.ready;
  int _repCount = 0;
  bool _baselineCaptured = false;
  
  // Baseline measurements (captured at "SYSTEM LOCKED")
  double _baselineTarget = 0;  // The distance we're tracking (e.g., hip to ankle)
  double _baselineRuler = 0;   // The reference distance (e.g., torso length)
  double _baselineRatio = 0;   // target / ruler at start
  
  // Current frame measurements
  double _currentRatio = 0;
  double _currentPercentage = 100;  // 100% = at baseline, 60% = deep in rep
  
  // Thresholds
  double _repTriggerPercent = 60;   // Must hit this to trigger rep
  double _resetPercent = 90;        // Must return to this to validate rep
  
  // Smoothing (EMA)
  double _smoothedRatio = 0;
  static const double _emaAlpha = 0.3;  // Higher = more responsive, Lower = smoother
  
  // Feedback
  String _feedback = '';
  
  RepCounter(this.rule) {
    _repTriggerPercent = rule.repTriggerPercent;
    _resetPercent = rule.resetPercent;
  }
  
  // Getters
  int get repCount => _repCount;
  RepState get state => _state;
  double get currentPercentage => _currentPercentage;
  String get feedback => _feedback;
  bool get isLocked => _baselineCaptured;
  
  /// Call this when "SYSTEM LOCKED" - captures the baseline
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
    
    print('🔒 BASELINE CAPTURED');
    print('   Target distance: ${_baselineTarget.toStringAsFixed(3)}');
    print('   Ruler distance: ${_baselineRuler.toStringAsFixed(3)}');
    print('   Ratio: ${_baselineRatio.toStringAsFixed(3)}');
  }
  
  /// Process each frame - returns true if rep was just completed
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
    
    // Calculate current ratio
    final currentTarget = _distance(points.targetA, points.targetB);
    final currentRuler = _distance(points.rulerA, points.rulerB);
    
    if (currentRuler < 0.01) return false;
    
    final rawRatio = currentTarget / currentRuler;
    
    // Apply EMA smoothing
    _smoothedRatio = (_emaAlpha * rawRatio) + ((1 - _emaAlpha) * _smoothedRatio);
    _currentRatio = _smoothedRatio;
    
    // Calculate percentage relative to baseline
    // If exercise SHRINKS (squat, pushup): lower % = deeper
    // If exercise EXPANDS (shoulder press): higher % = deeper
    if (rule.shrinks) {
      _currentPercentage = (_currentRatio / _baselineRatio) * 100;
    } else {
      // For expanding exercises, invert the logic
      _currentPercentage = (_baselineRatio / _currentRatio) * 100;
    }
    
    // Clamp to reasonable range
    _currentPercentage = _currentPercentage.clamp(20, 150);
    
    // State machine
    return _updateState();
  }
  
  bool _updateState() {
    switch (_state) {
      case RepState.ready:
      case RepState.up:
        // Waiting for user to go DOWN
        if (_currentPercentage <= _repTriggerPercent) {
          _state = RepState.down;
          _feedback = "Good depth!";
          print('⬇️ DOWN - Hit ${_currentPercentage.toStringAsFixed(0)}%');
        }
        return false;
        
      case RepState.down:
        // Waiting for user to come back UP
        if (_currentPercentage >= _resetPercent) {
          _state = RepState.up;
          _repCount++;
          _feedback = "";
          print('✅ REP ${_repCount} - Back to ${_currentPercentage.toStringAsFixed(0)}%');
          return true;  // REP COMPLETED
        }
        return false;
    }
  }
  
  /// Extract the 4 points we need from landmarks
  _Points? _extractPoints(List<PoseLandmark> landmarks) {
    final map = {for (var lm in landmarks) lm.type: lm};
    
    final targetA = map[rule.targetA];
    final targetB = map[rule.targetB];
    final rulerA = map[rule.rulerA];
    final rulerB = map[rule.rulerB];
    
    if (targetA == null || targetB == null || rulerA == null || rulerB == null) {
      return null;
    }
    
    // Check confidence - all points must be visible enough
    if (targetA.likelihood < 0.5 || targetB.likelihood < 0.5 ||
        rulerA.likelihood < 0.5 || rulerB.likelihood < 0.5) {
      return null;
    }
    
    return _Points(
      targetA: Point(targetA.x, targetA.y),
      targetB: Point(targetB.x, targetB.y),
      rulerA: Point(rulerA.x, rulerA.y),
      rulerB: Point(rulerB.x, rulerB.y),
    );
  }
  
  /// Calculate distance between two points
  double _distance(Point a, Point b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }
  
  /// Reset for next set
  void reset() {
    _repCount = 0;
    _state = RepState.ready;
    _feedback = '';
    // Keep baseline - don't make them re-lock
  }
  
  /// Full reset (new exercise)
  void fullReset() {
    reset();
    _baselineCaptured = false;
    _baselineTarget = 0;
    _baselineRuler = 0;
    _baselineRatio = 0;
  }
}

/// Simple point class
class Point {
  final double x;
  final double y;
  Point(this.x, this.y);
}

/// Container for the 4 points we extract
class _Points {
  final Point targetA;
  final Point targetB;
  final Point rulerA;
  final Point rulerB;
  
  _Points({
    required this.targetA,
    required this.targetB,
    required this.rulerA,
    required this.rulerB,
  });
}


// =============================================================================
// EXERCISE RULE - The definition for each exercise
// =============================================================================

class ExerciseRule {
  final String id;
  final String name;
  
  // Target points - the distance we're tracking
  final PoseLandmarkType targetA;
  final PoseLandmarkType targetB;
  
  // Ruler points - the baseline reference (usually torso)
  final PoseLandmarkType rulerA;
  final PoseLandmarkType rulerB;
  
  // Does the target distance SHRINK for a rep? (most exercises = true)
  // false = distance EXPANDS for a rep (like shoulder press going UP)
  final bool shrinks;
  
  // Thresholds (as percentages of baseline)
  final double repTriggerPercent;  // Must hit this % to trigger (default 60%)
  final double resetPercent;       // Must return to this % to count (default 90%)
  
  const ExerciseRule({
    required this.id,
    required this.name,
    required this.targetA,
    required this.targetB,
    required this.rulerA,
    required this.rulerB,
    this.shrinks = true,
    this.repTriggerPercent = 60,
    this.resetPercent = 90,
  });
}


// =============================================================================
// EXERCISE RULES - All 120+ exercises using the proportion system
// =============================================================================

// Shorthand for landmark types
const _lShoulder = PoseLandmarkType.leftShoulder;
const _rShoulder = PoseLandmarkType.rightShoulder;
const _lElbow = PoseLandmarkType.leftElbow;
const _rElbow = PoseLandmarkType.rightElbow;
const _lWrist = PoseLandmarkType.leftWrist;
const _rWrist = PoseLandmarkType.rightWrist;
const _lHip = PoseLandmarkType.leftHip;
const _rHip = PoseLandmarkType.rightHip;
const _lKnee = PoseLandmarkType.leftKnee;
const _rKnee = PoseLandmarkType.rightKnee;
const _lAnkle = PoseLandmarkType.leftAnkle;
const _rAnkle = PoseLandmarkType.rightAnkle;

class ExerciseRules {
  
  // ======================= LEG EXERCISES =======================
  // Target: Hip to Ankle (shrinks when you squat)
  // Ruler: Shoulder to Hip (torso - stays constant)
  
  static const squats = ExerciseRule(
    id: 'squats', name: 'Squats',
    targetA: _rHip, targetB: _rAnkle,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 65,  // Don't need to go ATG
    resetPercent: 90,
  );
  
  static const airSquats = ExerciseRule(
    id: 'air_squats', name: 'Air Squats',
    targetA: _rHip, targetB: _rAnkle,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 65,
    resetPercent: 90,
  );
  
  static const lunges = ExerciseRule(
    id: 'lunges', name: 'Lunges',
    targetA: _rHip, targetB: _rKnee,  // Front leg knee drops
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 85,
  );
  
  static const bulgarianSplitSquat = ExerciseRule(
    id: 'bulgarian_split_squat', name: 'Bulgarian Split Squat',
    targetA: _rHip, targetB: _rKnee,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 85,
  );
  
  static const gluteBridge = ExerciseRule(
    id: 'glute_bridge', name: 'Glute Bridge',
    targetA: _rShoulder, targetB: _rHip,  // Hip rises UP
    rulerA: _rHip, rulerB: _rKnee,
    shrinks: false,  // Distance EXPANDS when you bridge up
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  static const hipThrust = ExerciseRule(
    id: 'hip_thrust', name: 'Hip Thrust',
    targetA: _rShoulder, targetB: _rHip,
    rulerA: _rHip, rulerB: _rKnee,
    shrinks: false,
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  static const romanianDeadlift = ExerciseRule(
    id: 'romanian_deadlift', name: 'Romanian Deadlift',
    targetA: _rShoulder, targetB: _rAnkle,  // Shoulders go DOWN toward ankles
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 65,
    resetPercent: 90,
  );
  
  static const deadlift = ExerciseRule(
    id: 'deadlift', name: 'Deadlift',
    targetA: _rShoulder, targetB: _rAnkle,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const calfRaises = ExerciseRule(
    id: 'calf_raises', name: 'Calf Raises',
    targetA: _rAnkle, targetB: _rKnee,  // Ankle rises relative to knee
    rulerA: _rKnee, rulerB: _rHip,
    shrinks: true,  // Distance gets smaller as you rise
    repTriggerPercent: 85,  // Small movement
    resetPercent: 95,
  );
  
  static const stepUps = ExerciseRule(
    id: 'step_ups', name: 'Step-ups',
    targetA: _rHip, targetB: _rAnkle,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: false,  // You go UP
    repTriggerPercent: 75,
    resetPercent: 90,
  );
  
  static const jumpSquats = ExerciseRule(
    id: 'jump_squats', name: 'Jump Squats',
    targetA: _rHip, targetB: _rAnkle,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 70,
    resetPercent: 85,
  );
  
  static const wallSits = ExerciseRule(
    id: 'wall_sits', name: 'Wall Sits',
    targetA: _rHip, targetB: _rAnkle,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 70,  // Hold position
    resetPercent: 95,
  );
  
  static const sumoSquat = ExerciseRule(
    id: 'sumo_squat', name: 'Sumo Squat',
    targetA: _rHip, targetB: _rAnkle,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 65,
    resetPercent: 90,
  );
  
  static const gobletSquats = ExerciseRule(
    id: 'goblet_squats', name: 'Goblet Squats',
    targetA: _rHip, targetB: _rAnkle,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 65,
    resetPercent: 90,
  );
  
  static const legPress = ExerciseRule(
    id: 'leg_press', name: 'Leg Press',
    targetA: _rHip, targetB: _rKnee,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const legExtensions = ExerciseRule(
    id: 'leg_extensions', name: 'Leg Extensions',
    targetA: _rKnee, targetB: _rAnkle,  // Lower leg extends
    rulerA: _rHip, rulerB: _rKnee,
    shrinks: false,  // Leg straightens OUT
    repTriggerPercent: 80,
    resetPercent: 95,
  );
  
  static const legCurls = ExerciseRule(
    id: 'leg_curls', name: 'Leg Curls',
    targetA: _rKnee, targetB: _rAnkle,  // Heel to butt
    rulerA: _rHip, rulerB: _rKnee,
    shrinks: true,
    repTriggerPercent: 55,
    resetPercent: 85,
  );
  
  static const donkeyKicks = ExerciseRule(
    id: 'donkey_kicks', name: 'Donkey Kicks',
    targetA: _rHip, targetB: _rKnee,  // Leg goes back
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: false,
    repTriggerPercent: 75,
    resetPercent: 90,
  );
  
  static const fireHydrants = ExerciseRule(
    id: 'fire_hydrants', name: 'Fire Hydrants',
    targetA: _lKnee, targetB: _rKnee,  // Knees spread apart
    rulerA: _lHip, rulerB: _rHip,
    shrinks: false,  // Distance increases
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  static const clamshells = ExerciseRule(
    id: 'clamshells', name: 'Clamshells',
    targetA: _lKnee, targetB: _rKnee,
    rulerA: _lHip, rulerB: _rHip,
    shrinks: false,
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  
  // ======================= PUSH EXERCISES =======================
  // Target: Shoulder to Wrist (or Shoulder to ground proxy)
  // Ruler: Torso (Shoulder to Hip) or Shoulder width
  
  static const pushUps = ExerciseRule(
    id: 'push_ups', name: 'Push-ups',
    targetA: _rShoulder, targetB: _rWrist,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,  // Shoulder drops toward wrist
    repTriggerPercent: 65,  // 90 degree elbow
    resetPercent: 90,
  );
  
  static const widePushUps = ExerciseRule(
    id: 'wide_pushups', name: 'Wide Push-ups',
    targetA: _rShoulder, targetB: _rWrist,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  static const diamondPushUps = ExerciseRule(
    id: 'diamond_pushups', name: 'Diamond Push-ups',
    targetA: _rShoulder, targetB: _rWrist,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 65,
    resetPercent: 90,
  );
  
  static const benchPress = ExerciseRule(
    id: 'bench_press', name: 'Bench Press',
    targetA: _rShoulder, targetB: _rElbow,  // Elbow drops
    rulerA: _rElbow, rulerB: _rWrist,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const inclinePress = ExerciseRule(
    id: 'incline_press', name: 'Incline Press',
    targetA: _rShoulder, targetB: _rElbow,
    rulerA: _rElbow, rulerB: _rWrist,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const declinePress = ExerciseRule(
    id: 'decline_press', name: 'Decline Press',
    targetA: _rShoulder, targetB: _rElbow,
    rulerA: _rElbow, rulerB: _rWrist,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const dips = ExerciseRule(
    id: 'dips', name: 'Dips',
    targetA: _rShoulder, targetB: _rElbow,
    rulerA: _rElbow, rulerB: _rWrist,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const chestFlys = ExerciseRule(
    id: 'chest_flys', name: 'Chest Flys',
    targetA: _lWrist, targetB: _rWrist,  // Hands come together
    rulerA: _lShoulder, rulerB: _rShoulder,
    shrinks: true,
    repTriggerPercent: 50,
    resetPercent: 85,
  );
  
  static const cableCrossovers = ExerciseRule(
    id: 'cable_crossovers', name: 'Cable Crossovers',
    targetA: _lWrist, targetB: _rWrist,
    rulerA: _lShoulder, rulerB: _rShoulder,
    shrinks: true,
    repTriggerPercent: 50,
    resetPercent: 85,
  );
  
  
  // ======================= PULL EXERCISES =======================
  
  static const pullUps = ExerciseRule(
    id: 'pull_ups', name: 'Pull-ups',
    targetA: _rShoulder, targetB: _rElbow,  // Elbow bends
    rulerA: _rElbow, rulerB: _rWrist,
    shrinks: true,
    repTriggerPercent: 55,
    resetPercent: 90,
  );
  
  static const latPulldowns = ExerciseRule(
    id: 'lat_pulldowns', name: 'Lat Pulldowns',
    targetA: _rShoulder, targetB: _rElbow,
    rulerA: _rElbow, rulerB: _rWrist,
    shrinks: true,
    repTriggerPercent: 55,
    resetPercent: 90,
  );
  
  static const bentOverRows = ExerciseRule(
    id: 'bent_over_rows', name: 'Bent-Over Rows',
    targetA: _rElbow, targetB: _rHip,  // Elbow comes to hip
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const cableRows = ExerciseRule(
    id: 'cable_rows', name: 'Cable Rows',
    targetA: _rElbow, targetB: _rHip,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const singleArmRow = ExerciseRule(
    id: 'single_arm_db_row', name: 'Single Arm DB Row',
    targetA: _rElbow, targetB: _rHip,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const facePulls = ExerciseRule(
    id: 'face_pulls', name: 'Face Pulls',
    targetA: _rWrist, targetB: _rShoulder,  // Wrist comes to face
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 65,
    resetPercent: 90,
  );
  
  
  // ======================= SHOULDER EXERCISES =======================
  
  static const overheadPress = ExerciseRule(
    id: 'overhead_press', name: 'Overhead Press',
    targetA: _rShoulder, targetB: _rWrist,  // Wrist goes UP above shoulder
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: false,  // Distance EXPANDS as you press up
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  static const arnoldPress = ExerciseRule(
    id: 'arnold_press', name: 'Arnold Press',
    targetA: _rShoulder, targetB: _rWrist,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: false,
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  static const lateralRaises = ExerciseRule(
    id: 'lateral_raises', name: 'Lateral Raises',
    targetA: _lWrist, targetB: _rWrist,  // Arms spread OUT
    rulerA: _lShoulder, rulerB: _rShoulder,
    shrinks: false,
    repTriggerPercent: 65,
    resetPercent: 90,
  );
  
  static const frontRaises = ExerciseRule(
    id: 'front_raises', name: 'Front Raises',
    targetA: _rWrist, targetB: _rHip,  // Wrist goes UP away from hip
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: false,
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  static const rearDeltFlys = ExerciseRule(
    id: 'rear_delt_flys', name: 'Rear Delt Flys',
    targetA: _lWrist, targetB: _rWrist,
    rulerA: _lShoulder, rulerB: _rShoulder,
    shrinks: false,
    repTriggerPercent: 65,
    resetPercent: 90,
  );
  
  static const shrugs = ExerciseRule(
    id: 'shrugs', name: 'Shrugs',
    targetA: _rShoulder, targetB: _rHip,  // Shoulder rises
    rulerA: _rHip, rulerB: _rKnee,
    shrinks: false,
    repTriggerPercent: 85,  // Small movement
    resetPercent: 95,
  );
  
  
  // ======================= ARM EXERCISES =======================
  
  static const bicepCurls = ExerciseRule(
    id: 'bicep_curls', name: 'Bicep Curls',
    targetA: _rShoulder, targetB: _rWrist,  // Wrist comes to shoulder
    rulerA: _rShoulder, rulerB: _rElbow,  // Upper arm as ruler
    shrinks: true,
    repTriggerPercent: 55,
    resetPercent: 90,
  );
  
  static const hammerCurls = ExerciseRule(
    id: 'hammer_curls', name: 'Hammer Curls',
    targetA: _rShoulder, targetB: _rWrist,
    rulerA: _rShoulder, rulerB: _rElbow,
    shrinks: true,
    repTriggerPercent: 55,
    resetPercent: 90,
  );
  
  static const preacherCurls = ExerciseRule(
    id: 'preacher_curls', name: 'Preacher Curls',
    targetA: _rShoulder, targetB: _rWrist,
    rulerA: _rShoulder, rulerB: _rElbow,
    shrinks: true,
    repTriggerPercent: 55,
    resetPercent: 90,
  );
  
  static const tricepExtensions = ExerciseRule(
    id: 'tricep_extensions', name: 'Tricep Extensions',
    targetA: _rElbow, targetB: _rWrist,  // Forearm extends
    rulerA: _rShoulder, rulerB: _rElbow,
    shrinks: false,  // Arm straightens OUT
    repTriggerPercent: 75,
    resetPercent: 90,
  );
  
  static const skullCrushers = ExerciseRule(
    id: 'skull_crushers', name: 'Skull Crushers',
    targetA: _rElbow, targetB: _rWrist,
    rulerA: _rShoulder, rulerB: _rElbow,
    shrinks: true,  // Forearm comes DOWN
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const tricepPushdowns = ExerciseRule(
    id: 'tricep_pushdowns', name: 'Tricep Pushdowns',
    targetA: _rElbow, targetB: _rWrist,
    rulerA: _rShoulder, rulerB: _rElbow,
    shrinks: false,
    repTriggerPercent: 75,
    resetPercent: 90,
  );
  
  static const tricepDips = ExerciseRule(
    id: 'tricep_dips', name: 'Tricep Dips',
    targetA: _rShoulder, targetB: _rElbow,
    rulerA: _rElbow, rulerB: _rWrist,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  
  // ======================= CORE EXERCISES =======================
  
  static const crunches = ExerciseRule(
    id: 'crunches', name: 'Crunches',
    targetA: _rShoulder, targetB: _rHip,  // Shoulders curl toward hips
    rulerA: _rHip, rulerB: _rKnee,
    shrinks: true,
    repTriggerPercent: 75,
    resetPercent: 90,
  );
  
  static const sitUps = ExerciseRule(
    id: 'sit_ups', name: 'Sit-ups',
    targetA: _rShoulder, targetB: _rKnee,  // Shoulders come to knees
    rulerA: _rHip, rulerB: _rKnee,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 90,
  );
  
  static const legRaises = ExerciseRule(
    id: 'leg_raises', name: 'Leg Raises',
    targetA: _rHip, targetB: _rAnkle,  // Legs come UP
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: false,  // Actually the angle changes...
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  static const mountainClimbers = ExerciseRule(
    id: 'mountain_climbers', name: 'Mountain Climbers',
    targetA: _rKnee, targetB: _rShoulder,  // Knee comes to chest
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 65,
    resetPercent: 85,
  );
  
  static const plank = ExerciseRule(
    id: 'plank', name: 'Plank',
    targetA: _rShoulder, targetB: _rAnkle,  // Body stays straight
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: false,
    repTriggerPercent: 95,  // Just hold
    resetPercent: 100,
  );
  
  static const russianTwists = ExerciseRule(
    id: 'russian_twists', name: 'Russian Twists',
    targetA: _lWrist, targetB: _rWrist,  // Hands move side to side
    rulerA: _lShoulder, rulerB: _rShoulder,
    shrinks: true,
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  static const bicycleCrunches = ExerciseRule(
    id: 'bicycle_crunches', name: 'Bicycle Crunches',
    targetA: _rElbow, targetB: _lKnee,  // Elbow to opposite knee
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 85,
  );
  
  static const supermanRaises = ExerciseRule(
    id: 'superman_raises', name: 'Superman Raises',
    targetA: _rWrist, targetB: _rAnkle,  // Stretch out
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: false,
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  
  // ======================= CARDIO / EXPLOSIVE =======================
  
  static const jumpingJacks = ExerciseRule(
    id: 'jumping_jacks', name: 'Jumping Jacks',
    targetA: _lWrist, targetB: _rWrist,  // Arms spread
    rulerA: _lShoulder, rulerB: _rShoulder,
    shrinks: false,
    repTriggerPercent: 65,
    resetPercent: 90,
  );
  
  static const burpees = ExerciseRule(
    id: 'burpees', name: 'Burpees',
    targetA: _rShoulder, targetB: _rAnkle,  // Full body up/down
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 50,
    resetPercent: 85,
  );
  
  static const highKnees = ExerciseRule(
    id: 'high_knees', name: 'High Knees',
    targetA: _rKnee, targetB: _rHip,  // Knee comes UP
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 70,
    resetPercent: 90,
  );
  
  static const buttKicks = ExerciseRule(
    id: 'butt_kicks', name: 'Butt Kicks',
    targetA: _rKnee, targetB: _rAnkle,  // Heel to butt
    rulerA: _rHip, rulerB: _rKnee,
    shrinks: true,
    repTriggerPercent: 60,
    resetPercent: 85,
  );
  
  static const boxJumps = ExerciseRule(
    id: 'box_jumps', name: 'Box Jumps',
    targetA: _rHip, targetB: _rAnkle,
    rulerA: _rShoulder, rulerB: _rHip,
    shrinks: true,
    repTriggerPercent: 70,
    resetPercent: 85,
  );
  
  
  // ======================= LOOKUP MAP =======================
  
  static final Map<String, ExerciseRule> _rules = {
    // Legs
    'squats': squats,
    'air_squats': airSquats,
    'lunges': lunges,
    'lunge': lunges,
    'bulgarian_split_squat': bulgarianSplitSquat,
    'glute_bridge': gluteBridge,
    'hip_thrust': hipThrust,
    'romanian_deadlift': romanianDeadlift,
    'rdl': romanianDeadlift,
    'deadlift': deadlift,
    'calf_raises': calfRaises,
    'step_ups': stepUps,
    'jump_squats': jumpSquats,
    'wall_sits': wallSits,
    'wall_sit': wallSits,
    'sumo_squat': sumoSquat,
    'goblet_squats': gobletSquats,
    'leg_press': legPress,
    'leg_extensions': legExtensions,
    'leg_curls': legCurls,
    'donkey_kicks': donkeyKicks,
    'fire_hydrants': fireHydrants,
    'clamshells': clamshells,
    
    // Push
    'push_ups': pushUps,
    'pushups': pushUps,
    'wide_pushups': widePushUps,
    'diamond_pushups': diamondPushUps,
    'bench_press': benchPress,
    'incline_press': inclinePress,
    'decline_press': declinePress,
    'dips': dips,
    'dips_chest': dips,
    'chest_flys': chestFlys,
    'cable_crossovers': cableCrossovers,
    
    // Pull
    'pull_ups': pullUps,
    'lat_pulldowns': latPulldowns,
    'bent_over_rows': bentOverRows,
    'cable_rows': cableRows,
    'single_arm_db_row': singleArmRow,
    'face_pulls': facePulls,
    
    // Shoulders
    'overhead_press': overheadPress,
    'shoulder_press': overheadPress,
    'arnold_press': arnoldPress,
    'lateral_raises': lateralRaises,
    'front_raises': frontRaises,
    'rear_delt_flys': rearDeltFlys,
    'shrugs': shrugs,
    
    // Arms
    'bicep_curls': bicepCurls,
    'hammer_curls': hammerCurls,
    'preacher_curls': preacherCurls,
    'tricep_extensions': tricepExtensions,
    'skull_crushers': skullCrushers,
    'tricep_pushdowns': tricepPushdowns,
    'tricep_dips': tricepDips,
    'tricep_dips_chair': tricepDips,
    
    // Core
    'crunches': crunches,
    'sit_ups': sitUps,
    'leg_raises': legRaises,
    'mountain_climbers': mountainClimbers,
    'plank': plank,
    'plank_hold': plank,
    'russian_twists': russianTwists,
    'bicycle_crunches': bicycleCrunches,
    'superman_raises': supermanRaises,
    
    // Cardio
    'jumping_jacks': jumpingJacks,
    'burpees': burpees,
    'high_knees': highKnees,
    'butt_kicks': buttKicks,
    'box_jumps': boxJumps,
  };
  
  /// Get rule by exercise ID
  static ExerciseRule? getRule(String id) {
    return _rules[id.toLowerCase()];
  }
  
  /// Check if we have a rule for this exercise
  static bool hasRule(String id) {
    return _rules.containsKey(id.toLowerCase());
  }
  
  /// Get all exercise IDs
  static List<String> get allIds => _rules.keys.toList();
}
