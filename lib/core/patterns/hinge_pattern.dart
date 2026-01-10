import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// HINGE PATTERN - Hip Angle (Shoulder-Hip-Knee)
/// =============================================================================
/// Used for: deadlift, glute_bridge, hip_thrust, kettlebell_swing, etc.
/// 
/// Normal mode (inverted=false): Triggers when angle DECREASES (deadlift, RDL)
/// Inverted mode (inverted=true): Triggers when angle INCREASES (glute bridge, hip thrust)
/// =============================================================================

class HingePattern implements BasePattern {
  // Config
  final double triggerAngle;
  final double resetAngle;
  final bool inverted; // true for glute bridge, false for deadlift
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
  
  HingePattern({
    this.triggerAngle = 105,
    this.resetAngle = 165,
    this.inverted = false,
    this.cueGood = "Lockout!",
    this.cueBad = "Hips forward!",
  });
  
  @override RepState get state => _state;
  @override bool get isLocked => _baselineCaptured;
  @override int get repCount => _repCount;
  @override String get feedback => _feedback;
  @override bool get justHitTrigger => _justHitTrigger;
  
  @override
  double get chargeProgress {
    if (inverted) {
      // Glute bridge: progress as angle INCREASES toward trigger
      double progress = (_currentAngle - resetAngle) / (triggerAngle - resetAngle);
      return progress.clamp(0.0, 1.0);
    } else {
      // Deadlift: progress as angle DECREASES toward trigger
      double progress = (180 - _currentAngle) / (180 - triggerAngle);
      return progress.clamp(0.0, 1.0);
    }
  }
  
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
    
    // Set initial angle based on mode
    if (inverted) {
      _smoothedAngle = resetAngle; // Start at low angle for glute bridge
    } else {
      _smoothedAngle = 180; // Start standing for deadlift
    }
    
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
    final hip = map[PoseLandmarkType.leftHip];
    final knee = map[PoseLandmarkType.leftKnee];
    
    if (shoulder == null || hip == null || knee == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    double rawAngle = _calculateAngle(shoulder, hip, knee);
    _smoothedAngle = (_smoothingFactor * rawAngle) + ((1 - _smoothingFactor) * _smoothedAngle);
    _currentAngle = _smoothedAngle;
    
    // DIRECTION-AWARE TRIGGERS
    bool isDown;
    bool isReset;
    
    if (inverted) {
      // Glute bridge: trigger when angle INCREASES past threshold
      isDown = _currentAngle >= triggerAngle;
      isReset = _currentAngle <= resetAngle;
    } else {
      // Deadlift: trigger when angle DECREASES past threshold
      isDown = _currentAngle <= triggerAngle;
      isReset = _currentAngle >= resetAngle;
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
    _baselineCaptured = false;
    _smoothedAngle = inverted ? resetAngle : 180;
    _currentAngle = _smoothedAngle;
    _justHitTrigger = false;
  }
}
