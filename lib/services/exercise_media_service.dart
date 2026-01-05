import 'package:flutter/foundation.dart';
import 'exercise_animation_database.dart';

/// =============================================================================
/// EXERCISE MEDIA SERVICE - SIMPLIFIED & WORKING
/// =============================================================================
/// Directly uses ExerciseDB v2 image URLs
/// NO API KEY NEEDED - These URLs are public!
/// =============================================================================

class ExerciseMediaService {
  static final ExerciseMediaService _instance = ExerciseMediaService._internal();
  factory ExerciseMediaService() => _instance;
  ExerciseMediaService._internal();

  /// Get animation URL for an exercise
  /// Returns working GIF URL from ExerciseDB v2
  String getAnimationUrl(String exerciseId) {
    final url = ExerciseAnimationDatabase.getAnimationUrl(exerciseId);
    
    if (kDebugMode) {
      print('🎬 Animation URL for "$exerciseId": $url');
    }
    
    return url;
  }
  
  /// Check if we have an animation for this exercise
  bool hasAnimation(String exerciseId) {
    return ExerciseAnimationDatabase.hasAnimation(exerciseId);
  }
  
  /// Initialize service (kept for compatibility, but not needed)
  Future<void> initialize() async {
    if (kDebugMode) {
      print('✅ ExerciseMediaService initialized (direct URL mode)');
    }
  }
  
  /// Preload exercises (kept for compatibility, but not needed with direct URLs)
  Future<void> preloadExercises(List<String> exerciseIds) async {
    if (kDebugMode) {
      print('📦 Preload requested for ${exerciseIds.length} exercises');
      print('ℹ️  Using direct ExerciseDB URLs - no preloading needed');
    }
  }
  
  /// Clear cache (kept for compatibility)
  Future<void> clearCache() async {
    if (kDebugMode) {
      print('🗑️  Cache clear requested (using direct URLs, nothing to clear)');
    }
  }
}
