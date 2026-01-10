import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'base_pattern.dart';
import 'squat_pattern.dart';
import 'push_pattern.dart';
import 'pull_pattern.dart';
import 'hinge_pattern.dart';
import 'curl_pattern.dart';
import 'knee_drive_pattern.dart';
import 'hold_pattern.dart';
import 'rotation_pattern.dart';
import 'calf_pattern.dart';

/// Pattern types
enum PatternType { squat, push, pull, hinge, curl, kneeDrive, hold, rotation, calf }

/// Exercise configuration
class ExerciseConfig {
  final PatternType patternType;
  final Map<String, dynamic> params;
  
  const ExerciseConfig({
    required this.patternType,
    this.params = const {},
  });
}

/// =============================================================================
/// MOVEMENT ENGINE - Master Controller
/// =============================================================================
/// Maps 200+ exercises to their pattern type.
/// Creates the right pattern instance for each exercise.
/// =============================================================================

class MovementEngine {
  BasePattern? _activePattern;
  String? _currentExerciseId;
  
  // Getters - delegate to active pattern
  int get repCount => _activePattern?.repCount ?? 0;
  String get feedback => _activePattern?.feedback ?? '';
  double get chargeProgress => _activePattern?.chargeProgress ?? 0;
  bool get justHitTrigger => _activePattern?.justHitTrigger ?? false;
  bool get isLocked => _activePattern?.isLocked ?? false;
  RepState get state => _activePattern?.state ?? RepState.ready;
  String? get currentExerciseId => _currentExerciseId;
  
  /// Set the current exercise - creates the appropriate pattern
  void setExercise(String exerciseId) {
    _currentExerciseId = exerciseId.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');

    final config = exercises[_currentExerciseId];
    if (config == null) {
      // Default to squat pattern for unknown exercises
      _activePattern = SquatPattern();
      return;
    }

    _activePattern = _createPattern(config);
  }

  /// LEGACY: Alias for setExercise for backwards compatibility
  void loadExercise(String exerciseId) => setExercise(exerciseId);

  /// Check if an exercise has a pattern configured
  static bool hasPattern(String exerciseId) {
    final normalized = exerciseId.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return exercises.containsKey(normalized);
  }

  /// Capture baseline position (Map version)
  void captureBaseline(dynamic landmarks) {
    if (_activePattern == null) return;

    // Handle both List<PoseLandmark> and Map<PoseLandmarkType, PoseLandmark>
    if (landmarks is List<PoseLandmark>) {
      final map = {for (var lm in landmarks) lm.type: lm};
      _activePattern!.captureBaseline(map);
    } else if (landmarks is Map<PoseLandmarkType, PoseLandmark>) {
      _activePattern!.captureBaseline(landmarks);
    }
  }

  /// Process a frame - returns true if rep was counted
  bool processFrame(dynamic landmarks) {
    if (_activePattern == null) return false;

    // Handle both List<PoseLandmark> and Map<PoseLandmarkType, PoseLandmark>
    if (landmarks is List<PoseLandmark>) {
      final map = {for (var lm in landmarks) lm.type: lm};
      return _activePattern!.processFrame(map);
    } else if (landmarks is Map<PoseLandmarkType, PoseLandmark>) {
      return _activePattern!.processFrame(landmarks);
    }

    return false;
  }
  
  /// Reset the current pattern
  void reset() {
    _activePattern?.reset();
  }
  
  /// Create pattern instance from config
  BasePattern _createPattern(ExerciseConfig config) {
    switch (config.patternType) {
      case PatternType.squat:
        return SquatPattern(
          triggerPercent: config.params['triggerPercent'] ?? 0.78,
          resetPercent: config.params['resetPercent'] ?? 0.92,
          cueGood: config.params['cueGood'] ?? 'Depth!',
          cueBad: config.params['cueBad'] ?? 'Lower!',
        );
        
      case PatternType.push:
        return PushPattern(
          inverted: config.params['inverted'] ?? false,
          cueGood: config.params['cueGood'] ?? 'Perfect!',
          cueBad: config.params['cueBad'] ?? 'Go lower!',
        );
        
      case PatternType.pull:
        return PullPattern(
          triggerAngle: config.params['triggerAngle'] ?? 75,
          resetAngle: config.params['resetAngle'] ?? 155,
          cueGood: config.params['cueGood'] ?? 'Chin up!',
          cueBad: config.params['cueBad'] ?? 'Full hang!',
        );
        
      case PatternType.hinge:
        return HingePattern(
          inverted: config.params['inverted'] ?? false,
          triggerAngle: config.params['triggerAngle'] ?? 105,
          resetAngle: config.params['resetAngle'] ?? 165,
          cueGood: config.params['cueGood'] ?? 'Lockout!',
          cueBad: config.params['cueBad'] ?? 'Hips forward!',
        );
        
      case PatternType.curl:
        return CurlPattern(
          cueGood: config.params['cueGood'] ?? 'Full curl!',
          cueBad: config.params['cueBad'] ?? 'Squeeze!',
        );
        
      case PatternType.kneeDrive:
        return KneeDrivePattern(
          triggerPercent: config.params['triggerPercent'] ?? 0.15,
          cueGood: config.params['cueGood'] ?? 'Drive!',
          cueBad: config.params['cueBad'] ?? 'Knees up!',
        );
        
      case PatternType.hold:
        return HoldPattern(
          holdType: config.params['holdType'] ?? HoldType.plank,
          cueGood: config.params['cueGood'] ?? 'Hold it!',
          cueBad: config.params['cueBad'] ?? 'Get in position!',
        );
        
      case PatternType.rotation:
        return RotationPattern(
          triggerAngle: config.params['triggerAngle'] ?? 45,
          cueGood: config.params['cueGood'] ?? 'Twist!',
          cueBad: config.params['cueBad'] ?? 'Rotate more!',
        );
        
      case PatternType.calf:
        return CalfPattern(
          cueGood: config.params['cueGood'] ?? 'Squeeze!',
          cueBad: config.params['cueBad'] ?? 'Higher!',
        );
    }
  }
  
  /// ==========================================================================
  /// EXERCISE DATABASE - 200+ exercises mapped to patterns
  /// ==========================================================================
  static const Map<String, ExerciseConfig> exercises = {
    
    // =========================================================================
    // ===== SQUAT PATTERN =====
    // =========================================================================
    'squat': ExerciseConfig(patternType: PatternType.squat),
    'squats': ExerciseConfig(patternType: PatternType.squat), // PLURAL ALIAS
    'air_squat': ExerciseConfig(patternType: PatternType.squat),
    'air_squats': ExerciseConfig(patternType: PatternType.squat), // PLURAL ALIAS
    'bodyweight_squat': ExerciseConfig(patternType: PatternType.squat),
    'bodyweight_squats': ExerciseConfig(patternType: PatternType.squat), // PLURAL ALIAS
    'goblet_squat': ExerciseConfig(patternType: PatternType.squat),
    'goblet_squats': ExerciseConfig(patternType: PatternType.squat), // PLURAL ALIAS
    'barbell_squat': ExerciseConfig(patternType: PatternType.squat),
    'back_squat': ExerciseConfig(patternType: PatternType.squat),
    'front_squat': ExerciseConfig(patternType: PatternType.squat),
    'sumo_squat': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'sumo_squats': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}), // PLURAL
    'split_squat': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'bulgarian_split_squat': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}),
    'lunges': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}), // PLURAL ALIAS
    'walking_lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}),
    'walking_lunges': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}), // PLURAL
    'reverse_lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}),
    'reverse_lunges': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}), // PLURAL
    'lateral_lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}),
    'curtsy_lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}),
    'curtsy_lunges': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}), // PLURAL
    'jump_lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90, 'cueGood': 'Explode!', 'cueBad': 'Lower!'}),
    'jump_lunges': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90, 'cueGood': 'Explode!', 'cueBad': 'Lower!'}), // PLURAL
    'step_up': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80}),
    'step_ups': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80}), // PLURAL
    'stepups_chair': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80}), // HOME VARIANT
    'box_step_up': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80}),
    'box_stepups': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80}), // PLURAL
    'leg_press': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'leg_press_high': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}), // FEET HIGH VARIANT
    'thruster': ExerciseConfig(patternType: PatternType.squat),
    'thrusters': ExerciseConfig(patternType: PatternType.squat), // PLURAL
    'wall_ball': ExerciseConfig(patternType: PatternType.squat),
    'wall_balls': ExerciseConfig(patternType: PatternType.squat), // PLURAL
    
    // SQUAT PATTERN - EXPLOSIVE VARIANTS
    'jump_squat': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80, 'cueGood': 'Explode!', 'cueBad': 'Lower!'}),
    'jump_squats': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80, 'cueGood': 'Explode!', 'cueBad': 'Lower!'}), // PLURAL
    'squat_jump': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80, 'cueGood': 'Explode!', 'cueBad': 'Lower!'}),
    'squat_jumps': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80, 'cueGood': 'Explode!', 'cueBad': 'Lower!'}), // PLURAL
    'box_jump': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'cueGood': 'Explode!', 'cueBad': 'Load up!'}),
    'box_jumps': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'cueGood': 'Explode!', 'cueBad': 'Load up!'}), // PLURAL
    'tuck_jump': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80, 'cueGood': 'Knees up!', 'cueBad': 'Higher!'}),
    'tuck_jumps': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80, 'cueGood': 'Knees up!', 'cueBad': 'Higher!'}), // PLURAL
    'star_jump': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.85, 'cueGood': 'Explode!', 'cueBad': 'Arms up!'}),
    'star_jumps': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.85, 'cueGood': 'Explode!', 'cueBad': 'Arms up!'}), // PLURAL
    'jumping_jack': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.90, 'cueGood': 'Jump!', 'cueBad': 'Arms up!'}),
    'jumping_jacks': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.90, 'cueGood': 'Jump!', 'cueBad': 'Arms up!'}), // PLURAL
    'lateral_hop': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.85}),
    'lateral_hops': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.85}), // PLURAL
    
    // SQUAT PATTERN - BURPEE (squat component)
    'burpee': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.65, 'resetPercent': 0.90, 'cueGood': 'Explode!', 'cueBad': 'Chest down!'}),
    'burpees': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.65, 'resetPercent': 0.90, 'cueGood': 'Explode!', 'cueBad': 'Chest down!'}), // PLURAL
    'sprawl': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.65, 'resetPercent': 0.90}),
    'sprawls': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.65, 'resetPercent': 0.90}), // PLURAL
    
    // SQUAT PATTERN - PULSE VARIANTS
    'sumo_squat_pulse': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80, 'resetPercent': 0.85, 'cueGood': 'Pulse!', 'cueBad': 'Stay low!'}),
    'squat_pulse': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80, 'resetPercent': 0.85, 'cueGood': 'Pulse!', 'cueBad': 'Stay low!'}),
    'squat_to_kickback': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.78}),
    
    // SQUAT PATTERN - BANDED
    'banded_squat': ExerciseConfig(patternType: PatternType.squat),
    'banded_lateral_walk': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.90, 'cueGood': 'Step!', 'cueBad': 'Wider!'}),
    
    // =========================================================================
    // ===== PUSH PATTERN =====
    // =========================================================================
    'pushup': ExerciseConfig(patternType: PatternType.push),
    'pushups': ExerciseConfig(patternType: PatternType.push), // PLURAL ALIAS
    'push_up': ExerciseConfig(patternType: PatternType.push),
    'push_ups': ExerciseConfig(patternType: PatternType.push), // PLURAL ALIAS
    'wide_pushup': ExerciseConfig(patternType: PatternType.push),
    'wide_pushups': ExerciseConfig(patternType: PatternType.push), // PLURAL ALIAS
    'diamond_pushup': ExerciseConfig(patternType: PatternType.push),
    'diamond_pushups': ExerciseConfig(patternType: PatternType.push), // PLURAL ALIAS
    'close_grip_pushup': ExerciseConfig(patternType: PatternType.push),
    'close_grip_push_ups': ExerciseConfig(patternType: PatternType.push), // VARIANT
    'decline_pushup': ExerciseConfig(patternType: PatternType.push),
    'decline_pushups': ExerciseConfig(patternType: PatternType.push), // PLURAL
    'incline_pushup': ExerciseConfig(patternType: PatternType.push),
    'incline_pushups': ExerciseConfig(patternType: PatternType.push), // PLURAL
    'pike_pushup': ExerciseConfig(patternType: PatternType.push),
    'pike_pushups': ExerciseConfig(patternType: PatternType.push), // PLURAL ALIAS
    'pike_push_ups': ExerciseConfig(patternType: PatternType.push), // VARIANT
    'archer_pushup': ExerciseConfig(patternType: PatternType.push),
    'clap_pushup': ExerciseConfig(patternType: PatternType.push),
    'plank_to_pushup': ExerciseConfig(patternType: PatternType.push),
    
    // PUSH PATTERN - BENCH PRESS
    'bench_press': ExerciseConfig(patternType: PatternType.push),
    'barbell_bench_press': ExerciseConfig(patternType: PatternType.push),
    'dumbbell_bench_press': ExerciseConfig(patternType: PatternType.push),
    'incline_bench_press': ExerciseConfig(patternType: PatternType.push),
    'incline_press': ExerciseConfig(patternType: PatternType.push),
    'incline_db_press': ExerciseConfig(patternType: PatternType.push), // MISSING - ADDED
    'decline_bench_press': ExerciseConfig(patternType: PatternType.push),
    'decline_press': ExerciseConfig(patternType: PatternType.push),
    'dumbbell_press': ExerciseConfig(patternType: PatternType.push),
    'close_grip_bench': ExerciseConfig(patternType: PatternType.push),
    'machine_chest_press': ExerciseConfig(patternType: PatternType.push),
    
    // PUSH PATTERN - OVERHEAD (INVERTED)
    'overhead_press': ExerciseConfig(patternType: PatternType.push, params: {'inverted': true, 'cueGood': 'Lockout!', 'cueBad': 'Press higher!'}),
    'shoulder_press': ExerciseConfig(patternType: PatternType.push, params: {'inverted': true, 'cueGood': 'Lockout!', 'cueBad': 'Press higher!'}),
    'military_press': ExerciseConfig(patternType: PatternType.push, params: {'inverted': true, 'cueGood': 'Lockout!', 'cueBad': 'Press higher!'}),
    'arnold_press': ExerciseConfig(patternType: PatternType.push, params: {'inverted': true, 'cueGood': 'Lockout!', 'cueBad': 'Press higher!'}),
    'push_press': ExerciseConfig(patternType: PatternType.push, params: {'inverted': true, 'cueGood': 'Lockout!', 'cueBad': 'Press higher!'}),
    'seated_db_press': ExerciseConfig(patternType: PatternType.push, params: {'inverted': true, 'cueGood': 'Lockout!', 'cueBad': 'Press higher!'}), // MISSING - ADDED
    'seated_shoulder_press': ExerciseConfig(patternType: PatternType.push, params: {'inverted': true, 'cueGood': 'Lockout!', 'cueBad': 'Press higher!'}),
    'landmine_press': ExerciseConfig(patternType: PatternType.push),
    
    // PUSH PATTERN - DIPS
    'dips': ExerciseConfig(patternType: PatternType.push),
    'dip': ExerciseConfig(patternType: PatternType.push),
    'tricep_dips': ExerciseConfig(patternType: PatternType.push),
    'tricep_dip': ExerciseConfig(patternType: PatternType.push),
    'tricep_dips_chair': ExerciseConfig(patternType: PatternType.push), // HOME VARIANT - ADDED
    'bench_dips': ExerciseConfig(patternType: PatternType.push),
    'ring_dips': ExerciseConfig(patternType: PatternType.push),
    'chest_dips': ExerciseConfig(patternType: PatternType.push),
    'dips_chest': ExerciseConfig(patternType: PatternType.push), // VARIANT
    
    // PUSH PATTERN - FLYES
    'chest_fly': ExerciseConfig(patternType: PatternType.push),
    'chest_flys': ExerciseConfig(patternType: PatternType.push), // PLURAL
    'dumbbell_fly': ExerciseConfig(patternType: PatternType.push),
    'dumbbell_flyes': ExerciseConfig(patternType: PatternType.push), // PLURAL - ADDED
    'cable_fly': ExerciseConfig(patternType: PatternType.push),
    'cable_crossover': ExerciseConfig(patternType: PatternType.push),
    'cable_crossovers': ExerciseConfig(patternType: PatternType.push), // PLURAL
    'machine_chest_fly': ExerciseConfig(patternType: PatternType.push),
    
    // PUSH PATTERN - PLANK VARIANTS
    'plank_shoulder_taps': ExerciseConfig(patternType: PatternType.push, params: {'cueGood': 'Tap!', 'cueBad': 'Stay stable!'}), // ADDED
    'plank_shoulder_tap': ExerciseConfig(patternType: PatternType.push, params: {'cueGood': 'Tap!', 'cueBad': 'Stay stable!'}),
    
    // =========================================================================
    // ===== PULL PATTERN =====
    // =========================================================================
    'pullup': ExerciseConfig(patternType: PatternType.pull),
    'pullups': ExerciseConfig(patternType: PatternType.pull), // PLURAL ALIAS
    'pull_up': ExerciseConfig(patternType: PatternType.pull),
    'pull_ups': ExerciseConfig(patternType: PatternType.pull), // PLURAL ALIAS
    'chinup': ExerciseConfig(patternType: PatternType.pull),
    'chinups': ExerciseConfig(patternType: PatternType.pull), // PLURAL
    'chin_up': ExerciseConfig(patternType: PatternType.pull),
    'chin_ups': ExerciseConfig(patternType: PatternType.pull), // PLURAL
    'wide_grip_pullup': ExerciseConfig(patternType: PatternType.pull),
    'close_grip_pullup': ExerciseConfig(patternType: PatternType.pull),
    'neutral_grip_pullup': ExerciseConfig(patternType: PatternType.pull),
    'muscle_up': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 60}),
    
    // PULL PATTERN - PULLDOWNS
    'lat_pulldown': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 80, 'resetAngle': 160}),
    'lat_pulldowns': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 80, 'resetAngle': 160}), // PLURAL
    'cable_pulldown': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 80, 'resetAngle': 160}),
    
    // PULL PATTERN - ROWS
    'bent_over_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'bent_over_rows': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}), // PLURAL
    'bent_rows': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}), // ALIAS
    'barbell_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'barbell_rows': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}), // PLURAL
    'pendlay_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'dumbbell_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'dumbbell_rows': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}), // PLURAL
    'single_arm_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'single_arm_db_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}), // VARIANT - ADDED
    'cable_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 75, 'resetAngle': 155}),
    'cable_rows': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 75, 'resetAngle': 155}), // PLURAL
    'seated_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 75, 'resetAngle': 155}),
    'seated_cable_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 75, 'resetAngle': 155}), // VARIANT - ADDED
    't_bar_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'tbar_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}), // VARIANT - ADDED
    'tbar_rows': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}), // PLURAL
    'inverted_row': ExerciseConfig(patternType: PatternType.pull),
    'inverted_rows': ExerciseConfig(patternType: PatternType.pull), // PLURAL
    'renegade_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'renegade_rows': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}), // PLURAL - ADDED
    
    // PULL PATTERN - FACE PULLS / REAR DELTS
    'face_pull': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 80, 'resetAngle': 150}),
    'face_pulls': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 80, 'resetAngle': 150}), // PLURAL - ADDED
    'reverse_fly': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 90, 'resetAngle': 160}),
    'reverse_flys': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 90, 'resetAngle': 160}), // PLURAL
    'rear_delt_fly': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 90, 'resetAngle': 160}),
    'rear_delt_flys': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 90, 'resetAngle': 160}), // PLURAL
    
    // =========================================================================
    // ===== HINGE PATTERN =====
    // =========================================================================
    'deadlift': ExerciseConfig(patternType: PatternType.hinge),
    'deadlifts': ExerciseConfig(patternType: PatternType.hinge), // PLURAL
    'barbell_deadlift': ExerciseConfig(patternType: PatternType.hinge),
    'sumo_deadlift': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100}),
    'romanian_deadlift': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 95}),
    'rdl': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 95}),
    'stiff_leg_deadlift': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 90}),
    'single_leg_deadlift': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100}),
    'trap_bar_deadlift': ExerciseConfig(patternType: PatternType.hinge),
    'good_morning': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100}),
    'good_mornings': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100}), // PLURAL
    
    // HINGE PATTERN - KETTLEBELL
    'kettlebell_swing': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100, 'resetAngle': 170}),
    'kettlebell_swings': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100, 'resetAngle': 170}), // PLURAL - ADDED
    'kb_swing': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100, 'resetAngle': 170}),
    
    // HINGE PATTERN - GLUTE BRIDGES (INVERTED - angle INCREASES)
    'hip_thrust': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 170, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Thrust higher!'}),
    'hip_thrusts': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 170, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Thrust higher!'}), // PLURAL
    'barbell_hip_thrust': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 170, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Thrust higher!'}),
    'glute_bridge': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 165, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Hips up!'}),
    'glute_bridges': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 165, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Hips up!'}), // PLURAL
    'single_leg_glute_bridge': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 165, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Hips up!'}),
    'glute_bridge_single': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 165, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Hips up!'}), // VARIANT - ADDED
    'glute_bridge_hold': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 165, 'resetAngle': 120, 'cueGood': 'Hold!', 'cueBad': 'Hips up!'}), // HOLD VARIANT - ADDED
    'banded_glute_bridge': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 165, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Hips up!'}), // BANDED - ADDED
    'frog_pump': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Pump!'}),
    'frog_pumps': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Pump!'}), // PLURAL - ADDED
    
    // HINGE PATTERN - CABLE/MACHINE
    'cable_pull_through': ExerciseConfig(patternType: PatternType.hinge),
    'cable_pullthrough': ExerciseConfig(patternType: PatternType.hinge), // VARIANT - ADDED
    
    // HINGE PATTERN - EXTENSIONS
    'back_extension': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100, 'resetAngle': 170}),
    'back_extensions': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100, 'resetAngle': 170}), // PLURAL
    'hyperextension': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100, 'resetAngle': 170}),
    'hyperextensions': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100, 'resetAngle': 170}), // PLURAL
    
    // HINGE PATTERN - SUPERMAN (INVERTED)
    'superman': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 130, 'cueGood': 'Hold!', 'cueBad': 'Lift higher!'}),
    'supermans': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 130, 'cueGood': 'Hold!', 'cueBad': 'Lift higher!'}), // PLURAL
    'superman_raise': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 130, 'cueGood': 'Hold!', 'cueBad': 'Lift higher!'}),
    'superman_raises': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 130, 'cueGood': 'Hold!', 'cueBad': 'Lift higher!'}), // PLURAL - ADDED
    'superman_hold': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    
    // HINGE PATTERN - DONKEY KICKS (INVERTED - hip extension)
    'donkey_kick': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Kick higher!'}),
    'donkey_kicks': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Kick higher!'}), // PLURAL - ADDED
    'donkey_kick_pulses': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 155, 'resetAngle': 145, 'cueGood': 'Pulse!', 'cueBad': 'Keep kicking!'}), // PULSE - ADDED
    'donkey_kicks_cable': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Kick higher!'}), // CABLE - ADDED
    'cable_kickback': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Kick higher!'}), // ADDED
    'glute_kickback': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Kick higher!'}), // ADDED
    'banded_kickback': ExerciseConfig(patternType: PatternType.hinge, params: {'inverted': true, 'triggerAngle': 160, 'resetAngle': 120, 'cueGood': 'Squeeze!', 'cueBad': 'Kick higher!'}), // BANDED - ADDED
    
    // =========================================================================
    // ===== CURL PATTERN =====
    // =========================================================================
    'bicep_curl': ExerciseConfig(patternType: PatternType.curl),
    'bicep_curls': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'barbell_curl': ExerciseConfig(patternType: PatternType.curl),
    'barbell_curls': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'dumbbell_curl': ExerciseConfig(patternType: PatternType.curl),
    'dumbbell_curls': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'hammer_curl': ExerciseConfig(patternType: PatternType.curl),
    'hammer_curls': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'preacher_curl': ExerciseConfig(patternType: PatternType.curl),
    'preacher_curls': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'concentration_curl': ExerciseConfig(patternType: PatternType.curl),
    'concentration_curls': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'cable_curl': ExerciseConfig(patternType: PatternType.curl),
    'cable_curls': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'incline_curl': ExerciseConfig(patternType: PatternType.curl),
    'incline_curls': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'spider_curl': ExerciseConfig(patternType: PatternType.curl),
    'ez_bar_curl': ExerciseConfig(patternType: PatternType.curl),
    'reverse_curl': ExerciseConfig(patternType: PatternType.curl),
    'zottman_curl': ExerciseConfig(patternType: PatternType.curl),
    
    // CURL PATTERN - TRICEP EXTENSIONS
    'tricep_extension': ExerciseConfig(patternType: PatternType.curl),
    'tricep_extensions': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'overhead_tricep_extension': ExerciseConfig(patternType: PatternType.curl),
    'overhead_tricep_ext': ExerciseConfig(patternType: PatternType.curl), // VARIANT - ADDED
    'overhead_tricep': ExerciseConfig(patternType: PatternType.curl), // VARIANT
    'tricep_pushdown': ExerciseConfig(patternType: PatternType.curl),
    'tricep_pushdowns': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'rope_pushdown': ExerciseConfig(patternType: PatternType.curl),
    'skull_crusher': ExerciseConfig(patternType: PatternType.curl),
    'skull_crushers': ExerciseConfig(patternType: PatternType.curl), // PLURAL - ADDED
    'tricep_kickback': ExerciseConfig(patternType: PatternType.curl),
    'tricep_kickbacks': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    
    // CURL PATTERN - SHOULDER RAISES
    'lateral_raise': ExerciseConfig(patternType: PatternType.curl),
    'lateral_raises': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'cable_lateral_raise': ExerciseConfig(patternType: PatternType.curl),
    'front_raise': ExerciseConfig(patternType: PatternType.curl),
    'front_raises': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'upright_row': ExerciseConfig(patternType: PatternType.curl),
    'upright_rows': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    
    // CURL PATTERN - SHRUGS
    'shrug': ExerciseConfig(patternType: PatternType.curl),
    'shrugs': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'barbell_shrug': ExerciseConfig(patternType: PatternType.curl),
    'barbell_shrugs': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'dumbbell_shrug': ExerciseConfig(patternType: PatternType.curl),
    'dumbbell_shrugs': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    
    // CURL PATTERN - WRIST
    'wrist_curl': ExerciseConfig(patternType: PatternType.curl),
    'wrist_curls': ExerciseConfig(patternType: PatternType.curl), // PLURAL
    'reverse_wrist_curl': ExerciseConfig(patternType: PatternType.curl),
    
    // CURL PATTERN - LEG EXTENSIONS/CURLS (use elbow-like motion)
    'leg_extension': ExerciseConfig(patternType: PatternType.curl, params: {'cueGood': 'Squeeze!', 'cueBad': 'Full extension!'}), // ADDED
    'leg_extensions': ExerciseConfig(patternType: PatternType.curl, params: {'cueGood': 'Squeeze!', 'cueBad': 'Full extension!'}), // PLURAL
    'leg_curl': ExerciseConfig(patternType: PatternType.curl, params: {'cueGood': 'Squeeze!', 'cueBad': 'Full curl!'}), // ADDED
    'leg_curls': ExerciseConfig(patternType: PatternType.curl, params: {'cueGood': 'Squeeze!', 'cueBad': 'Full curl!'}), // PLURAL
    
    // =========================================================================
    // ===== KNEE DRIVE PATTERN =====
    // =========================================================================
    'mountain_climber': ExerciseConfig(patternType: PatternType.kneeDrive),
    'mountain_climbers': ExerciseConfig(patternType: PatternType.kneeDrive), // PLURAL
    'high_knee': ExerciseConfig(patternType: PatternType.kneeDrive),
    'high_knees': ExerciseConfig(patternType: PatternType.kneeDrive), // PLURAL - ADDED
    'running_in_place': ExerciseConfig(patternType: PatternType.kneeDrive),
    'bicycle_crunch': ExerciseConfig(patternType: PatternType.kneeDrive),
    'bicycle_crunches': ExerciseConfig(patternType: PatternType.kneeDrive), // PLURAL - ADDED
    'flutter_kick': ExerciseConfig(patternType: PatternType.kneeDrive),
    'flutter_kicks': ExerciseConfig(patternType: PatternType.kneeDrive), // PLURAL
    'scissor_kick': ExerciseConfig(patternType: PatternType.kneeDrive),
    'scissor_kicks': ExerciseConfig(patternType: PatternType.kneeDrive), // PLURAL
    'butt_kick': ExerciseConfig(patternType: PatternType.kneeDrive),
    'butt_kicks': ExerciseConfig(patternType: PatternType.kneeDrive), // PLURAL
    'a_skip': ExerciseConfig(patternType: PatternType.kneeDrive),
    'b_skip': ExerciseConfig(patternType: PatternType.kneeDrive),
    'skater': ExerciseConfig(patternType: PatternType.kneeDrive),
    'skaters': ExerciseConfig(patternType: PatternType.kneeDrive), // PLURAL
    'dead_bug': ExerciseConfig(patternType: PatternType.kneeDrive, params: {'cueGood': 'Extend!', 'cueBad': 'Opposite!'}), // ADDED
    'dead_bugs': ExerciseConfig(patternType: PatternType.kneeDrive, params: {'cueGood': 'Extend!', 'cueBad': 'Opposite!'}), // PLURAL
    'leg_raise': ExerciseConfig(patternType: PatternType.kneeDrive, params: {'cueGood': 'Legs up!', 'cueBad': 'Control!'}),
    'leg_raises': ExerciseConfig(patternType: PatternType.kneeDrive, params: {'cueGood': 'Legs up!', 'cueBad': 'Control!'}), // PLURAL - ADDED
    'hanging_leg_raise': ExerciseConfig(patternType: PatternType.kneeDrive, params: {'cueGood': 'Legs up!', 'cueBad': 'No swing!'}), // ADDED
    'hanging_leg_raises': ExerciseConfig(patternType: PatternType.kneeDrive, params: {'cueGood': 'Legs up!', 'cueBad': 'No swing!'}), // PLURAL
    
    // =========================================================================
    // ===== HOLD PATTERN =====
    // =========================================================================
    'plank': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'planks': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}), // PLURAL
    'plank_hold': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}), // VARIANT - ADDED
    'forearm_plank': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'high_plank': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'side_plank': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'side_planks': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}), // PLURAL
    'side_plank_left': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'side_plank_right': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'plank_jack': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'plank_jacks': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}), // PLURAL - ADDED
    
    // HOLD PATTERN - WALL SIT
    'wall_sit': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.wallSit}),
    'wall_sits': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.wallSit}), // PLURAL
    'wall_squat': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.wallSit}),
    
    // HOLD PATTERN - HANGS
    'dead_hang': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.hang}),
    'active_hang': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.hang}),
    
    // HOLD PATTERN - CORE HOLDS
    'l_sit': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'hollow_hold': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'hollow_body_hold': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'arch_hold': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'boat_pose': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    
    // HOLD PATTERN - STRETCHES
    'warrior_pose': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'tree_pose': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'downward_dog': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'childs_pose': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'pigeon_pose': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'cobra_stretch': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'cat_cow': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'hamstring_stretch': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'quad_stretch': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'hip_flexor_stretch': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'butterfly_stretch': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    '90_90_stretch': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'frog_stretch': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}),
    'happy_baby': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}), // ADDED
    'worlds_greatest_stretch': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}), // ADDED
    'chest_doorway_stretch': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.stretch}), // ADDED
    
    // =========================================================================
    // ===== ROTATION PATTERN =====
    // =========================================================================
    'russian_twist': ExerciseConfig(patternType: PatternType.rotation),
    'russian_twists': ExerciseConfig(patternType: PatternType.rotation), // PLURAL
    'woodchopper': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 60}),
    'woodchoppers': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 60}), // PLURAL
    'wood_chopper': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 60}),
    'cable_woodchop': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 60}),
    'cable_rotation': ExerciseConfig(patternType: PatternType.rotation),
    'oblique_twist': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 40}),
    'standing_rotation': ExerciseConfig(patternType: PatternType.rotation),
    'seated_rotation': ExerciseConfig(patternType: PatternType.rotation),
    'medicine_ball_twist': ExerciseConfig(patternType: PatternType.rotation),
    'landmine_rotation': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 50}),
    
    // ROTATION PATTERN - HIP ROTATIONS
    'fire_hydrant': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 40, 'cueGood': 'Open!', 'cueBad': 'Lift higher!'}),
    'fire_hydrants': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 40, 'cueGood': 'Open!', 'cueBad': 'Lift higher!'}), // PLURAL - ADDED
    'banded_fire_hydrant': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 40, 'cueGood': 'Open!', 'cueBad': 'Lift higher!'}), // BANDED - ADDED
    'clamshell': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 40, 'cueGood': 'Open!', 'cueBad': 'Squeeze!'}),
    'clamshells': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 40, 'cueGood': 'Open!', 'cueBad': 'Squeeze!'}), // PLURAL - ADDED
    'banded_clamshell': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 40, 'cueGood': 'Open!', 'cueBad': 'Squeeze!'}), // BANDED - ADDED
    
    // =========================================================================
    // ===== CALF PATTERN =====
    // =========================================================================
    'calf_raise': ExerciseConfig(patternType: PatternType.calf),
    'calf_raises': ExerciseConfig(patternType: PatternType.calf), // PLURAL - ADDED
    'standing_calf_raise': ExerciseConfig(patternType: PatternType.calf),
    'standing_calf_raises': ExerciseConfig(patternType: PatternType.calf), // PLURAL
    'seated_calf_raise': ExerciseConfig(patternType: PatternType.calf),
    'seated_calf_raises': ExerciseConfig(patternType: PatternType.calf), // PLURAL
    'single_leg_calf_raise': ExerciseConfig(patternType: PatternType.calf),
    'donkey_calf_raise': ExerciseConfig(patternType: PatternType.calf),
    'smith_machine_calf_raise': ExerciseConfig(patternType: PatternType.calf),
    
    // =========================================================================
    // ===== CORE EXERCISES (various patterns) =====
    // =========================================================================
    'situp': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.70, 'resetPercent': 0.90, 'cueGood': 'Crunch!', 'cueBad': 'Squeeze abs!'}),
    'situps': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.70, 'resetPercent': 0.90, 'cueGood': 'Crunch!', 'cueBad': 'Squeeze abs!'}), // PLURAL
    'sit_up': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.70, 'resetPercent': 0.90, 'cueGood': 'Crunch!', 'cueBad': 'Squeeze abs!'}),
    'sit_ups': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.70, 'resetPercent': 0.90, 'cueGood': 'Crunch!', 'cueBad': 'Squeeze abs!'}), // PLURAL
    'decline_situp': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.70, 'resetPercent': 0.90, 'cueGood': 'Crunch!', 'cueBad': 'Squeeze abs!'}), // ADDED
    'crunch': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.85, 'resetPercent': 0.92, 'cueGood': 'Squeeze!', 'cueBad': 'Crunch harder!'}),
    'crunches': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.85, 'resetPercent': 0.92, 'cueGood': 'Squeeze!', 'cueBad': 'Crunch harder!'}), // PLURAL
    'cable_crunch': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80, 'resetPercent': 0.92, 'cueGood': 'Squeeze!', 'cueBad': 'Crunch harder!'}), // ADDED
    'ab_wheel_rollout': ExerciseConfig(patternType: PatternType.push, params: {'cueGood': 'Extend!', 'cueBad': 'Control!'}), // ADDED - uses push pattern
    'ab_wheel': ExerciseConfig(patternType: PatternType.push, params: {'cueGood': 'Extend!', 'cueBad': 'Control!'}),
    
    // =========================================================================
    // ===== COMPOUND/CIRCUIT EXERCISES =====
    // =========================================================================
    'barbell_squat_press': ExerciseConfig(patternType: PatternType.squat, params: {'cueGood': 'Drive up!', 'cueBad': 'Full squat!'}), // ADDED
    'squat_press': ExerciseConfig(patternType: PatternType.squat, params: {'cueGood': 'Drive up!', 'cueBad': 'Full squat!'}),
    'bear_crawl': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.85, 'cueGood': 'Crawl!', 'cueBad': 'Stay low!'}),
    'bear_crawls': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.85, 'cueGood': 'Crawl!', 'cueBad': 'Stay low!'}), // PLURAL
    
    // =========================================================================
    // ===== EXERCISES THAT CAN'T BE TRACKED (default to manual) =====
    // =========================================================================
    // battle_ropes - can't track with pose detection
    // jump_rope - too fast for pose detection
    // These will fall through to default squat pattern
  };
}
