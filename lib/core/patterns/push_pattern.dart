import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// PUSH PATTERN - Shoulder-to-Wrist Y Distance
/// =============================================================================
/// Used for: push_ups, bench_press, overhead_press, dips, etc.
/// 
/// Normal mode (inverted=false): Triggers when gap SHRINKS (pushup, bench)
/// Inverted mode (inverted=true): Triggers when gap GROWS (overhead press)
/// =============================================================================

class PushPattern implements BasePattern {
  // Config
  final bool inverted; // true for overhead press, false for pushup
  final String cueGood;
  final String cueBad;
  
  // State
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  bool _justHitTrigger = false;
  
  // Baseline
  double _baselineTarget = 0;
  
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
    this.inverted = false,
    this.cueGood = "Perfect!",
    this.cueBad = "Full range!",
  });
  
  @override RepState get state => _state;
  @override bool get isLocked => _baselineCaptured;
  @override int get repCount => _repCount;
  @override String get feedback => _feedback;
  @override bool get justHitTrigger => _justHitTrigger;
  
  @override
  double get chargeProgress {
    if (inverted) {
      // Overhead press: progress as gap grows (percentage increases)
      double progress = (_currentPercentage - 100) / 50; // 100% -> 150% = full progress
      return progress.clamp(0.0, 1.0);
    } else {
      // Pushup: progress as gap shrinks (percentage decreases)
      double progress = (100 - _currentPercentage) / 10;
      return progress.clamp(0.0, 1.0);
    }
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
    
    double shoulderY = (lShoulder.y + rShoulder.y) / 2;
    double wristY = (lWrist.y + rWrist.y) / 2;
    double currentYDiff = (wristY - shoulderY).abs();
    
    double rawPercentage = 100;
    if (_baselineTarget > 0.01) {
      rawPercentage = (currentYDiff / _baselineTarget) * 100;
    }
    
    _smoothedPercentage = (_smoothingFactor * rawPercentage) + ((1 - _smoothingFactor) * _smoothedPercentage);
    _currentPercentage = _smoothedPercentage.clamp(0, 200);
    
    // DIRECTION-AWARE TRIGGERS
    bool isDown;
    bool isReset;
    
    if (inverted) {
      // Overhead press: trigger when gap GROWS (percentage > 140%)
      isDown = _currentPercentage >= 140;
      isReset = _currentPercentage <= 110;
    } else {
      // Pushup: trigger when gap SHRINKS (percentage < 90%)
      isDown = _currentPercentage <= 90;
      isReset = _currentPercentage >= 95;
    }
    
    // State machine (EXACT SAME AS WORKING PATTERNS)
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
          if (!isReset) {
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
    _baselineCaptured = false;
    _smoothedPercentage = 100;
    _currentPercentage = 100;
    _justHitTrigger = false;
  }
}
