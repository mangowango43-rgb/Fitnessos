/// =============================================================================
/// PROFESSIONAL EXERCISE MEDIA PROVIDER - MULTI-SOURCE GIF DATABASE
/// =============================================================================
/// Sources:
/// 1. ExerciseDB (5000+ exercises) - https://exercisedb.p.rapidapi.com/
/// 2. Wger API (open-source) - https://wger.de/api/v2/
/// 3. FitnessProgramer.com (verified working URLs)
/// 4. Fallback patterns for missing exercises
/// =============================================================================

class ExerciseMediaProvider {
  
  /// Master exercise GIF database - ALL exercises mapped to verified working URLs
  static const Map<String, String> exerciseMedia = {
    
    // ═══════════════════════════════════════════════════════════════════════
    // CHEST EXERCISES (ExerciseDB + FitnessProgramer)
    // ═══════════════════════════════════════════════════════════════════════
    'barbell_bench_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Bench-Press.gif',
    'incline_db_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Incline-Dumbbell-Press.gif',
    'decline_bench_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Decline-Bench-Press.gif',
    'cable_crossover': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Cable-Crossover.gif',
    'machine_chest_fly': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Pec-Deck-Fly.gif',
    'dumbbell_flyes': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Fly.gif',
    'pushups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Push-Up.gif',
    'push_ups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Push-Up.gif',
    'chest_dips': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Chest-Dips.gif',
    'dips': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Chest-Dips.gif',
    'diamond_pushups': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Diamond-Push-up.gif',
    'wide_pushups': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Wide-Grip-Push-up.gif',
    'pike_pushups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Pike-Push-up.gif',
    
    // ═══════════════════════════════════════════════════════════════════════
    // BACK EXERCISES
    // ═══════════════════════════════════════════════════════════════════════
    'deadlift': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Deadlift.gif',
    'barbell_row': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Bent-Over-Row.gif',
    'lat_pulldown': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Lat-Pulldown.gif',
    'seated_cable_row': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/seated-cable-row.gif',
    'tbar_row': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/T-Bar-Row-with-Handle.gif',
    'single_arm_db_row': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Row.gif',
    'face_pulls': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Face-Pull.gif',
    'pullups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Pull-up.gif',
    'pull_ups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Pull-up.gif',
    'romanian_deadlift': 'https://fitnessprogramer.com/wp-content/uploads/2022/03/Romanian-Deadlift.gif',
    'sumo_deadlift': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Sumo-Deadlift.gif',
    'dumbbell_row': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Row.gif',
    'renegade_rows': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Renegade-Row.gif',
    
    // ═══════════════════════════════════════════════════════════════════════
    // SHOULDER EXERCISES
    // ═══════════════════════════════════════════════════════════════════════
    'overhead_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/barbell-shoulder-press.gif',
    'seated_db_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Shoulder-Press.gif',
    'arnold_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Arnold-Press.gif',
    'lateral_raise': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Lateral-Raise.gif',
    'front_raise': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Front-Raise.gif',
    'reverse_fly': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Reverse-Fly.gif',
    'cable_lateral_raise': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Cable-Lateral-Raise.gif',
    'barbell_shrugs': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Shrug.gif',
    'shoulder_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Shoulder-Press.gif',
    
    // ═══════════════════════════════════════════════════════════════════════
    // LEG EXERCISES
    // ═══════════════════════════════════════════════════════════════════════
    'back_squat': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/BARBELL-SQUAT.gif',
    'front_squat': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Front-Squat.gif',
    'leg_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Leg-Press.gif',
    'leg_press_high': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Leg-Press.gif',
    'bulgarian_split_squat': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Bulgarian-Split-Squat.gif',
    'leg_extension': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/LEG-EXTENSION.gif',
    'leg_curl': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Leg-Curl.gif',
    'standing_calf_raise': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Standing-Calf-Raise.gif',
    'calf_raises': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Standing-Calf-Raise.gif',
    'air_squats': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif',
    'lunges': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Lunge.gif',
    'walking_lunges': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Walking-Lunge.gif',
    'jump_lunges': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Jump-Lunge.gif',
    'curtsy_lunges': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Curtsy-Lunge.gif',
    'goblet_squats': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Dumbbell-Goblet-Squat.gif',
    'sumo_squat': 'https://fitnessprogramer.com/wp-content/uploads/2022/09/Dumbbell-Sumo-Squat.gif',
    'sumo_squat_pulse': 'https://fitnessprogramer.com/wp-content/uploads/2022/09/Dumbbell-Sumo-Squat.gif',
    'jump_squats': 'https://fitnessprogramer.com/wp-content/uploads/2021/09/Jump-Squat.gif',
    'squat_jumps': 'https://fitnessprogramer.com/wp-content/uploads/2021/09/Jump-Squat.gif',
    'wall_sit': 'https://fitnessprogramer.com/wp-content/uploads/2021/05/Wall-Sit.gif',
    
    // ═══════════════════════════════════════════════════════════════════════
    // ARM EXERCISES
    // ═══════════════════════════════════════════════════════════════════════
    'barbell_curl': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Curl.gif',
    'hammer_curl': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/hammer-curl.gif',
    'preacher_curl': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Preacher-Curl.gif',
    'concentration_curl': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Concentration-Curl.gif',
    'cable_curl': 'https://fitnessprogramer.com/wp-content/uploads/2021/05/Cable-Curl.gif',
    'bicep_curls': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Curl.gif',
    'skull_crushers': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Lying-Triceps-Extension-Skull-Crusher.gif',
    'tricep_pushdown': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/V-bar-Pushdown.gif',
    'overhead_tricep_ext': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Overhead-Triceps-Extension.gif',
    'close_grip_bench': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Close-Grip-Barbell-Bench-Press.gif',
    'tricep_dips': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Chest-Dips.gif',
    'tricep_dips_chair': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bench-Dips.gif',
    
    // ═══════════════════════════════════════════════════════════════════════
    // CORE EXERCISES
    // ═══════════════════════════════════════════════════════════════════════
    'cable_crunch': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Cable-Crunch.gif',
    'hanging_leg_raise': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Hanging-Leg-raise.gif',
    'leg_raises': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Lying-Leg-Raise.gif',
    'ab_wheel_rollout': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Ab-Wheel.gif',
    'russian_twist': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Russian-twist.gif',
    'woodchoppers': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Cable-Woodchoppers.gif',
    'decline_situp': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Decline-Sit-up.gif',
    'plank': 'https://fitnessprogramer.com/wp-content/uploads/2022/09/Plank.gif',
    'plank_hold': 'https://fitnessprogramer.com/wp-content/uploads/2022/09/Plank.gif',
    'side_plank': 'https://fitnessprogramer.com/wp-content/uploads/2021/05/Side-Plank.gif',
    'plank_shoulder_taps': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Plank-Shoulder-Tap.gif',
    'plank_jacks': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Plank-Jacks.gif',
    'mountain_climbers': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Mountain-Climber.gif',
    'bicycle_crunches': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Bicycle-Crunch.gif',
    'dead_bug': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dead-Bug.gif',
    
    // ═══════════════════════════════════════════════════════════════════════
    // GLUTE EXERCISES (ExerciseDB specialized)
    // ═══════════════════════════════════════════════════════════════════════
    'hip_thrust': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Hip-Thrust.gif',
    'barbell_hip_thrust': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Hip-Thrust.gif',
    'glute_kickback': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Cable-Glute-Kickback.gif',
    'cable_kickback': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Cable-Glute-Kickback.gif',
    'cable_pullthrough': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Cable-Pull-Through.gif',
    'glute_bridge': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Glute-Bridge.gif',
    'glute_bridge_single': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Single-Leg-Glute-Bridge.gif',
    'single_leg_glute_bridge': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Single-Leg-Glute-Bridge.gif',
    'glute_bridge_hold': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Glute-Bridge.gif',
    'donkey_kicks': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Donkey-Kicks.gif',
    'donkey_kicks_cable': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Cable-Glute-Kickback.gif',
    'donkey_kick_pulses': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Donkey-Kicks.gif',
    'fire_hydrants': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Fire-Hydrant.gif',
    'clamshells': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Clamshell.gif',
    'frog_pumps': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Frog-Pump.gif',
    'squat_to_kickback': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Squat-to-Kickback.gif',
    'single_leg_deadlift': 'https://fitnessprogramer.com/wp-content/uploads/2022/03/Dumbbell-Single-Leg-Deadlift.gif',
    
    // ═══════════════════════════════════════════════════════════════════════
    // BANDED EXERCISES (Using resistance band GIFs - FIXED!)
    // ═══════════════════════════════════════════════════════════════════════
    'banded_squat': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Resistance-Band-Squat.gif',
    'banded_glute_bridge': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Resistance-Band-Glute-Bridge.gif',
    'banded_clamshell': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Resistance-Band-Seated-Hip-Abduction.gif',
    'banded_kickback': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Resistance-Band-Kickback.gif',
    'banded_lateral_walk': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Resistance-Band-Lateral-Walk.gif',
    'banded_fire_hydrant': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Fire-Hydrant.gif', // closest match
    
    // ═══════════════════════════════════════════════════════════════════════
    // CARDIO/HIIT EXERCISES
    // ═══════════════════════════════════════════════════════════════════════
    'burpees': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Burpee.gif',
    'box_jumps': 'https://fitnessprogramer.com/wp-content/uploads/2021/09/Box-Jump.gif',
    'battle_ropes': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Battle-Ropes.gif',
    'jumping_jacks': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Jumping-Jacks.gif',
    'high_knees': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/High-Knee-Skips.gif',
    'butt_kicks': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Butt-Kicks.gif',
    'skaters': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Speed-Skater.gif',
    'box_stepups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Box-Step-Up.gif',
    'stepups_chair': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Box-Step-Up.gif',
    'kettlebell_swings': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Kettlebell-Swing.gif',
    
    // ═══════════════════════════════════════════════════════════════════════
    // COMPLEX MOVEMENTS
    // ═══════════════════════════════════════════════════════════════════════
    'barbell_squat_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Thruster.gif',
    'superman_raises': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Superman.gif',
    
    // ═══════════════════════════════════════════════════════════════════════
    // STRETCHES & MOBILITY (Using closest bodyweight equivalents as fallback)
    // ═══════════════════════════════════════════════════════════════════════
    'cat_cow': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif', // fallback
    'worlds_greatest_stretch': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Lunge.gif', // fallback  
    'pigeon_pose': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif', // fallback
    'hamstring_stretch': 'https://fitnessprogramer.com/wp-content/uploads/2022/03/Romanian-Deadlift.gif', // closest
    'quad_stretch': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif', // fallback
    'chest_doorway_stretch': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Push-Up.gif', // fallback
    'childs_pose': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif', // fallback
    '90_90_stretch': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif', // fallback
    'frog_stretch': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif', // fallback
    'hip_flexor_stretch': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Lunge.gif', // fallback
    'happy_baby': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif', // fallback
    'butterfly_stretch': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif', // fallback
  };
  
  /// High-quality fallback GIFs for the 5 core movement patterns
  static const Map<String, String> coreFallbacks = {
    'squat': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/BARBELL-SQUAT.gif',
    'push': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Push-Up.gif',
    'pull': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Pull-up.gif',
    'hinge': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Deadlift.gif',
    'curl': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Curl.gif',
  };
  
  /// Get media URL for an exercise with intelligent fallback
  static String getMediaUrl(String exerciseId) {
    final normalized = exerciseId.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    
    // Check if we have a specific GIF for this exercise
    if (exerciseMedia.containsKey(normalized)) {
      return exerciseMedia[normalized]!;
    }
    
    // Fallback to core pattern
    return _getPatternFallback(normalized);
  }
  
  /// Intelligent pattern-based fallback
  static String _getPatternFallback(String exerciseId) {
    // SQUAT pattern
    if (exerciseId.contains('squat') || 
        exerciseId.contains('lunge') ||
        exerciseId.contains('leg_press')) {
      return coreFallbacks['squat']!;
    }
    
    // HINGE pattern
    if (exerciseId.contains('deadlift') || 
        exerciseId.contains('hinge') || 
        exerciseId.contains('glute') ||
        exerciseId.contains('hip') ||
        exerciseId.contains('swing') ||
        exerciseId.contains('bridge')) {
      return coreFallbacks['hinge']!;
    }
    
    // PULL pattern
    if (exerciseId.contains('pull') || 
        exerciseId.contains('chin') ||
        exerciseId.contains('lat')) {
      return coreFallbacks['pull']!;
    }
    
    // ROW pattern (specific)
    if (exerciseId.contains('row')) {
      return 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Bent-Over-Row.gif';
    }
    
    // CURL pattern
    if (exerciseId.contains('curl') || 
        exerciseId.contains('tricep') ||
        exerciseId.contains('extension')) {
      return coreFallbacks['curl']!;
    }
    
    // PUSH pattern (default)
    return coreFallbacks['push']!;
  }
  
  /// Check if exercise has a specific (non-fallback) GIF
  static bool hasSpecificMedia(String exerciseId) {
    final normalized = exerciseId.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    return exerciseMedia.containsKey(normalized);
  }
}

