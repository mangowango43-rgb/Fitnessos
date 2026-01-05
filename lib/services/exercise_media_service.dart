import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_media.dart';
import '../core/patterns/movement_engine.dart';

/// =============================================================================
/// EXERCISE MEDIA SERVICE
/// =============================================================================
/// Fetches, caches, and manages exercise animations from ExerciseDB API
/// 
/// Features:
/// - Free ExerciseDB API integration
/// - Local caching (no repeated API calls)
/// - Smart pattern-based fallbacks
/// - Optimized for battery (lazy loading)
/// =============================================================================

class ExerciseMediaService {
  static final ExerciseMediaService _instance = ExerciseMediaService._internal();
  factory ExerciseMediaService() => _instance;
  ExerciseMediaService._internal();

  // ExerciseDB API (Free tier - no key needed for basic access)
  static const String _baseUrl = 'https://exercisedb.p.rapidapi.com';
  static const String _rapidApiKey = 'DEMO'; // TODO: Get free key from RapidAPI
  
  // Cache
  final Map<String, ExerciseMedia> _cache = {};
  bool _isInitialized = false;
  
  /// Initialize service and load cache
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('exercise_media_cache');
      
      if (cachedJson != null) {
        final Map<String, dynamic> cacheData = json.decode(cachedJson);
        _cache.clear();
        cacheData.forEach((key, value) {
          _cache[key] = ExerciseMedia.fromJson(value);
        });
        print('✅ Loaded ${_cache.length} cached exercise animations');
      }
      
      _isInitialized = true;
    } catch (e) {
      print('⚠️ Error loading exercise media cache: $e');
      _isInitialized = true;
    }
  }
  
  /// Get animation URL for an exercise
  /// Returns cached URL or fetches from API
  Future<String> getAnimationUrl(String exerciseId) async {
    await initialize();
    
    // Check cache first
    if (_cache.containsKey(exerciseId)) {
      return _cache[exerciseId]!.gifUrl;
    }
    
    // Try to fetch from API
    try {
      final media = await _fetchFromApi(exerciseId);
      if (media != null) {
        _cache[exerciseId] = media;
        await _saveCache();
        return media.gifUrl;
      }
    } catch (e) {
      print('⚠️ API fetch failed for $exerciseId: $e');
    }
    
    // Fallback to pattern-based animation
    return _getPatternFallback(exerciseId);
  }
  
  /// Get ExerciseMedia object (full metadata)
  Future<ExerciseMedia?> getExerciseMedia(String exerciseId) async {
    await initialize();
    
    if (_cache.containsKey(exerciseId)) {
      return _cache[exerciseId];
    }
    
    try {
      final media = await _fetchFromApi(exerciseId);
      if (media != null) {
        _cache[exerciseId] = media;
        await _saveCache();
        return media;
      }
    } catch (e) {
      print('⚠️ API fetch failed for $exerciseId: $e');
    }
    
    return null;
  }
  
  /// Fetch from ExerciseDB API
  Future<ExerciseMedia?> _fetchFromApi(String exerciseId) async {
    // For now, return null to use fallbacks
    // TODO: Implement actual API calls when user adds RapidAPI key
    
    // Example API call (commented out):
    /*
    final url = Uri.parse('$_baseUrl/exercises/name/${exerciseId.replaceAll('_', '%20')}');
    final response = await http.get(
      url,
      headers: {
        'X-RapidAPI-Key': _rapidApiKey,
        'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return ExerciseMedia.fromJson(data[0]);
      }
    }
    */
    
    return null;
  }
  
  /// Get pattern-based fallback animation
  String _getPatternFallback(String exerciseId) {
    // Determine pattern from exercise name keywords
    final normalizedId = exerciseId.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    
    // SQUAT patterns
    if (normalizedId.contains('squat') || 
        normalizedId.contains('lunge') || 
        normalizedId.contains('leg_press') ||
        normalizedId.contains('sit_up') ||
        normalizedId.contains('crunch') ||
        normalizedId.contains('plank') ||
        normalizedId.contains('burpee')) {
      return PatternFallbacks.getFallback('squat');
    }
    
    // HINGE patterns
    if (normalizedId.contains('deadlift') || 
        normalizedId.contains('hinge') || 
        normalizedId.contains('glute') ||
        normalizedId.contains('swing') ||
        normalizedId.contains('good_morning')) {
      return PatternFallbacks.getFallback('hinge');
    }
    
    // PULL patterns
    if (normalizedId.contains('pull') || 
        normalizedId.contains('chin') || 
        normalizedId.contains('row') ||
        normalizedId.contains('lat')) {
      return PatternFallbacks.getFallback('pull');
    }
    
    // CURL patterns
    if (normalizedId.contains('curl') || 
        normalizedId.contains('extension') || 
        normalizedId.contains('tricep')) {
      return PatternFallbacks.getFallback('curl');
    }
    
    // PUSH patterns (default)
    return PatternFallbacks.getFallback('push');
  }
  
  /// Save cache to local storage
  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = json.encode(
        _cache.map((key, value) => MapEntry(key, value.toJson())),
      );
      await prefs.setString('exercise_media_cache', cacheJson);
    } catch (e) {
      print('⚠️ Error saving exercise media cache: $e');
    }
  }
  
  /// Preload animations for a list of exercises (background)
  Future<void> preloadExercises(List<String> exerciseIds) async {
    await initialize();
    
    for (final id in exerciseIds) {
      if (!_cache.containsKey(id)) {
        // Load in background, don't block
        getAnimationUrl(id).then((_) {
          print('📦 Preloaded animation for: $id');
        }).catchError((e) {
          print('⚠️ Failed to preload $id: $e');
        });
      }
    }
  }
  
  /// Clear cache (for debugging)
  Future<void> clearCache() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('exercise_media_cache');
    print('🗑️ Cleared exercise media cache');
  }
}

/// =============================================================================
/// STATIC MAPPING: Exercise IDs to ExerciseDB Names
/// =============================================================================
/// This maps our internal IDs to ExerciseDB search terms
/// Used for API queries (when API key is added)
/// =============================================================================

class ExerciseDbMapping {
  static const Map<String, String> exerciseToDbName = {
    // PUSH
    'pushups': 'push up',
    'push_ups': 'push up',
    'bench_press': 'barbell bench press',
    'incline_press': 'incline bench press',
    'overhead_press': 'shoulder press',
    'tricep_dips': 'triceps dip',
    'diamond_pushups': 'diamond push up',
    
    // SQUAT
    'squats': 'squat',
    'air_squats': 'air squat',
    'goblet_squats': 'goblet squat',
    'jump_squats': 'jump squat',
    'lunges': 'lunge',
    'bulgarian_split_squat': 'bulgarian split squat',
    'leg_press': 'leg press',
    'burpees': 'burpee',
    
    // HINGE
    'deadlift': 'deadlift',
    'romanian_deadlift': 'romanian deadlift',
    'glute_bridge': 'glute bridge',
    'hip_thrust': 'hip thrust',
    'kettlebell_swings': 'kettlebell swing',
    'good_mornings': 'good morning',
    
    // PULL
    'pull_ups': 'pull up',
    'pullups': 'pull up',
    'chin_ups': 'chin up',
    'lat_pulldowns': 'lat pulldown',
    'bent_over_rows': 'bent over row',
    'cable_rows': 'cable row',
    'dumbbell_row': 'dumbbell row',
    
    // CURL
    'bicep_curls': 'bicep curl',
    'hammer_curls': 'hammer curl',
    'barbell_curl': 'barbell curl',
    'tricep_extensions': 'tricep extension',
    'skull_crushers': 'skull crusher',
    
    // CORE
    'sit_ups': 'sit up',
    'situps': 'sit up',
    'crunches': 'crunch',
    'leg_raises': 'leg raise',
    'plank': 'plank',
    'plank_hold': 'plank',
    'russian_twists': 'russian twist',
    'mountain_climbers': 'mountain climber',
    
    // Add more as needed...
  };
  
  static String getDbName(String exerciseId) {
    final normalized = exerciseId.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return exerciseToDbName[normalized] ?? normalized.replaceAll('_', ' ');
  }
}

