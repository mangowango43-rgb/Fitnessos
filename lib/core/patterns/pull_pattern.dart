import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// PULL PATTERN - Elbow Angle
/// =============================================================================
/// Used for: pull_ups, lat_pulldowns, bent_over_rows, cable_rows, etc.
/// 
/// Logic: Track the angle at the elbow (shoulder-elbow-wrist).
/// When you pull, the elbow CLOSES (angle gets smaller).
/// When you release, it OPENS (angle gets bigger).
/// =============================================================================

class PullPattern implements BasePattern {
  // Config
  final double triggerAngle; // e.g. 75 = trigger when elbow closes to 75°
  final double resetAngle; // e.g. 155 = reset when elbow opens to 155°
  final String cueGood;
  final String cueBad;
  
  // State
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  bool _justHitTrigger = false;
  
  // Current values
  double _currentAngle = 180;
  double _smoothedAngle = 180;
  
  // Anti-ghost
  static const double _smoothingFactor = 0.3;
  DateTime? _intentTimer;
  DateTime _lastRepTime = DateTime.now();
  static const int _intentDelayMs = 250;
  static const int _minTimeBetweenRepsMs = 500;
  
  PullPattern({
    this.triggerAngle = 75,
    this.resetAngle = 155,
    this.cueGood = "Chin up!",
    this.cueBad = "Full hang!",
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
    // 180° = hanging, triggerAngle = pulled up
    double progress = (180 - _currentAngle) / (180 - triggerAngle);
    return progress.clamp(0.0, 1.0);
  }
  
  // Helper: Calculate angle at vertex point
  double _calculateAngle(PoseLandmark a, PoseLandmark v, PoseLandmark b) {
    double v1x = a.x - v.x, v1y = a.y - v.y, v1z = a.z - v.z;
    double v2x = b.x - v.x, v2y = b.y - v.y, v2z = b.z - v.z;
    
    double dot = (v1x * v2x) + (v1y * v2y) + (v1z * v2z);
    double mag1 = math.sqrt(v1x * v1x + v1y * v1y + v1z * v1z);
    double mag2 = math.sqrt(v2x * v2x + v2y * v2y + v2z * v2z);
    
    if (mag1 < 0.001 || mag2 < 0.001) return 180;
    
    double cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180 / math.pi;
  }
  
  @override
  void captureBaseline(Map<PoseLandmarkType, PoseLandmark> map) {
    final shoulder = map[PoseLandmarkType.leftShoulder];
    final elbow = map[PoseLandmarkType.leftElbow];
    final wrist = map[PoseLandmarkType.leftWrist];
    
    if (shoulder == null || elbow == null || wrist == null) {
      _feedback = "Body not in frame";
      return;
    }
    
    _smoothedAngle = 180;
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
    
    final shoulder = map[PoseLandmarkType.leftShoulder];
    final elbow = map[PoseLandmarkType.leftElbow];
    final wrist = map[PoseLandmarkType.leftWrist];
    
    if (shoulder == null || elbow == null || wrist == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    // Calculate elbow angle (shoulder-elbow-wrist)
    double rawAngle = _calculateAngle(shoulder, elbow, wrist);
    
    // Smooth it
    _smoothedAngle = (_smoothingFactor * rawAngle) + ((1 - _smoothingFactor) * _smoothedAngle);
    _currentAngle = _smoothedAngle;
    
    // Check triggers
    bool isDown = _currentAngle <= triggerAngle;
    bool isReset = _currentAngle >= resetAngle;
    
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
          _feedback = "";
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
    _smoothedAngle = 180;
    _currentAngle = 180;
    _justHitTrigger = false;
  }
}

