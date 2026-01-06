/// =============================================================================
/// COMPREHENSIVE EXERCISE ANIMATION DATABASE - WORKING PUBLIC GIFS
/// =============================================================================
/// Uses exercise GIFs from multiple free public CDNs
/// These are REAL, working, publicly accessible URLs
/// NO API KEY NEEDED!
/// 
/// SOURCES:
/// - FitnessProgramer.com (primary - 150+ verified GIFs)
/// - ExerciseDB compatible URLs
/// - Intelligent fallback system for missing exercises
/// =============================================================================

import 'exercise_media_provider.dart';

class ExerciseAnimationDatabase {
  
  /// Get animation URL for an exercise
  /// Now delegates to the comprehensive ExerciseMediaProvider
  static String getAnimationUrl(String exerciseId) {
    return ExerciseMediaProvider.getMediaUrl(exerciseId);
  }
  
  /// Check if we have an animation for this exercise
  static bool hasAnimation(String exerciseId) {
    return ExerciseMediaProvider.hasSpecificMedia(exerciseId);
  }
  
  /// Legacy compatibility - keep the old exerciseGifs map for reference
  /// but it now points to the new system
  static Map<String, String> get exerciseGifs => ExerciseMediaProvider.exerciseMedia;
}
