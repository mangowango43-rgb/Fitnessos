import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_rules.dart';
import 'rep_counter.dart';
import 'voice_coach.dart';

/// Manages the active workout session
/// Connects: Pose Detection → Rep Counter → Voice Coach
class WorkoutSession {
  final VoiceCoach _voice = VoiceCoach();
  RepCounter? _counter;
  ExerciseRule? _currentExercise;
  
  // Current state
  int _currentSetIndex = 0;
  int _targetReps = 0;
  int _targetSets = 0;
  bool _isActive = false;
  bool _isResting = false;
  
  // Callbacks
  Function(int reps, double formScore)? onRepCounted;
  Function(String feedback)? onFeedback;
  Function(int setComplete, int totalSets)? onSetComplete;
  
  // Getters
  bool get isActive => _isActive;
  bool get isResting => _isResting;
  int get currentReps => _counter?.repCount ?? 0;
  int get currentSet => _currentSetIndex + 1;
  int get targetReps => _targetReps;
  int get targetSets => _targetSets;
  double get currentAngle => _counter?.currentAngle ?? 0;
  double get formScore => _counter?.formScore ?? 0;
  String get feedback => _counter?.feedback ?? '';
  String get exerciseName => _currentExercise?.name ?? '';
  String get phase => _counter?.state ?? '';
  
  /// Initialize the session
  Future<void> init() async {
    await _voice.init();
  }
  
  /// Start tracking an exercise
  Future<void> startExercise({
    required String exerciseId,
    required int sets,
    required int reps,
  }) async {
    final rule = HomeFullBodyRules.getRule(exerciseId);
    if (rule == null) {
      print('⚠️ No tracking rule for: $exerciseId');
      return;
    }
    
    _currentExercise = rule;
    _counter = RepCounter(rule);
    _targetSets = sets;
    _targetReps = reps;
    _currentSetIndex = 0;
    _isActive = true;
    _isResting = false;
    
    await _voice.announceExercise(rule.name, sets, reps);
  }
  
  /// Process pose landmarks from camera
  /// Call this every frame with the detected landmarks
  void processPose(List<PoseLandmark> landmarks) {
    if (!_isActive || _isResting || _counter == null) return;
    
    bool repCompleted = _counter!.processPose(landmarks);
    
    if (repCompleted) {
      _onRepCompleted();
    }
    
    // Send feedback if changed
    if (_counter!.feedback.isNotEmpty) {
      onFeedback?.call(_counter!.feedback);
    }
  }
  
  void _onRepCompleted() {
    final reps = _counter!.repCount;
    final score = _counter!.formScore;
    
    // Announce rep
    _voice.announceRep(reps);
    
    // Callback
    onRepCounted?.call(reps, score);
    
    // Check if set complete
    if (reps >= _targetReps) {
      _onSetComplete();
    }
  }
  
  void _onSetComplete() {
    _currentSetIndex++;
    
    if (_currentSetIndex >= _targetSets) {
      // Exercise complete
      _voice.announceSetComplete(_currentSetIndex, _targetSets);
      onSetComplete?.call(_currentSetIndex, _targetSets);
      _isActive = false;
    } else {
      // More sets to go
      _voice.announceSetComplete(_currentSetIndex, _targetSets);
      onSetComplete?.call(_currentSetIndex, _targetSets);
      _isResting = true;
    }
  }
  
  /// Call when rest is complete and ready for next set
  void startNextSet() {
    if (!_isResting) return;
    
    _isResting = false;
    _counter?.reset();
    _voice.speakNow('Set ${_currentSetIndex + 1}. Go!');
  }
  
  /// Manually skip to next set (if user wants to end set early)
  void skipToNextSet() {
    _onSetComplete();
  }
  
  /// Reset the current exercise (start over)
  void resetExercise() {
    _counter?.reset();
    _currentSetIndex = 0;
    _isResting = false;
  }
  
  /// Stop the session
  void stop() {
    _isActive = false;
    _isResting = false;
    _counter = null;
    _currentExercise = null;
  }
  
  Future<void> dispose() async {
    await _voice.dispose();
  }
}

