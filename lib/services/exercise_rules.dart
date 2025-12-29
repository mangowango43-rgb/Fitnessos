import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Rule definition for tracking a single exercise
class ExerciseRule {
  final String id;
  final String name;
  
  // The 3 landmarks that form the angle (right side)
  final PoseLandmarkType jointA; // First point
  final PoseLandmarkType jointB; // Vertex (where angle is measured)
  final PoseLandmarkType jointC; // Third point
  
  // Angle thresholds
  final double extendedAngle; // Angle when extended (e.g., standing, arms straight)
  final double contractedAngle; // Angle when contracted (e.g., squatting, arms bent)
  
  // Which direction counts the rep
  final bool countOnContraction; // true = count when going FROM extended TO contracted
  
  // Form feedback
  final double goodFormMin;
  final double goodFormMax;
  final String cueGood;
  final String cueBad;

  const ExerciseRule({
    required this.id,
    required this.name,
    required this.jointA,
    required this.jointB,
    required this.jointC,
    required this.extendedAngle,
    required this.contractedAngle,
    this.countOnContraction = true,
    required this.goodFormMin,
    required this.goodFormMax,
    this.cueGood = "Good rep!",
    this.cueBad = "Check form!",
  });
}

/// HOME - BODYWEIGHT BASICS - FULL BODY (7 exercises)
/// 
/// FIXED: Much more forgiving angles for real-world camera positions
/// 
class HomeFullBodyRules {
  
  // Landmark shortcuts
  static const _shoulder = PoseLandmarkType.rightShoulder;
  static const _elbow = PoseLandmarkType.rightElbow;
  static const _wrist = PoseLandmarkType.rightWrist;
  static const _hip = PoseLandmarkType.rightHip;
  static const _knee = PoseLandmarkType.rightKnee;
  static const _ankle = PoseLandmarkType.rightAnkle;

  /// 1. PUSH-UPS
  /// FIXED: extendedAngle 160→140, contractedAngle 90→120
  /// This means: arms straight ~140°, bottom position ~120°
  /// Much easier to hit from phone camera angle
  static const pushUps = ExerciseRule(
    id: 'pushups',
    name: 'Push-Ups',
    jointA: _shoulder,
    jointB: _elbow,
    jointC: _wrist,
    extendedAngle: 140,     // WAS 160 - lowered so easier to "reset"
    contractedAngle: 120,   // WAS 90 - raised so don't need to go as deep
    countOnContraction: true,
    goodFormMin: 110,
    goodFormMax: 130,
    cueGood: "Good!",
    cueBad: "Lower!",
  );

  /// 2. AIR SQUATS
  /// FIXED: More forgiving
  static const airSquats = ExerciseRule(
    id: 'air_squats',
    name: 'Air Squats',
    jointA: _hip,
    jointB: _knee,
    jointC: _ankle,
    extendedAngle: 160,     // WAS 170
    contractedAngle: 110,   // WAS 90 - don't need to go as deep
    countOnContraction: false,
    goodFormMin: 90,
    goodFormMax: 120,
    cueGood: "Nice!",
    cueBad: "Deeper!",
  );

  /// 3. LUNGES
  static const lunges = ExerciseRule(
    id: 'lunges',
    name: 'Lunges',
    jointA: _hip,
    jointB: _knee,
    jointC: _ankle,
    extendedAngle: 160,     // WAS 170
    contractedAngle: 110,   // WAS 90
    countOnContraction: false,
    goodFormMin: 100,
    goodFormMax: 120,
    cueGood: "Good lunge!",
    cueBad: "Knee down!",
  );

  /// 4. SUPERMAN RAISES
  static const supermanRaises = ExerciseRule(
    id: 'superman_raises',
    name: 'Superman Raises',
    jointA: _shoulder,
    jointB: _hip,
    jointC: _knee,
    extendedAngle: 175,     // WAS 180
    contractedAngle: 155,   // WAS 150
    countOnContraction: false,
    goodFormMin: 165,
    goodFormMax: 180,
    cueGood: "Hold!",
    cueBad: "Lift higher!",
  );

  /// 5. GLUTE BRIDGE
  static const gluteBridge = ExerciseRule(
    id: 'glute_bridge',
    name: 'Glute Bridge',
    jointA: _shoulder,
    jointB: _hip,
    jointC: _knee,
    extendedAngle: 170,     // WAS 180
    contractedAngle: 110,   // WAS 100
    countOnContraction: false,
    goodFormMin: 160,
    goodFormMax: 175,
    cueGood: "Squeeze!",
    cueBad: "Hips up!",
  );

  /// 6. PLANK (Isometric)
  static const plank = ExerciseRule(
    id: 'plank',
    name: 'Plank',
    jointA: _shoulder,
    jointB: _hip,
    jointC: _ankle,
    extendedAngle: 175,     // WAS 180
    contractedAngle: 155,   // WAS 160
    countOnContraction: false,
    goodFormMin: 165,
    goodFormMax: 180,
    cueGood: "Hold it!",
    cueBad: "Hips up!",
  );

  /// 7. MOUNTAIN CLIMBERS
  static const mountainClimbers = ExerciseRule(
    id: 'mountain_climbers',
    name: 'Mountain Climbers',
    jointA: _hip,
    jointB: _knee,
    jointC: _ankle,
    extendedAngle: 155,     // WAS 170
    contractedAngle: 80,    // WAS 60
    countOnContraction: true,
    goodFormMin: 70,
    goodFormMax: 100,
    cueGood: "Fast!",
    cueBad: "Knee up!",
  );

  /// Get rule by exercise ID
  static ExerciseRule? getRule(String exerciseId) {
    final id = exerciseId.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return _ruleMap[id];
  }

  static const Map<String, ExerciseRule> _ruleMap = {
    'pushups': pushUps,
    'push_ups': pushUps,
    'push-ups': pushUps,
    'air_squats': airSquats,
    'airsquats': airSquats,
    'squats': airSquats,
    'lunges': lunges,
    'lunge': lunges,
    'superman_raises': supermanRaises,
    'superman': supermanRaises,
    'supermans': supermanRaises,
    'glute_bridge': gluteBridge,
    'glute_bridges': gluteBridge,
    'glutebridge': gluteBridge,
    'plank': plank,
    'planks': plank,
    'mountain_climbers': mountainClimbers,
    'mountainclimbers': mountainClimbers,
  };

  /// Check if we have a rule for this exercise
  static bool hasRule(String exerciseId) => getRule(exerciseId) != null;
}
