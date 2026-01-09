import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../core/patterns/movement_engine.dart';
import '../core/patterns/base_pattern.dart';
import 'voice_coach.dart';
import '../models/rep_quality.dart';

// Export RepState and RepCounter for UI access
export '../core/patterns/base_pattern.dart' show RepState;

/// Manages the active workout session
/// Connects: Pose Detection → Rep Counter → Voice Coach
class WorkoutSession {
  final VoiceCoach _voice = VoiceCoach();
  MovementEngine _engine = MovementEngine();
  String _currentExerciseId = '';
  bool _baselineCaptured = false;

  // Current state
  int _currentSetIndex = 0;
  int _targetReps = 0;
  int _targetSets = 0;
  bool _isActive = false;
  bool _isResting = false;
  
  // GAMING: Combo tracking
  int _currentCombo = 0;
  int _maxCombo = 0;
  int _comboBrokenCount = 0;
  int _perfectReps = 0;
  int _goodReps = 0;
  int _missedReps = 0;
  List<RepData> _repHistory = [];
  DateTime? _setStartTime;
  
  // Callbacks
  Function(int reps, double formScore)? onRepCounted;
  Function(String feedback)? onFeedback;
  Function(int setComplete, int totalSets)? onSetComplete;
  Function(int combo, int maxCombo)? onComboChange;
  Function(RepQuality quality, double formScore)? onRepQuality;
  
  // Getters
  bool get isActive => _isActive;
  bool get isResting => _isResting;
  int get currentReps => _engine.repCount ?? 0;
  int get currentSet => _currentSetIndex + 1;
  int get targetReps => _targetReps;
  int get targetSets => _targetSets;
  double get currentAngle => (_engine.chargeProgress * 100) ?? 0;
  double get formScore => (_engine.chargeProgress * 100) ?? 0;
  String get feedback => _engine.feedback ?? '';
  String get exerciseName => _currentExerciseId;
  String get phase => _engine.state.name ?? '';

  // GAMING: Combo getters
  int get currentCombo => _currentCombo;
  int get maxCombo => _maxCombo;
  int get perfectReps => _perfectReps;
  int get goodReps => _goodReps;
  int get missedReps => _missedReps;
  List<RepData> get repHistory => List.unmodifiable(_repHistory);

  // GAMING: Real-time charge progress for power gauge and skeleton state
  // Patterns already return 0.0 to 1.0, just pass through
  double get chargeProgress => _engine.chargeProgress;
  RepState? get repState => _engine.state;
  
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
    // Load the pattern for this exercise
    if (!MovementEngine.hasPattern(exerciseId)) {
      print('⚠️ No tracking pattern for: $exerciseId');
      return;
    }

    _currentExerciseId = exerciseId;
    _engine.loadExercise(exerciseId);
    _baselineCaptured = false;
    _targetSets = sets;
    _targetReps = reps;
    _currentSetIndex = 0;
    _isActive = true;
    _isResting = false;

    // GAMING: Reset combo tracking for new exercise
    _currentCombo = 0;
    _maxCombo = 0;
    _comboBrokenCount = 0;
    _perfectReps = 0;
    _goodReps = 0;
    _missedReps = 0;
    _repHistory = [];
    _setStartTime = DateTime.now();

    _voice.announceExercise(exerciseId, sets, reps);
  }
  
  /// Process pose landmarks from camera
  /// Call this every frame with the detected landmarks
  void processPose(List<PoseLandmark> landmarks) {
    if (!_isActive || _isResting || _engine == null) return;

    // Capture baseline on first frame to lock on to user
    if (!_baselineCaptured) {
      _engine.captureBaseline(landmarks);
      _baselineCaptured = true;
      return; // Don't process first frame
    }

    bool repCompleted = _engine.processFrame(landmarks);

    if (repCompleted) {
      _onRepCompleted();
    }

    // Send feedback if changed
    if (_engine.feedback.isNotEmpty) {
      onFeedback?.call(_engine.feedback);
    }
  }
  
  void _onRepCompleted() {
    final reps = _engine.repCount;
    final score = (_engine.chargeProgress * 100);

    // GAMING: Classify rep quality
    final quality = classifyRep(score);

    // GAMING: Update combo
    if (quality == RepQuality.perfect || quality == RepQuality.good) {
      _currentCombo++;
      if (_currentCombo > _maxCombo) {
        _maxCombo = _currentCombo;
      }
    } else {
      // Combo broken
      if (_currentCombo >= 3) {
        _comboBrokenCount++;
      }
      _currentCombo = 0;
    }

    // GAMING: Track rep stats
    switch (quality) {
      case RepQuality.perfect:
        _perfectReps++;
        break;
      case RepQuality.good:
        _goodReps++;
        break;
      case RepQuality.miss:
        _missedReps++;
        break;
    }

    // GAMING: Store rep data
    _repHistory.add(RepData(
      quality: quality,
      formScore: score,
      angle: (_engine.chargeProgress * 100),
      timestamp: DateTime.now(),
    ));

    // GAMING: Fire callbacks
    onRepQuality?.call(quality, score);
    onComboChange?.call(_currentCombo, _maxCombo);

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

    // CRITICAL FIX: Reset the pattern state AND force baseline recapture
    // This allows the engine to lock onto the user's current position for the new set
    _engine.reset();  // Resets rep count and pattern state to ready
    _baselineCaptured = false;  // Forces baseline recapture on next frame

    // Reset combo tracking for new set
    _currentCombo = 0;
    _repHistory = [];
    _setStartTime = DateTime.now();

    _voice.speakNow('Set ${_currentSetIndex + 1}. Go!');
  }
  
  /// Manually skip to next set (if user wants to end set early)
  void skipToNextSet() {
    _onSetComplete();
  }
  
  /// Reset the current exercise (start over)
  void resetExercise() {
    _engine.reset();
    _baselineCaptured = false;
    _currentSetIndex = 0;
    _isResting = false;
  }
  
  /// Stop the session
  void stop() {
    _isActive = false;
    _isResting = false;
    _engine.reset();
    _currentExerciseId = '';
  }
  
  Future<void> dispose() async {
    await _voice.dispose();
  }
}
