import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'base_pattern.dart';
import 'squat_pattern.dart';
import 'hinge_pattern.dart';
import 'push_pattern.dart';
import 'pull_pattern.dart';
import 'curl_pattern.dart';

/// =============================================================================
/// MOVEMENT ENGINE - The Boss
/// =============================================================================
/// This is the single entry point for the rep counting system.
/// It picks the right pattern based on exercise ID and delegates all work.
/// =============================================================================

enum MovementType { squat, hinge, push, pull, curl }

class MovementEngine {
  BasePattern? _activePattern;
  String _currentExerciseId = "";
  
  // Getters - delegate to active pattern
  bool get isLocked => _activePattern?.isLocked ?? false;
  int get repCount => _activePattern?.repCount ?? 0;
  String get feedback => _activePattern?.feedback ?? "";
  RepState get state => _activePattern?.state ?? RepState.ready;
  double get chargeProgress => _activePattern?.chargeProgress ?? 0.0;
  
  /// Load a pattern for an exercise
  void loadExercise(String exerciseId) {
    _currentExerciseId = exerciseId.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    _activePattern = _getPatternForExercise(_currentExerciseId);
  }
  
  /// Capture baseline for current exercise
  void captureBaseline(List<PoseLandmark> landmarks) {
    if (_activePattern == null) return;
    final map = {for (var lm in landmarks) lm.type: lm};
    _activePattern!.captureBaseline(map);
  }
  
  /// Process a frame - returns true if rep was counted
  bool processFrame(List<PoseLandmark> landmarks) {
    if (_activePattern == null) return false;
    final map = {for (var lm in landmarks) lm.type: lm};
    return _activePattern!.processFrame(map);
  }
  
  /// Reset the counter
  void reset() {
    _activePattern?.reset();
  }
  
  /// Check if we have a pattern for an exercise
  static bool hasPattern(String exerciseId) {
    final normalized = exerciseId.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return _exerciseToType.containsKey(normalized);
  }
  
  // =========================================================================
  // EXERCISE MAPPING - Which exercises use which pattern
  // =========================================================================
  
  BasePattern _getPatternForExercise(String exerciseId) {
    final type = _exerciseToType[exerciseId] ?? MovementType.squat;
    final config = _exerciseConfig[exerciseId];
    
    switch (type) {
      case MovementType.squat:
        return SquatPattern(
          triggerPercent: config?['trigger'] ?? 0.78,
          resetPercent: config?['reset'] ?? 0.92,
          cueGood: config?['cueGood'] ?? "Depth!",
          cueBad: config?['cueBad'] ?? "Hit parallel!",
        );
      case MovementType.hinge:
        return HingePattern(
          triggerAngle: config?['trigger'] ?? 105,
          resetAngle: config?['reset'] ?? 165,
          cueGood: config?['cueGood'] ?? "Lockout!",
          cueBad: config?['cueBad'] ?? "Hips forward!",
        );
      case MovementType.push:
        return PushPattern(
          cueGood: config?['cueGood'] ?? "Perfect!",
          cueBad: config?['cueBad'] ?? "Go lower!",
        );
      case MovementType.pull:
        return PullPattern(
          triggerAngle: config?['trigger'] ?? 75,
          resetAngle: config?['reset'] ?? 155,
          cueGood: config?['cueGood'] ?? "Chin up!",
          cueBad: config?['cueBad'] ?? "Full hang!",
        );
      case MovementType.curl:
        return CurlPattern(
          cueGood: config?['cueGood'] ?? "Full curl!",
          cueBad: config?['cueBad'] ?? "Squeeze!",
        );
    }
  }
  
  // Map exercise ID to movement type
  static final Map<String, MovementType> _exerciseToType = {

  // ============================================================================
  // GYM - CHEST
  // ============================================================================
  'barbell_bench_press': MovementType.push,
  'incline_db_press': MovementType.push,
  'decline_bench_press': MovementType.push,
  'cable_crossover': MovementType.push,
  'machine_chest_fly': MovementType.push,
  'dumbbell_flyes': MovementType.push,
  'pushups': MovementType.push,
  'chest_dips': MovementType.push,

  // ============================================================================
  // GYM - BACK
  // ============================================================================
  'deadlift': MovementType.hinge,
  'barbell_row': MovementType.pull,
  'lat_pulldown': MovementType.pull,
  'seated_cable_row': MovementType.pull,
  'tbar_row': MovementType.pull,
  'single_arm_db_row': MovementType.pull,
  'face_pulls': MovementType.pull,
  'pullups': MovementType.pull,
  'dumbbell_row': MovementType.pull,
  'renegade_rows': MovementType.pull,

  // ============================================================================
  // GYM - SHOULDERS
  // ============================================================================
  'overhead_press': MovementType.push,
  'seated_db_press': MovementType.push,
  'arnold_press': MovementType.push,
  'lateral_raise': MovementType.push,
  'front_raise': MovementType.push,
  'reverse_fly': MovementType.push,
  'cable_lateral_raise': MovementType.push,
  'barbell_shrugs': MovementType.push,
  'shoulder_press': MovementType.push,

  // ============================================================================
  // GYM - LEGS
  // ============================================================================
  'back_squat': MovementType.squat,
  'front_squat': MovementType.squat,
  'romanian_deadlift': MovementType.hinge,
  'leg_press': MovementType.squat,
  'bulgarian_split_squat': MovementType.squat,
  'leg_extension': MovementType.squat,
  'leg_curl': MovementType.squat,
  'hip_thrust': MovementType.hinge,
  'glute_kickback': MovementType.hinge,
  'standing_calf_raise': MovementType.squat,
  'sumo_squat': MovementType.squat,
  'sumo_deadlift': MovementType.hinge,
  'goblet_squats': MovementType.squat,
  'walking_lunges': MovementType.squat,
  'box_stepups': MovementType.squat,
  'box_jumps': MovementType.squat,

  // ============================================================================
  // GYM - ARMS
  // ============================================================================
  'barbell_curl': MovementType.curl,
  'hammer_curl': MovementType.curl,
  'preacher_curl': MovementType.curl,
  'skull_crushers': MovementType.curl,
  'concentration_curl': MovementType.curl,
  'tricep_pushdown': MovementType.curl,
  'overhead_tricep_ext': MovementType.curl,
  'close_grip_bench': MovementType.push,
  'cable_curl': MovementType.curl,
  'tricep_dips': MovementType.push,
  'bicep_curls': MovementType.curl,

  // ============================================================================
  // GYM - CORE
  // ============================================================================
  'cable_crunch': MovementType.squat,
  'hanging_leg_raise': MovementType.squat,
  'ab_wheel_rollout': MovementType.squat,
  'russian_twist': MovementType.squat,
  'woodchoppers': MovementType.squat,
  'decline_situp': MovementType.squat,
  'plank': MovementType.squat,
  'side_plank': MovementType.squat,
  'plank_hold': MovementType.squat,

  // ============================================================================
  // GYM - CIRCUITS
  // ============================================================================
  'barbell_squat_press': MovementType.squat,
  'battle_ropes': MovementType.squat,
  'thrusters': MovementType.squat,
  'kettlebell_swings': MovementType.hinge,

  // ============================================================================
  // GYM - BOOTY BUILDER
  // ============================================================================
  'cable_kickback': MovementType.hinge,
  'glute_bridge_single': MovementType.hinge,
  'cable_pullthrough': MovementType.hinge,
  'barbell_hip_thrust': MovementType.hinge,
  'leg_press_high': MovementType.squat,
  'donkey_kicks_cable': MovementType.hinge,

  // ============================================================================
  // HOME - BODYWEIGHT BASICS
  // ============================================================================
  'air_squats': MovementType.squat,
  'lunges': MovementType.squat,
  'superman_raises': MovementType.squat,
  'glute_bridge': MovementType.hinge,
  'mountain_climbers': MovementType.squat,
  'diamond_pushups': MovementType.push,
  'wide_pushups': MovementType.push,
  'pike_pushups': MovementType.push,
  'tricep_dips_chair': MovementType.push,
  'plank_shoulder_taps': MovementType.push,
  'single_leg_glute_bridge': MovementType.hinge,
  'stepups_chair': MovementType.squat,
  'wall_sit': MovementType.squat,
  'calf_raises': MovementType.squat,
  'bicycle_crunches': MovementType.squat,
  'leg_raises': MovementType.squat,
  'dead_bug': MovementType.squat,

  // ============================================================================
  // HOME - HIIT CIRCUITS
  // ============================================================================
  'burpees': MovementType.squat,
  'jump_squats': MovementType.squat,
  'high_knees': MovementType.squat,
  'jump_lunges': MovementType.squat,
  'squat_jumps': MovementType.squat,
  'plank_jacks': MovementType.squat,
  'jumping_jacks': MovementType.squat,
  'butt_kicks': MovementType.squat,
  'skaters': MovementType.squat,

  // ============================================================================
  // HOME - BOOTY
  // ============================================================================
  'donkey_kicks': MovementType.hinge,
  'fire_hydrants': MovementType.squat,
  'clamshells': MovementType.squat,
  'frog_pumps': MovementType.hinge,
  'sumo_squat_pulse': MovementType.squat,
  'curtsy_lunges': MovementType.squat,
  'glute_bridge_hold': MovementType.hinge,
  'donkey_kick_pulses': MovementType.hinge,
  'squat_to_kickback': MovementType.squat,
  'single_leg_deadlift': MovementType.hinge,
  'banded_squat': MovementType.squat,
  'banded_glute_bridge': MovementType.hinge,
  'banded_clamshell': MovementType.squat,
  'banded_kickback': MovementType.hinge,
  'banded_lateral_walk': MovementType.squat,
  'banded_fire_hydrant': MovementType.squat,

  // ============================================================================
  // HOME - RECOVERY & STRETCHES
  // ============================================================================
  'cat_cow': MovementType.squat,
  'worlds_greatest_stretch': MovementType.squat,
  'pigeon_pose': MovementType.squat,
  'hamstring_stretch': MovementType.squat,
  'quad_stretch': MovementType.squat,
  'chest_doorway_stretch': MovementType.squat,
  'childs_pose': MovementType.squat,
  '90_90_stretch': MovementType.squat,
  'frog_stretch': MovementType.squat,
  'hip_flexor_stretch': MovementType.squat,
  'happy_baby': MovementType.squat,
  'butterfly_stretch': MovementType.squat,

  // ============================================================================
  // ALIASES (different names for same exercises)
  // ============================================================================
  'push_ups': MovementType.push,
  'pull_ups': MovementType.pull,
  'chin_ups': MovementType.pull,
  'lat_pulldowns': MovementType.pull,
  'bent_over_rows': MovementType.pull,
  'cable_rows': MovementType.pull,
  't_bar_rows': MovementType.pull,
  'hammer_curls': MovementType.curl,
  'preacher_curls': MovementType.curl,
  'concentration_curls': MovementType.curl,
  'cable_curls': MovementType.curl,
  'tricep_extensions': MovementType.curl,
  'overhead_tricep': MovementType.curl,
  'tricep_kickbacks': MovementType.curl,
  'ez_bar_curl': MovementType.curl,
  'incline_curls': MovementType.curl,
  'lateral_raises': MovementType.push,
  'front_raises': MovementType.push,
  'rear_delt_flys': MovementType.push,
  'reverse_flys': MovementType.pull,
  'shrugs': MovementType.push,
  'upright_rows': MovementType.pull,
  'squats': MovementType.squat,
  'sit_ups': MovementType.squat,
  'situps': MovementType.squat,
  'crunches': MovementType.squat,
  'decline_sit_up': MovementType.squat,
  'russian_twists': MovementType.squat,
  'superman': MovementType.squat,
  'sprawls': MovementType.squat,
  'star_jumps': MovementType.squat,
  'tuck_jumps': MovementType.squat,
  'bear_crawls': MovementType.squat,
  'lateral_hops': MovementType.squat,
  'step_ups': MovementType.squat,
  'leg_extensions': MovementType.squat,
  'leg_curls': MovementType.squat,
  'wall_sits': MovementType.squat,
  'reverse_lunges': MovementType.squat,
  'stiff_leg_deadlift': MovementType.hinge,
  'good_mornings': MovementType.hinge,
  'bench_press': MovementType.push,
  'incline_press': MovementType.push,
  'decline_press': MovementType.push,
  'dumbbell_press': MovementType.push,
  'close_grip_push_ups': MovementType.push,
  'dips_chest': MovementType.push,
  'pike_push_ups': MovementType.push,
  'plank_to_pushup': MovementType.push,
  'chest_flys': MovementType.push,
  'cable_crossovers': MovementType.push,
  'cable_lateral_raise': MovementType.push,
  'pendlay_row': MovementType.pull,
};
  
  // Custom config per exercise (optional overrides)
  static final Map<String, Map<String, dynamic>> _exerciseConfig = {
    // Squats
    'squats': {'trigger': 0.78, 'reset': 0.92, 'cueGood': 'Depth!', 'cueBad': 'Hit parallel!'},
    'jump_squats': {'trigger': 0.80, 'reset': 0.92, 'cueGood': 'Explode!', 'cueBad': 'Lower!'},
    'wall_sits': {'trigger': 0.80, 'reset': 0.85, 'cueGood': 'Hold!', 'cueBad': '90 degrees!'},
    'lunges': {'trigger': 0.78, 'reset': 0.92, 'cueGood': 'Great step!', 'cueBad': 'Deeper!'},
    'burpees': {'trigger': 0.65, 'reset': 0.90, 'cueGood': 'Explode!', 'cueBad': 'Chest down!'},
    
    // Hinges
    'deadlift': {'trigger': 105.0, 'reset': 165.0, 'cueGood': 'Lockout!', 'cueBad': 'Hips forward!'},
    'glute_bridge': {'trigger': 160.0, 'reset': 110.0, 'cueGood': 'Squeeze!', 'cueBad': 'Hips up!'},
    'kettlebell_swings': {'trigger': 110.0, 'reset': 170.0, 'cueGood': 'Snap!', 'cueBad': 'Hips drive!'},
    
    // Pulls
    'pull_ups': {'trigger': 75.0, 'reset': 155.0, 'cueGood': 'Chin up!', 'cueBad': 'Full hang!'},
    'bent_over_rows': {'trigger': 80.0, 'reset': 150.0, 'cueGood': 'Pull!', 'cueBad': 'Squeeze lats!'},
    
    // Curls
    'bicep_curls': {'cueGood': 'Full curl!', 'cueBad': 'Squeeze!'},
  };
}

