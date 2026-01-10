import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// HOLD PATTERN - Timed Static Holds
/// =============================================================================
/// Used for: planks, wall_sits, dead_hangs, stretches
/// 
/// Logic: Check if user maintains position. Accumulate time while held.
/// repCount returns SECONDS held, not actual reps.
/// =============================================================================

enum HoldType { plank, wallSit, hang, stretch }

class HoldPattern implements BasePattern {
  final HoldType holdType;
  final String cueGood;
  final String cueBad;
  
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _secondsHeld = 0;
  String _feedback = "";
  bool _justHitTrigger = false;
  
  DateTime? _holdStartTime;
  DateTime? _lastSecondTick;
  bool _isInPosition = false;
  
  // Baseline values for position checking
  double _baselineValue = 0;
  static const double _tolerance = 0.20; // 20% tolerance
  
  HoldPattern({
    this.holdType = HoldType.plank,
    this.cueGood = "Hold it!",
    this.cueBad = "Get in position!",
  });
  
  @override RepState get state => _state;
  @override bool get isLocked => _baselineCaptured;
  @override int get repCount => _secondsHeld;
  @override String get feedback => _feedback;
  @override bool get justHitTrigger => _justHitTrigger;
  
  @override
  double get chargeProgress {
    if (!_isInPosition) return 0;
    int targetSeconds = 30;
    return (_secondsHeld / targetSeconds).clamp(0.0, 1.0);
  }
  
  double _calculateAngle(PoseLandmark a, PoseLandmark v, PoseLandmark b) {
    double v1x = a.x - v.x, v1y = a.y - v.y;
    double v2x = b.x - v.x, v2y = b.y - v.y;
    double dot = (v1x * v2x) + (v1y * v2y);
    double mag1 = math.sqrt(v1x * v1x + v1y * v1y);
    double mag2 = math.sqrt(v2x * v2x + v2y * v2y);
    if (mag1 < 0.001 || mag2 < 0.001) return 180;
    double cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180 / math.pi;
  }
  
  @override
  void captureBaseline(Map<PoseLandmarkType, PoseLandmark> map) {
    bool valid = false;
    
    switch (holdType) {
      case HoldType.plank:
        final shoulder = map[PoseLandmarkType.leftShoulder];
        final hip = map[PoseLandmarkType.leftHip];
        final ankle = map[PoseLandmarkType.leftAnkle];
        if (shoulder != null && hip != null && ankle != null) {
          _baselineValue = _calculateAngle(shoulder, hip, ankle);
          valid = true;
        }
        break;
        
      case HoldType.wallSit:
        final hip = map[PoseLandmarkType.leftHip];
        final knee = map[PoseLandmarkType.leftKnee];
        final ankle = map[PoseLandmarkType.leftAnkle];
        if (hip != null && knee != null && ankle != null) {
          _baselineValue = _calculateAngle(hip, knee, ankle);
          valid = true;
        }
        break;
        
      case HoldType.hang:
      case HoldType.stretch:
        final shoulder = map[PoseLandmarkType.leftShoulder];
        final elbow = map[PoseLandmarkType.leftElbow];
        final wrist = map[PoseLandmarkType.leftWrist];
        if (shoulder != null && elbow != null && wrist != null) {
          _baselineValue = _calculateAngle(shoulder, elbow, wrist);
          valid = true;
        }
        break;
    }
    
    if (!valid) {
      _feedback = "Body not in frame";
      return;
    }
    
    _baselineCaptured = true;
    _state = RepState.ready;
    _feedback = "LOCKED - Hold position!";
    _holdStartTime = DateTime.now();
    _lastSecondTick = DateTime.now();
    _isInPosition = true;
  }
  
  @override
  bool processFrame(Map<PoseLandmarkType, PoseLandmark> map) {
    if (!_baselineCaptured) {
      _feedback = "Waiting for lock";
      return false;
    }
    
    _justHitTrigger = false;
    
    double currentValue = 0;
    bool canCheck = false;
    
    switch (holdType) {
      case HoldType.plank:
        final shoulder = map[PoseLandmarkType.leftShoulder];
        final hip = map[PoseLandmarkType.leftHip];
        final ankle = map[PoseLandmarkType.leftAnkle];
        if (shoulder != null && hip != null && ankle != null) {
          currentValue = _calculateAngle(shoulder, hip, ankle);
          canCheck = true;
        }
        break;
        
      case HoldType.wallSit:
        final hip = map[PoseLandmarkType.leftHip];
        final knee = map[PoseLandmarkType.leftKnee];
        final ankle = map[PoseLandmarkType.leftAnkle];
        if (hip != null && knee != null && ankle != null) {
          currentValue = _calculateAngle(hip, knee, ankle);
          canCheck = true;
        }
        break;
        
      case HoldType.hang:
      case HoldType.stretch:
        final shoulder = map[PoseLandmarkType.leftShoulder];
        final elbow = map[PoseLandmarkType.leftElbow];
        final wrist = map[PoseLandmarkType.leftWrist];
        if (shoulder != null && elbow != null && wrist != null) {
          currentValue = _calculateAngle(shoulder, elbow, wrist);
          canCheck = true;
        }
        break;
    }
    
    if (!canCheck) {
      _feedback = "Stay in frame";
      _isInPosition = false;
      return false;
    }
    
    double deviation = (currentValue - _baselineValue).abs() / _baselineValue;
    _isInPosition = deviation <= _tolerance;
    
    if (_isInPosition) {
      _state = RepState.down;
      
      if (_lastSecondTick != null) {
        int elapsed = DateTime.now().difference(_lastSecondTick!).inSeconds;
        if (elapsed >= 1) {
          _secondsHeld += elapsed;
          _lastSecondTick = DateTime.now();
          _feedback = "${_secondsHeld}s - $cueGood";
          _justHitTrigger = true;
          return true;
        }
      }
      _feedback = "${_secondsHeld}s - $cueGood";
    } else {
      _state = RepState.ready;
      _feedback = cueBad;
      _lastSecondTick = DateTime.now();
    }
    
    return false;
  }
  
  @override
  void reset() {
    _secondsHeld = 0;
    _state = RepState.ready;
    _feedback = "";
    _baselineCaptured = false;
    _holdStartTime = null;
    _lastSecondTick = null;
    _isInPosition = false;
    _justHitTrigger = false;
  }
}

