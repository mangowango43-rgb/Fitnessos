import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// KNEE DRIVE PATTERN - Alternating Knee Raises
/// =============================================================================
/// Used for: mountain_climbers, high_knees, bicycle_crunches, flutter_kicks
/// 
/// Logic: Track both knees. Count when EITHER knee rises above hip level.
/// Requires alternating - won't count same leg twice in a row.
/// =============================================================================

class KneeDrivePattern implements BasePattern {
  final double triggerPercent;
  final String cueGood;
  final String cueBad;
  
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  bool _justHitTrigger = false;
  
  double _baselineHipY = 0;
  double _baselineLegLength = 0;
  bool _lastWasLeft = false;
  bool _waitingForReset = false;
  
  static const double _smoothingFactor = 0.3;
  double _smoothedLeftKneeY = 0;
  double _smoothedRightKneeY = 0;
  DateTime _lastRepTime = DateTime.now();
  static const int _minTimeBetweenRepsMs = 200;
  
  KneeDrivePattern({
    this.triggerPercent = 0.15,
    this.cueGood = "Drive!",
    this.cueBad = "Knees up!",
  });
  
  @override RepState get state => _state;
  @override bool get isLocked => _baselineCaptured;
  @override int get repCount => _repCount;
  @override String get feedback => _feedback;
  @override bool get justHitTrigger => _justHitTrigger;
  
  @override
  double get chargeProgress {
    if (!_baselineCaptured) return 0;
    double leftRise = (_baselineHipY - _smoothedLeftKneeY) / _baselineLegLength;
    double rightRise = (_baselineHipY - _smoothedRightKneeY) / _baselineLegLength;
    double maxRise = math.max(leftRise, rightRise);
    return (maxRise / triggerPercent).clamp(0.0, 1.0);
  }
  
  @override
  void captureBaseline(Map<PoseLandmarkType, PoseLandmark> map) {
    final lHip = map[PoseLandmarkType.leftHip];
    final rHip = map[PoseLandmarkType.rightHip];
    final lKnee = map[PoseLandmarkType.leftKnee];
    final rKnee = map[PoseLandmarkType.rightKnee];
    final lAnkle = map[PoseLandmarkType.leftAnkle];
    
    if (lHip == null || lKnee == null || lAnkle == null) {
      _feedback = "Body not in frame";
      return;
    }
    
    _baselineHipY = rHip != null ? (lHip.y + rHip.y) / 2 : lHip.y;
    _baselineLegLength = (lAnkle.y - lHip.y).abs();
    if (_baselineLegLength < 0.01) _baselineLegLength = 100;
    
    _smoothedLeftKneeY = lKnee.y;
    _smoothedRightKneeY = rKnee?.y ?? lKnee.y;
    
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
    
    final lHip = map[PoseLandmarkType.leftHip];
    final rHip = map[PoseLandmarkType.rightHip];
    final lKnee = map[PoseLandmarkType.leftKnee];
    final rKnee = map[PoseLandmarkType.rightKnee];
    
    if (lHip == null || lKnee == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    double currentHipY = rHip != null ? (lHip.y + rHip.y) / 2 : lHip.y;
    
    _smoothedLeftKneeY = (_smoothingFactor * lKnee.y) + ((1 - _smoothingFactor) * _smoothedLeftKneeY);
    if (rKnee != null) {
      _smoothedRightKneeY = (_smoothingFactor * rKnee.y) + ((1 - _smoothingFactor) * _smoothedRightKneeY);
    }
    
    double triggerY = currentHipY - (_baselineLegLength * triggerPercent);
    double resetY = currentHipY + (_baselineLegLength * 0.05);
    
    bool leftTriggered = _smoothedLeftKneeY < triggerY;
    bool rightTriggered = _smoothedRightKneeY < triggerY;
    bool leftReset = _smoothedLeftKneeY > resetY;
    bool rightReset = _smoothedRightKneeY > resetY;
    
    if (_waitingForReset) {
      if ((_lastWasLeft && leftReset) || (!_lastWasLeft && rightReset)) {
        _waitingForReset = false;
        _state = RepState.ready;
      }
      return false;
    }
    
    if (DateTime.now().difference(_lastRepTime).inMilliseconds > _minTimeBetweenRepsMs) {
      if (leftTriggered && !_lastWasLeft) {
        _repCount++;
        _lastWasLeft = true;
        _waitingForReset = true;
        _lastRepTime = DateTime.now();
        _feedback = cueGood;
        _state = RepState.down;
        _justHitTrigger = true;
        return true;
      } else if (rightTriggered && _lastWasLeft) {
        _repCount++;
        _lastWasLeft = false;
        _waitingForReset = true;
        _lastRepTime = DateTime.now();
        _feedback = cueGood;
        _state = RepState.down;
        _justHitTrigger = true;
        return true;
      } else if ((leftTriggered || rightTriggered) && _repCount == 0) {
        _repCount++;
        _lastWasLeft = leftTriggered;
        _waitingForReset = true;
        _lastRepTime = DateTime.now();
        _feedback = cueGood;
        _state = RepState.down;
        _justHitTrigger = true;
        return true;
      }
    }
    
    if (!leftTriggered && !rightTriggered) {
      _feedback = cueBad;
    }
    
    return false;
  }
  
  @override
  void reset() {
    _repCount = 0;
    _state = RepState.ready;
    _feedback = "";
    _baselineCaptured = false;
    _lastWasLeft = false;
    _waitingForReset = false;
    _justHitTrigger = false;
  }
}

