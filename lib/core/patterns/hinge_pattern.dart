import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// HINGE PATTERN - Hip Angle
/// =============================================================================
/// Used for: deadlift, romanian_deadlift, glute_bridge, kettlebell_swings, etc.
/// 
/// Logic: Track the angle at the hip (shoulder-hip-knee).
/// When you hinge forward, this angle CLOSES (gets smaller).
/// When you stand up, it OPENS (gets bigger).
/// =============================================================================

class HingePattern implements BasePattern {
  // Config
  final double triggerAngle; // e.g. 105 = trigger when angle drops to 105°
  final double resetAngle; // e.g. 165 = reset when angle returns to 165°
  final String cueGood;
  final String cueBad;
  
  // State
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  
  // Current values
  double _currentAngle = 180;
  double _smoothedAngle = 180;
  
  // Anti-ghost
  static const double _smoothingFactor = 0.3;
  DateTime? _intentTimer;
  DateTime _lastRepTime = DateTime.now();
  static const int _intentDelayMs = 250;
  static const int _minTimeBetweenRepsMs = 500;
  
  HingePattern({
    this.triggerAngle = 105,
    this.resetAngle = 165,
    this.cueGood = "Lockout!",
    this.cueBad = "Hips forward!",
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
  double get chargeProgress {
    // 180° = standing, triggerAngle = hinged
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
    final hip = map[PoseLandmarkType.leftHip];
    final knee = map[PoseLandmarkType.leftKnee];
    
    if (shoulder == null || hip == null || knee == null) {
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
    
    final shoulder = map[PoseLandmarkType.leftShoulder];
    final hip = map[PoseLandmarkType.leftHip];
    final knee = map[PoseLandmarkType.leftKnee];
    
    if (shoulder == null || hip == null || knee == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    // Calculate hip angle (shoulder-hip-knee)
    double rawAngle = _calculateAngle(shoulder, hip, knee);
    
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
  }
}

