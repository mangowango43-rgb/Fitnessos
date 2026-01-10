import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// PUSH PATTERN - Shoulder-to-Wrist Y Distance
/// =============================================================================
/// Used for: push_ups, bench_press, tricep_dips, overhead_press, etc.
/// 
/// Logic: Track vertical distance between shoulders and wrists.
/// When you go down, this distance SHRINKS.
/// When you come up, it GROWS back.
/// =============================================================================

class PushPattern implements BasePattern {
  // Config
  final String cueGood;
  final String cueBad;
  
  // State
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  bool _justHitTrigger = false;
  
  // Baseline
  double _baselineTarget = 0; // Y-distance between shoulders and wrists at start
  
  // Current values
  double _currentPercentage = 100;
  double _smoothedPercentage = 100;
  
  // Anti-ghost
  static const double _smoothingFactor = 0.3;
  DateTime? _intentTimer;
  DateTime _lastRepTime = DateTime.now();
  static const int _intentDelayMs = 250;
  static const int _minTimeBetweenRepsMs = 500;
  
  PushPattern({
    this.cueGood = "Perfect!",
    this.cueBad = "Go lower!",
  });
  
  // Getters
  @override
  RepState get state => _state;
  @override
  bool get isLocked => _baselineCaptured;
  @override
  int get repCount => _repCount;
  @override
  String get feedback => _feedback;
  @override
  bool get justHitTrigger => _justHitTrigger;
  
  @override
  double get chargeProgress {
    // 100% = up, 90% = down trigger
    // So progress = (100 - current) / (100 - 90) = (100 - current) / 10
    double progress = (100 - _currentPercentage) / 10;
    return progress.clamp(0.0, 1.0);
  }
  
  // Helper: 3D distance
  double _dist3D(PoseLandmark a, PoseLandmark b) {
    return math.sqrt(
      math.pow(b.x - a.x, 2) + 
      math.pow(b.y - a.y, 2) + 
      math.pow(b.z - a.z, 2)
    );
  }
  
  @override
  void captureBaseline(Map<PoseLandmarkType, PoseLandmark> map) {
    final lShoulder = map[PoseLandmarkType.leftShoulder];
    final rShoulder = map[PoseLandmarkType.rightShoulder];
    final lWrist = map[PoseLandmarkType.leftWrist];
    final rWrist = map[PoseLandmarkType.rightWrist];
    
    if (lShoulder == null || rShoulder == null || lWrist == null || rWrist == null) {
      _feedback = "Body not in frame";
      return;
    }
    
    // Store Y-distance between shoulders and wrists (vertical gap)
    double shoulderY = (lShoulder.y + rShoulder.y) / 2;
    double wristY = (lWrist.y + rWrist.y) / 2;
    _baselineTarget = (wristY - shoulderY).abs();
    
    if (_baselineTarget < 0.01) {
      _feedback = "Move back";
      return;
    }
    
    _smoothedPercentage = 100;
    _baselineCaptured = true;
    _state = RepState.ready;
    _feedback = "LOCKED";
  }
  
  @override
  bool processFrame(Map<PoseLandmarkType, PoseLandmark> map) {
    if (!_baselineCaptured) {
      _feedback = "Waiting for lock";
      return false;
    }

    _justHitTrigger = false;
    
    final lShoulder = map[PoseLandmarkType.leftShoulder];
    final rShoulder = map[PoseLandmarkType.rightShoulder];
    final lWrist = map[PoseLandmarkType.leftWrist];
    final rWrist = map[PoseLandmarkType.rightWrist];
    
    if (lShoulder == null || rShoulder == null || lWrist == null || rWrist == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    // Calculate current Y-distance
    double shoulderY = (lShoulder.y + rShoulder.y) / 2;
    double wristY = (lWrist.y + rWrist.y) / 2;
    double currentYDiff = (wristY - shoulderY).abs();
    
    // Calculate percentage
    double rawPercentage = 100;
    if (_baselineTarget > 0.01) {
      rawPercentage = (currentYDiff / _baselineTarget) * 100;
    }
    
    // Smooth it
    _smoothedPercentage = (_smoothingFactor * rawPercentage) + ((1 - _smoothingFactor) * _smoothedPercentage);
    _currentPercentage = _smoothedPercentage.clamp(0, 150);
    
    // Check triggers
    bool isDown = _currentPercentage <= 90; // Gap shrinks to 90% = down
    bool isReset = _currentPercentage >= 95; // Back to 95% = up
    
    // State machine
    switch (_state) {
      case RepState.ready:
      case RepState.up:
        if (isDown) {
          _intentTimer ??= DateTime.now();
          if (DateTime.now().difference(_intentTimer!).inMilliseconds > _intentDelayMs) {
            _state = RepState.down;
            _feedback = cueGood;
            _intentTimer = null;
            _justHitTrigger = true;
          } else {
            _state = RepState.goingDown;
          }
        } else {
          _intentTimer = null;
          _state = RepState.ready;
          if (!isReset && _currentPercentage < 95) {
            _feedback = cueBad;
          } else {
            _feedback = "";
          }
        }
        return false;
        
      case RepState.goingDown:
        if (isDown) {
          _intentTimer ??= DateTime.now();
          if (DateTime.now().difference(_intentTimer!).inMilliseconds > _intentDelayMs) {
            _state = RepState.down;
            _feedback = cueGood;
            _intentTimer = null;
            _justHitTrigger = true;
          }
        } else {
          _intentTimer = null;
          _state = RepState.ready;
        }
        return false;

      case RepState.down:
        if (isReset) {
          _state = RepState.goingUp;
        }
        return false;
        
      case RepState.goingUp:
        if (isReset) {
          if (DateTime.now().difference(_lastRepTime).inMilliseconds > _minTimeBetweenRepsMs) {
            _state = RepState.up;
            _repCount++;
            _lastRepTime = DateTime.now();
            _feedback = "";
            return true; // REP COUNTED
          }
        } else {
          _state = RepState.down;
        }
        return false;
    }
  }
  
  @override
  void reset() {
    _repCount = 0;
    _state = RepState.ready;
    _feedback = "";
    _intentTimer = null;
    _baselineCaptured = false;  // CRITICAL: Allow re-lock for Set 2
    _smoothedPercentage = 100;
    _currentPercentage = 100;
    _justHitTrigger = false;
  }
}

