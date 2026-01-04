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
    // SQUAT
    'squats': MovementType.squat,
    'air_squats': MovementType.squat,
    'goblet_squats': MovementType.squat,
    'front_squat': MovementType.squat,
    'back_squat': MovementType.squat,
    'sumo_squat': MovementType.squat,
    'jump_squats': MovementType.squat,
    'box_jumps': MovementType.squat,
    'banded_squat': MovementType.squat,
    'wall_sits': MovementType.squat,
    'lunges': MovementType.squat,
    'walking_lunges': MovementType.squat,
    'reverse_lunges': MovementType.squat,
    'curtsy_lunges': MovementType.squat,
    'jump_lunges': MovementType.squat,
    'bulgarian_split_squat': MovementType.squat,
    'step_ups': MovementType.squat,
    'leg_press': MovementType.squat,
    'leg_extensions': MovementType.squat,
    'leg_curls': MovementType.squat,
    'calf_raises': MovementType.squat,
    'sit_ups': MovementType.squat,
    'situps': MovementType.squat,
    'crunches': MovementType.squat,
    'decline_sit_up': MovementType.squat,
    'leg_raises': MovementType.squat,
    'hanging_leg_raise': MovementType.squat,
    'mountain_climbers': MovementType.squat,
    'bicycle_crunches': MovementType.squat,
    'russian_twists': MovementType.squat,
    'woodchoppers': MovementType.squat,
    'plank': MovementType.squat,
    'plank_hold': MovementType.squat,
    'side_plank': MovementType.squat,
    'superman_raises': MovementType.squat,
    'superman': MovementType.squat,
    'dead_bug': MovementType.squat,
    'burpees': MovementType.squat,
    'sprawls': MovementType.squat,
    'jumping_jacks': MovementType.squat,
    'star_jumps': MovementType.squat,
    'high_knees': MovementType.squat,
    'butt_kicks': MovementType.squat,
    'tuck_jumps': MovementType.squat,
    'bear_crawls': MovementType.squat,
    'skaters': MovementType.squat,
    'lateral_hops': MovementType.squat,
    'fire_hydrants': MovementType.squat,
    'banded_fire_hydrant': MovementType.squat,
    'clamshells': MovementType.squat,
    'banded_clamshell': MovementType.squat,
    'childs_pose': MovementType.squat,
    'cat_cow': MovementType.squat,
    'worlds_greatest_stretch': MovementType.squat,
    'hamstring_stretch': MovementType.squat,
    'quad_stretch': MovementType.squat,
    'hip_flexor_stretch': MovementType.squat,
    'pigeon_pose': MovementType.squat,
    'butterfly_stretch': MovementType.squat,
    'frog_stretch': MovementType.squat,
    '90_90_stretch': MovementType.squat,
    
    // HINGE
    'deadlift': MovementType.hinge,
    'sumo_deadlift': MovementType.hinge,
    'romanian_deadlift': MovementType.hinge,
    'single_leg_deadlift': MovementType.hinge,
    'stiff_leg_deadlift': MovementType.hinge,
    'kettlebell_swings': MovementType.hinge,
    'cable_pullthrough': MovementType.hinge,
    'glute_bridge': MovementType.hinge,
    'hip_thrust': MovementType.hinge,
    'single_leg_glute_bridge': MovementType.hinge,
    'banded_glute_bridge': MovementType.hinge,
    'frog_pumps': MovementType.hinge,
    'good_mornings': MovementType.hinge,
    'donkey_kicks': MovementType.hinge,
    'donkey_kick_pulses': MovementType.hinge,
    'banded_kickback': MovementType.hinge,
    
    // PUSH
    'pushups': MovementType.push,
    'push_ups': MovementType.push,
    'wide_pushups': MovementType.push,
    'diamond_pushups': MovementType.push,
    'close_grip_push_ups': MovementType.push,
    'bench_press': MovementType.push,
    'incline_press': MovementType.push,
    'decline_press': MovementType.push,
    'dumbbell_press': MovementType.push,
    'close_grip_bench': MovementType.push,
    'tricep_dips': MovementType.push,
    'tricep_dips_chair': MovementType.push,
    'dips_chest': MovementType.push,
    'overhead_press': MovementType.push,
    'shoulder_press': MovementType.push,
    'arnold_press': MovementType.push,
    'seated_db_press': MovementType.push,
    'pike_push_ups': MovementType.push,
    'plank_to_pushup': MovementType.push,
    'chest_flys': MovementType.push,
    'cable_crossovers': MovementType.push,
    'dumbbell_flyes': MovementType.push,
    'lateral_raises': MovementType.push,
    'front_raises': MovementType.push,
    'cable_lateral_raise': MovementType.push,
    'rear_delt_flys': MovementType.push,
    'upright_rows': MovementType.push,
    'shrugs': MovementType.push,
    
    // PULL
    'pull_ups': MovementType.pull,
    'pullups': MovementType.pull,
    'chin_ups': MovementType.pull,
    'lat_pulldowns': MovementType.pull,
    'lat_pulldown': MovementType.pull,
    'bent_over_rows': MovementType.pull,
    'barbell_row': MovementType.pull,
    'pendlay_row': MovementType.pull,
    'cable_rows': MovementType.pull,
    'seated_cable_row': MovementType.pull,
    't_bar_rows': MovementType.pull,
    'single_arm_db_row': MovementType.pull,
    'dumbbell_row': MovementType.pull,
    'renegade_rows': MovementType.pull,
    'face_pulls': MovementType.pull,
    'reverse_flys': MovementType.pull,
    
    // CURL
    'bicep_curls': MovementType.curl,
    'hammer_curls': MovementType.curl,
    'barbell_curl': MovementType.curl,
    'ez_bar_curl': MovementType.curl,
    'preacher_curls': MovementType.curl,
    'concentration_curls': MovementType.curl,
    'cable_curls': MovementType.curl,
    'incline_curls': MovementType.curl,
    'tricep_extensions': MovementType.curl,
    'overhead_tricep': MovementType.curl,
    'tricep_pushdown': MovementType.curl,
    'skull_crushers': MovementType.curl,
    'tricep_kickbacks': MovementType.curl,
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

