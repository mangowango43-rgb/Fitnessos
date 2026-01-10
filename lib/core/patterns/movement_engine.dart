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
/// Maps 150+ exercises to their pattern type.
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
  
  /// Capture baseline position
  void captureBaseline(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    _activePattern?.captureBaseline(landmarks);
  }
  
  /// Process a frame - returns true if rep was counted
  bool processFrame(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    return _activePattern?.processFrame(landmarks) ?? false;
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
  /// EXERCISE DATABASE - 150+ exercises mapped to patterns
  /// ==========================================================================
  static const Map<String, ExerciseConfig> exercises = {
    // ===== SQUAT PATTERN =====
    'squat': ExerciseConfig(patternType: PatternType.squat),
    'air_squat': ExerciseConfig(patternType: PatternType.squat),
    'bodyweight_squat': ExerciseConfig(patternType: PatternType.squat),
    'goblet_squat': ExerciseConfig(patternType: PatternType.squat),
    'barbell_squat': ExerciseConfig(patternType: PatternType.squat),
    'back_squat': ExerciseConfig(patternType: PatternType.squat),
    'front_squat': ExerciseConfig(patternType: PatternType.squat),
    'sumo_squat': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'split_squat': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'bulgarian_split_squat': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}),
    'walking_lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}),
    'reverse_lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}),
    'lateral_lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'curtsy_lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'jump_squat': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80}),
    'jump_lunge': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'box_jump': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80}),
    'step_up': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80}),
    'box_step_up': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.80}),
    'pistol_squat': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.70}),
    'sissy_squat': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'hack_squat': ExerciseConfig(patternType: PatternType.squat),
    'leg_press': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'sit_up': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.85, 'resetPercent': 0.95}),
    'crunch': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.90, 'resetPercent': 0.97}),
    'v_up': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.70}),
    'leg_raise': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75}),
    'burpee': ExerciseConfig(patternType: PatternType.squat, params: {'triggerPercent': 0.75, 'resetPercent': 0.90}),
    'thruster': ExerciseConfig(patternType: PatternType.squat),
    'wall_ball': ExerciseConfig(patternType: PatternType.squat),
    
    // ===== PUSH PATTERN =====
    'pushup': ExerciseConfig(patternType: PatternType.push),
    'push_up': ExerciseConfig(patternType: PatternType.push),
    'wide_pushup': ExerciseConfig(patternType: PatternType.push),
    'diamond_pushup': ExerciseConfig(patternType: PatternType.push),
    'close_grip_pushup': ExerciseConfig(patternType: PatternType.push),
    'decline_pushup': ExerciseConfig(patternType: PatternType.push),
    'incline_pushup': ExerciseConfig(patternType: PatternType.push),
    'pike_pushup': ExerciseConfig(patternType: PatternType.push),
    'archer_pushup': ExerciseConfig(patternType: PatternType.push),
    'clap_pushup': ExerciseConfig(patternType: PatternType.push),
    'bench_press': ExerciseConfig(patternType: PatternType.push),
    'barbell_bench_press': ExerciseConfig(patternType: PatternType.push),
    'dumbbell_bench_press': ExerciseConfig(patternType: PatternType.push),
    'incline_bench_press': ExerciseConfig(patternType: PatternType.push),
    'incline_press': ExerciseConfig(patternType: PatternType.push),
    'decline_bench_press': ExerciseConfig(patternType: PatternType.push),
    'decline_press': ExerciseConfig(patternType: PatternType.push),
    'dumbbell_press': ExerciseConfig(patternType: PatternType.push),
    'overhead_press': ExerciseConfig(patternType: PatternType.push),
    'shoulder_press': ExerciseConfig(patternType: PatternType.push),
    'military_press': ExerciseConfig(patternType: PatternType.push),
    'arnold_press': ExerciseConfig(patternType: PatternType.push),
    'push_press': ExerciseConfig(patternType: PatternType.push),
    'dips': ExerciseConfig(patternType: PatternType.push),
    'tricep_dips': ExerciseConfig(patternType: PatternType.push),
    'bench_dips': ExerciseConfig(patternType: PatternType.push),
    'ring_dips': ExerciseConfig(patternType: PatternType.push),
    'chest_fly': ExerciseConfig(patternType: PatternType.push),
    'dumbbell_fly': ExerciseConfig(patternType: PatternType.push),
    'cable_fly': ExerciseConfig(patternType: PatternType.push),
    'cable_crossover': ExerciseConfig(patternType: PatternType.push),
    'machine_chest_press': ExerciseConfig(patternType: PatternType.push),
    'landmine_press': ExerciseConfig(patternType: PatternType.push),
    
    // ===== PULL PATTERN =====
    'pullup': ExerciseConfig(patternType: PatternType.pull),
    'pull_up': ExerciseConfig(patternType: PatternType.pull),
    'chinup': ExerciseConfig(patternType: PatternType.pull),
    'chin_up': ExerciseConfig(patternType: PatternType.pull),
    'wide_grip_pullup': ExerciseConfig(patternType: PatternType.pull),
    'close_grip_pullup': ExerciseConfig(patternType: PatternType.pull),
    'neutral_grip_pullup': ExerciseConfig(patternType: PatternType.pull),
    'muscle_up': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 60}),
    'lat_pulldown': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 80, 'resetAngle': 160}),
    'cable_pulldown': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 80, 'resetAngle': 160}),
    'bent_over_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'barbell_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'dumbbell_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'single_arm_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'cable_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 75, 'resetAngle': 155}),
    'seated_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 75, 'resetAngle': 155}),
    'face_pull': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 80, 'resetAngle': 150}),
    'reverse_fly': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 90, 'resetAngle': 160}),
    't_bar_row': ExerciseConfig(patternType: PatternType.pull, params: {'triggerAngle': 70, 'resetAngle': 150}),
    'inverted_row': ExerciseConfig(patternType: PatternType.pull),
    
    // ===== HINGE PATTERN =====
    'deadlift': ExerciseConfig(patternType: PatternType.hinge),
    'barbell_deadlift': ExerciseConfig(patternType: PatternType.hinge),
    'sumo_deadlift': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100}),
    'romanian_deadlift': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 95}),
    'rdl': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 95}),
    'stiff_leg_deadlift': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 90}),
    'single_leg_deadlift': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100}),
    'trap_bar_deadlift': ExerciseConfig(patternType: PatternType.hinge),
    'good_morning': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100}),
    'kettlebell_swing': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100, 'resetAngle': 170}),
    'hip_thrust': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 165, 'resetAngle': 110}),
    'glute_bridge': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 165, 'resetAngle': 110}),
    'single_leg_glute_bridge': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 165, 'resetAngle': 110}),
    'barbell_hip_thrust': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 165, 'resetAngle': 110}),
    'cable_pull_through': ExerciseConfig(patternType: PatternType.hinge),
    'back_extension': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100, 'resetAngle': 170}),
    'hyperextension': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 100, 'resetAngle': 170}),
    'superman': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 160, 'resetAngle': 130}),
    'superman_raise': ExerciseConfig(patternType: PatternType.hinge, params: {'triggerAngle': 160, 'resetAngle': 130}),
    
    // ===== CURL PATTERN =====
    'bicep_curl': ExerciseConfig(patternType: PatternType.curl),
    'barbell_curl': ExerciseConfig(patternType: PatternType.curl),
    'dumbbell_curl': ExerciseConfig(patternType: PatternType.curl),
    'hammer_curl': ExerciseConfig(patternType: PatternType.curl),
    'preacher_curl': ExerciseConfig(patternType: PatternType.curl),
    'concentration_curl': ExerciseConfig(patternType: PatternType.curl),
    'cable_curl': ExerciseConfig(patternType: PatternType.curl),
    'incline_curl': ExerciseConfig(patternType: PatternType.curl),
    'spider_curl': ExerciseConfig(patternType: PatternType.curl),
    'ez_bar_curl': ExerciseConfig(patternType: PatternType.curl),
    'reverse_curl': ExerciseConfig(patternType: PatternType.curl),
    'zottman_curl': ExerciseConfig(patternType: PatternType.curl),
    'tricep_extension': ExerciseConfig(patternType: PatternType.curl),
    'overhead_tricep_extension': ExerciseConfig(patternType: PatternType.curl),
    'tricep_pushdown': ExerciseConfig(patternType: PatternType.curl),
    'rope_pushdown': ExerciseConfig(patternType: PatternType.curl),
    'skull_crusher': ExerciseConfig(patternType: PatternType.curl),
    'close_grip_bench': ExerciseConfig(patternType: PatternType.curl),
    'tricep_kickback': ExerciseConfig(patternType: PatternType.curl),
    'lateral_raise': ExerciseConfig(patternType: PatternType.curl),
    'front_raise': ExerciseConfig(patternType: PatternType.curl),
    'rear_delt_fly': ExerciseConfig(patternType: PatternType.curl),
    'upright_row': ExerciseConfig(patternType: PatternType.curl),
    'shrug': ExerciseConfig(patternType: PatternType.curl),
    'barbell_shrug': ExerciseConfig(patternType: PatternType.curl),
    'dumbbell_shrug': ExerciseConfig(patternType: PatternType.curl),
    'wrist_curl': ExerciseConfig(patternType: PatternType.curl),
    'reverse_wrist_curl': ExerciseConfig(patternType: PatternType.curl),
    
    // ===== KNEE DRIVE PATTERN =====
    'mountain_climber': ExerciseConfig(patternType: PatternType.kneeDrive),
    'mountain_climbers': ExerciseConfig(patternType: PatternType.kneeDrive),
    'high_knees': ExerciseConfig(patternType: PatternType.kneeDrive),
    'high_knee': ExerciseConfig(patternType: PatternType.kneeDrive),
    'running_in_place': ExerciseConfig(patternType: PatternType.kneeDrive),
    'bicycle_crunch': ExerciseConfig(patternType: PatternType.kneeDrive),
    'bicycle_crunches': ExerciseConfig(patternType: PatternType.kneeDrive),
    'flutter_kick': ExerciseConfig(patternType: PatternType.kneeDrive),
    'flutter_kicks': ExerciseConfig(patternType: PatternType.kneeDrive),
    'scissor_kick': ExerciseConfig(patternType: PatternType.kneeDrive),
    'scissor_kicks': ExerciseConfig(patternType: PatternType.kneeDrive),
    'butt_kicks': ExerciseConfig(patternType: PatternType.kneeDrive),
    'butt_kick': ExerciseConfig(patternType: PatternType.kneeDrive),
    'a_skip': ExerciseConfig(patternType: PatternType.kneeDrive),
    'b_skip': ExerciseConfig(patternType: PatternType.kneeDrive),
    'skater': ExerciseConfig(patternType: PatternType.kneeDrive),
    'skaters': ExerciseConfig(patternType: PatternType.kneeDrive),
    
    // ===== HOLD PATTERN =====
    'plank': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'forearm_plank': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'high_plank': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'side_plank': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'side_plank_left': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'side_plank_right': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'wall_sit': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.wallSit}),
    'wall_squat': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.wallSit}),
    'dead_hang': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.hang}),
    'active_hang': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.hang}),
    'l_sit': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'hollow_hold': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'hollow_body_hold': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'superman_hold': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'arch_hold': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
    'boat_pose': ExerciseConfig(patternType: PatternType.hold, params: {'holdType': HoldType.plank}),
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
    
    // ===== ROTATION PATTERN =====
    'russian_twist': ExerciseConfig(patternType: PatternType.rotation),
    'russian_twists': ExerciseConfig(patternType: PatternType.rotation),
    'woodchopper': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 60}),
    'wood_chopper': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 60}),
    'cable_woodchop': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 60}),
    'cable_rotation': ExerciseConfig(patternType: PatternType.rotation),
    'oblique_twist': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 40}),
    'standing_rotation': ExerciseConfig(patternType: PatternType.rotation),
    'seated_rotation': ExerciseConfig(patternType: PatternType.rotation),
    'medicine_ball_twist': ExerciseConfig(patternType: PatternType.rotation),
    'landmine_rotation': ExerciseConfig(patternType: PatternType.rotation, params: {'triggerAngle': 50}),
    
    // ===== CALF PATTERN =====
    'calf_raise': ExerciseConfig(patternType: PatternType.calf),
    'calf_raises': ExerciseConfig(patternType: PatternType.calf),
    'standing_calf_raise': ExerciseConfig(patternType: PatternType.calf),
    'seated_calf_raise': ExerciseConfig(patternType: PatternType.calf),
    'single_leg_calf_raise': ExerciseConfig(patternType: PatternType.calf),
    'donkey_calf_raise': ExerciseConfig(patternType: PatternType.calf),
    'smith_machine_calf_raise': ExerciseConfig(patternType: PatternType.calf),
  };
}
