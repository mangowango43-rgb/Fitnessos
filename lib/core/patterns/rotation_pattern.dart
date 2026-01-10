import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// ROTATION PATTERN - Torso Twist
/// =============================================================================
/// Used for: russian_twists, woodchoppers, cable_rotations
/// 
/// Logic: Track shoulder position relative to hips.
/// Count rep when shoulders rotate past trigger angle from center.
/// Alternates left-right rotation.
/// =============================================================================

class RotationPattern implements BasePattern {
  final double triggerAngle;
  final String cueGood;
  final String cueBad;
  
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  bool _justHitTrigger = false;
  
  bool _lastWasLeft = false;
  double _currentRotation = 0;
  double _smoothedRotation = 0;
  
  double _baselineHipCenterX = 0;
  double _baselineShoulderWidth = 0;
  
  static const double _smoothingFactor = 0.3;
  DateTime _lastRepTime = DateTime.now();
  static const int _minTimeBetweenRepsMs = 300;
  
  RotationPattern({
    this.triggerAngle = 45,
    this.cueGood = "Twist!",
    this.cueBad = "Rotate more!",
  });
  
  @override RepState get state => _state;
  @override bool get isLocked => _baselineCaptured;
  @override int get repCount => _repCount;
  @override String get feedback => _feedback;
  @override bool get justHitTrigger => _justHitTrigger;
  
  @override
  double get chargeProgress {
    double progress = _currentRotation.abs() / triggerAngle;
    return progress.clamp(0.0, 1.0);
  }
  
  @override
  void captureBaseline(Map<PoseLandmarkType, PoseLandmark> map) {
    final lShoulder = map[PoseLandmarkType.leftShoulder];
    final rShoulder = map[PoseLandmarkType.rightShoulder];
    final lHip = map[PoseLandmarkType.leftHip];
    final rHip = map[PoseLandmarkType.rightHip];
    
    if (lShoulder == null || rShoulder == null || lHip == null || rHip == null) {
      _feedback = "Body not in frame";
      return;
    }
    
    _baselineHipCenterX = (lHip.x + rHip.x) / 2;
    _baselineShoulderWidth = (rShoulder.x - lShoulder.x).abs();
    
    _smoothedRotation = 0;
    _currentRotation = 0;
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
    final lHip = map[PoseLandmarkType.leftHip];
    final rHip = map[PoseLandmarkType.rightHip];
    
    if (lShoulder == null || rShoulder == null || lHip == null || rHip == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    double shoulderCenterX = (lShoulder.x + rShoulder.x) / 2;
    double hipCenterX = (lHip.x + rHip.x) / 2;
    
    double offset = shoulderCenterX - hipCenterX;
    double normalizedOffset = offset / (_baselineShoulderWidth + 0.01);
    double rawRotation = normalizedOffset * 90;
    
    _smoothedRotation = (_smoothingFactor * rawRotation) + ((1 - _smoothingFactor) * _smoothedRotation);
    _currentRotation = _smoothedRotation;
    
    bool rotatedLeft = _currentRotation <= -triggerAngle;
    bool rotatedRight = _currentRotation >= triggerAngle;
    
    if (DateTime.now().difference(_lastRepTime).inMilliseconds > _minTimeBetweenRepsMs) {
      if (rotatedLeft && _lastWasLeft == false) {
        _repCount++;
        _lastWasLeft = true;
        _lastRepTime = DateTime.now();
        _feedback = cueGood;
        _state = RepState.down;
        _justHitTrigger = true;
        return true;
      } else if (rotatedRight && _lastWasLeft == true) {
        _repCount++;
        _lastWasLeft = false;
        _lastRepTime = DateTime.now();
        _feedback = cueGood;
        _state = RepState.down;
        _justHitTrigger = true;
        return true;
      }
    }
    
    if (!rotatedLeft && !rotatedRight) {
      _feedback = cueBad;
      _state = RepState.ready;
    }
    
    return false;
  }
  
  @override
  void reset() {
    _repCount = 0;
    _state = RepState.ready;
    _feedback = "";
    _baselineCaptured = false;
    _smoothedRotation = 0;
    _currentRotation = 0;
    _lastWasLeft = false;
    _justHitTrigger = false;
  }
}

