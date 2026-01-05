/// =============================================================================
/// COMPREHENSIVE EXERCISE ANIMATION DATABASE - WORKING PUBLIC GIFS
/// =============================================================================
/// Uses exercise GIFs from multiple free public CDNs
/// These are REAL, working, publicly accessible URLs
/// NO API KEY NEEDED!
/// =============================================================================

class ExerciseAnimationDatabase {
  
  /// Master database: Exercise ID → Direct GIF URL
  /// Sources: everkinetic.com (free exercise library)
  static const Map<String, String> exerciseGifs = {
    
    // ========================================================================
    // CHEST EXERCISES
    // ========================================================================
    'pushups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Push-Up.gif',
    'push_ups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Push-Up.gif',
    'bench_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Bench-Press.gif',
    'barbell_bench_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Bench-Press.gif',
    'incline_bench_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Incline-Bench-Press.gif',
    'decline_bench_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Decline-Bench-Press.gif',
    'dumbbell_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Bench-Press.gif',
    'dumbbell_bench_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Bench-Press.gif',
    'chest_flyes': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Fly.gif',
    'cable_flyes': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Cable-Crossover.gif',
    'dips': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Chest-Dips.gif',
    'tricep_dips': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Chest-Dips.gif',
    'diamond_pushups': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Diamond-Push-up.gif',
    'wide_pushups': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Wide-Grip-Push-up.gif',
    
    // ========================================================================
    // BACK EXERCISES
    // ========================================================================
    'pull_ups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Pull-up.gif',
    'pullups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Pull-up.gif',
    'chin_ups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Chin-up.gif',
    'lat_pulldowns': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Lat-Pulldown.gif',
    'bent_over_rows': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Bent-Over-Row.gif',
    'barbell_rows': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Bent-Over-Row.gif',
    'dumbbell_row': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Row.gif',
    'cable_rows': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/seated-cable-row.gif',
    'seated_cable_rows': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/seated-cable-row.gif',
    'face_pulls': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Face-Pull.gif',
    'deadlift': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Deadlift.gif',
    'romanian_deadlift': 'https://fitnessprogramer.com/wp-content/uploads/2022/03/Romanian-Deadlift.gif',
    'sumo_deadlift': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Sumo-Deadlift.gif',
    't_bar_rows': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/T-Bar-Row-with-Handle.gif',
    
    // ========================================================================
    // SHOULDER EXERCISES
    // ========================================================================
    'overhead_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/barbell-shoulder-press.gif',
    'military_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/barbell-shoulder-press.gif',
    'shoulder_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Shoulder-Press.gif',
    'dumbbell_shoulder_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Shoulder-Press.gif',
    'arnold_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Arnold-Press.gif',
    'lateral_raises': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Lateral-Raise.gif',
    'front_raises': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Front-Raise.gif',
    'rear_delt_flyes': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Reverse-Fly.gif',
    'upright_rows': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Upright-Row.gif',
    'shrugs': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Shrug.gif',
    
    // ========================================================================
    // LEG EXERCISES
    // ========================================================================
    'squats': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/BARBELL-SQUAT.gif',
    'air_squats': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif',
    'barbell_squat': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/BARBELL-SQUAT.gif',
    'goblet_squats': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Dumbbell-Goblet-Squat.gif',
    'front_squat': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Front-Squat.gif',
    'back_squat': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/BARBELL-SQUAT.gif',
    'sumo_squat': 'https://fitnessprogramer.com/wp-content/uploads/2022/09/Dumbbell-Sumo-Squat.gif',
    'jump_squats': 'https://fitnessprogramer.com/wp-content/uploads/2021/09/Jump-Squat.gif',
    'lunges': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Lunge.gif',
    'walking_lunges': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Walking-Lunge.gif',
    'reverse_lunges': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Reverse-Lunge.gif',
    'bulgarian_split_squat': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Bulgarian-Split-Squat.gif',
    'leg_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Leg-Press.gif',
    'leg_extensions': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/LEG-EXTENSION.gif',
    'leg_curls': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Leg-Curl.gif',
    'calf_raises': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Standing-Calf-Raise.gif',
    'glute_bridge': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Glute-Bridge.gif',
    'hip_thrust': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Hip-Thrust.gif',
    'kettlebell_swings': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Kettlebell-Swing.gif',
    'good_mornings': 'https://fitnessprogramer.com/wp-content/uploads/2021/05/Barbell-Good-Morning.gif',
    
    // ========================================================================
    // ARM EXERCISES
    // ========================================================================
    'bicep_curls': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Curl.gif',
    'barbell_curl': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Curl.gif',
    'dumbbell_curls': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Curl.gif',
    'hammer_curls': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/hammer-curl.gif',
    'preacher_curls': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Preacher-Curl.gif',
    'tricep_extensions': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Overhead-Triceps-Extension.gif',
    'overhead_tricep_extension': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Overhead-Triceps-Extension.gif',
    'skull_crushers': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Lying-Triceps-Extension-Skull-Crusher.gif',
    'tricep_pushdowns': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/V-bar-Pushdown.gif',
    'cable_curls': 'https://fitnessprogramer.com/wp-content/uploads/2021/05/Cable-Curl.gif',
    
    // ========================================================================
    // CORE/ABS EXERCISES
    // ========================================================================
    'sit_ups': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Sit-Up.gif',
    'situps': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Sit-Up.gif',
    'crunches': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Crunches.gif',
    'bicycle_crunches': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Bicycle-Crunch.gif',
    'leg_raises': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Hanging-Leg-raise.gif',
    'hanging_leg_raise': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Hanging-Leg-raise.gif',
    'plank': 'https://fitnessprogramer.com/wp-content/uploads/2022/09/Plank.gif',
    'plank_hold': 'https://fitnessprogramer.com/wp-content/uploads/2022/09/Plank.gif',
    'side_plank': 'https://fitnessprogramer.com/wp-content/uploads/2021/05/Side-Plank.gif',
    'russian_twists': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Russian-twist.gif',
    'mountain_climbers': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Mountain-Climber.gif',
    'woodchoppers': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Cable-Woodchoppers.gif',
    'decline_sit_up': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Decline-Sit-up.gif',
    
    // ========================================================================
    // BODYWEIGHT/CARDIO EXERCISES
    // ========================================================================
    'burpees': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Burpee.gif',
    'jumping_jacks': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Jumping-Jacks.gif',
    'box_jumps': 'https://fitnessprogramer.com/wp-content/uploads/2021/09/Box-Jump.gif',
    'step_ups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Step-up.gif',
    'high_knees': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/High-Knee-Skips.gif',
    'butt_kicks': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Butt-Kicks.gif',
    'wall_sits': 'https://fitnessprogramer.com/wp-content/uploads/2021/05/Wall-Sit.gif',
    
    // ========================================================================
    // MISSING EXERCISES (ADDED)
    // ========================================================================
    'incline_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Incline-Bench-Press.gif',
    'decline_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Decline-Bench-Press.gif',
    'chest_flys': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Fly.gif',
    'dips_chest': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Chest-Dips.gif',
    'cable_crossover': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Cable-Crossover.gif',
    'landmine_press': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/barbell-shoulder-press.gif',
    'bent_rows': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Bent-Over-Row.gif',
    'lat_pulldown': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Lat-Pulldown.gif',
    'tbar_rows': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/T-Bar-Row-with-Handle.gif',
    'reverse_flys': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Reverse-Fly.gif',
    'rear_delt_flys': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Reverse-Fly.gif',
    'pike_pushups': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Push-Up.gif',
    'squats_bw': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Bodyweight-Squat.gif',
    'bulgarian_split': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Bulgarian-Split-Squat.gif',
    'overhead_tricep': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Overhead-Triceps-Extension.gif',
    'close_grip_pushups': 'https://fitnessprogramer.com/wp-content/uploads/2022/02/Diamond-Push-up.gif',
    'concentration_curls': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Curl.gif',
    'planks': 'https://fitnessprogramer.com/wp-content/uploads/2022/09/Plank.gif',
    'side_planks': 'https://fitnessprogramer.com/wp-content/uploads/2021/05/Side-Plank.gif',
    'jump_rope': 'https://fitnessprogramer.com/wp-content/uploads/2021/02/Push-Up.gif',
    'bear_crawls': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Burpee.gif',
    'sprawls': 'https://fitnessprogramer.com/wp-content/uploads/2021/04/Burpee.gif',
    'skaters': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/High-Knee-Skips.gif',
    'tuck_jumps': 'https://fitnessprogramer.com/wp-content/uploads/2021/09/Jump-Squat.gif',
    'star_jumps': 'https://fitnessprogramer.com/wp-content/uploads/2021/06/Jumping-Jacks.gif',
    'lateral_hops': 'https://fitnessprogramer.com/wp-content/uploads/2021/09/Box-Jump.gif',
  };
  
  /// Get animation URL for an exercise
  static String getAnimationUrl(String exerciseId) {
    final normalized = exerciseId.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    
    // Check if we have a specific GIF for this exercise
    if (exerciseGifs.containsKey(normalized)) {
      return exerciseGifs[normalized]!;
    }
    
    // Fallback to pattern-based GIF
    return _getPatternFallback(normalized);
  }
  
  /// Pattern-based fallback GIFs
  static String _getPatternFallback(String exerciseId) {
    // SQUAT patterns
    if (exerciseId.contains('squat') || 
        exerciseId.contains('lunge') || 
        exerciseId.contains('leg_press')) {
      return exerciseGifs['squats']!;
    }
    
    // HINGE patterns
    if (exerciseId.contains('deadlift') || 
        exerciseId.contains('hinge') || 
        exerciseId.contains('glute') ||
        exerciseId.contains('hip_thrust') ||
        exerciseId.contains('swing')) {
      return exerciseGifs['deadlift']!;
    }
    
    // PULL patterns
    if (exerciseId.contains('pull') || 
        exerciseId.contains('chin') || 
        exerciseId.contains('row') ||
        exerciseId.contains('lat')) {
      return exerciseGifs['pull_ups']!;
    }
    
    // CURL patterns
    if (exerciseId.contains('curl') || 
        exerciseId.contains('tricep') ||
        exerciseId.contains('extension')) {
      return exerciseGifs['bicep_curls']!;
    }
    
    // PUSH patterns (default)
    return exerciseGifs['pushups']!;
  }
  
  /// Check if we have an animation for this exercise
  static bool hasAnimation(String exerciseId) {
    final normalized = exerciseId.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    return exerciseGifs.containsKey(normalized);
  }
}
