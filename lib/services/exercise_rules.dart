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
/// Exercises:
/// 1. Push-Ups - 3x15 - Chest/Triceps
/// 2. Air Squats - 3x20 - Legs
/// 3. Lunges - 3x12 - Legs
/// 4. Superman Raises - 3x15 - Back
/// 5. Glute Bridge - 3x15 - Glutes
/// 6. Plank - 3x45s - Core (isometric - special handling)
/// 7. Mountain Climbers- 3x20 - Cardio/Core
class HomeFullBodyRules {
  
  // Landmark shortcuts
  static const _shoulder = PoseLandmarkType.rightShoulder;
  static const _elbow = PoseLandmarkType.rightElbow;
  static const _wrist = PoseLandmarkType.rightWrist;
  static const _hip = PoseLandmarkType.rightHip;
  static const _knee = PoseLandmarkType.rightKnee;
  static const _ankle = PoseLandmarkType.rightAnkle;

  /// 1. PUSH-UPS
  /// Track: Shoulder → Elbow → Wrist angle
  /// Extended: ~160° (arms straight)
  /// Contracted: ~90° (chest to floor)
  /// Count when: Going DOWN (extended → contracted)
  static const pushUps = ExerciseRule(
    id: 'pushups',
    name: 'Push-Ups',
    jointA: _shoulder,
    jointB: _elbow,
    jointC: _wrist,
    extendedAngle: 160,
    contractedAngle: 90,
    countOnContraction: true,
    goodFormMin: 80,
    goodFormMax: 100,
    cueGood: "Perfect depth!",
    cueBad: "Go lower!",
  );

  /// 2. AIR SQUATS
  /// Track: Hip → Knee → Ankle angle
  /// Extended: ~170° (standing)
  /// Contracted: ~90° (parallel squat)
  /// Count when: Going UP (contracted → extended)
  static const airSquats = ExerciseRule(
    id: 'air_squats',
    name: 'Air Squats',
    jointA: _hip,
    jointB: _knee,
    jointC: _ankle,
    extendedAngle: 170,
    contractedAngle: 90,
    countOnContraction: false, // Count on the way UP
    goodFormMin: 70,
    goodFormMax: 100,
    cueGood: "Great depth!",
    cueBad: "Sit deeper!",
  );

  /// 3. LUNGES
  /// Track: Hip → Knee → Ankle angle (front leg)
  /// Extended: ~170° (standing)
  /// Contracted: ~90° (deep lunge)
  /// Count when: Going UP
  static const lunges = ExerciseRule(
    id: 'lunges',
    name: 'Lunges',
    jointA: _hip,
    jointB: _knee,
    jointC: _ankle,
    extendedAngle: 170,
    contractedAngle: 90,
    countOnContraction: false,
    goodFormMin: 80,
    goodFormMax: 100,
    cueGood: "Deep lunge!",
    cueBad: "Knee to 90!",
  );

  /// 4. SUPERMAN RAISES
  /// Track: Shoulder → Hip → Knee angle (body extension)
  /// Contracted: ~150° (lying flat)
  /// Extended: ~180° (back arched, limbs up)
  /// Count when: Going UP (lifting)
  static const supermanRaises = ExerciseRule(
    id: 'superman_raises',
    name: 'Superman Raises',
    jointA: _shoulder,
    jointB: _hip,
    jointC: _knee,
    extendedAngle: 180,
    contractedAngle: 150,
    countOnContraction: false,
    goodFormMin: 170,
    goodFormMax: 190,
    cueGood: "Hold it!",
    cueBad: "Lift higher!",
  );

  /// 5. GLUTE BRIDGE
  /// Track: Shoulder → Hip → Knee angle
  /// Contracted: ~100° (hips down)
  /// Extended: ~180° (hips up, body straight)
  /// Count when: Going UP
  static const gluteBridge = ExerciseRule(
    id: 'glute_bridge',
    name: 'Glute Bridge',
    jointA: _shoulder,
    jointB: _hip,
    jointC: _knee,
    extendedAngle: 180,
    contractedAngle: 100,
    countOnContraction: false,
    goodFormMin: 170,
    goodFormMax: 190,
    cueGood: "Squeeze glutes!",
    cueBad: "Push hips up!",
  );

  /// 6. PLANK (Isometric - no reps, just hold detection)
  /// Track: Shoulder → Hip → Ankle angle
  /// Should be ~180° (straight line)
  /// This is special - we don't count reps, just check form
  static const plank = ExerciseRule(
    id: 'plank',
    name: 'Plank',
    jointA: _shoulder,
    jointB: _hip,
    jointC: _ankle,
    extendedAngle: 180,
    contractedAngle: 160, // If hips sag below this, bad form
    countOnContraction: false,
    goodFormMin: 170,
    goodFormMax: 190,
    cueGood: "Hold strong!",
    cueBad: "Hips up!",
  );

  /// 7. MOUNTAIN CLIMBERS
  /// Track: Hip → Knee → Ankle (alternating legs)
  /// Extended: ~170° (leg back)
  /// Contracted: ~60° (knee to chest)
  /// Count when: Knee comes forward
  static const mountainClimbers = ExerciseRule(
    id: 'mountain_climbers',
    name: 'Mountain Climbers',
    jointA: _hip,
    jointB: _knee,
    jointC: _ankle,
    extendedAngle: 170,
    contractedAngle: 60,
    countOnContraction: true,
    goodFormMin: 50,
    goodFormMax: 70,
    cueGood: "Fast!",
    cueBad: "Knee to chest!",
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

