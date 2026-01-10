import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// CALF PATTERN - Ankle Rise (Heel Raise)
/// =============================================================================
/// Used for: calf_raises, standing_calf_raise, seated_calf_raise
/// 
/// Logic: Track ankle Y-position relative to baseline.
/// When ankles rise (Y decreases), count rep.
/// =============================================================================

class CalfPattern implements BasePattern {
  final String cueGood;
  final String cueBad;
  
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  bool _justHitTrigger = false;
  
  double _baselineAnkleY = 0;
  double _baselineKneeY = 0;
  double _currentRisePercent = 0;
  double _smoothedRisePercent = 0;
  
  static const double _triggerRisePercent = 8;
  static const double _resetRisePercent = 3;
  
  static const double _smoothingFactor = 0.3;
  DateTime? _intentTimer;
  DateTime _lastRepTime = DateTime.now();
  static const int _intentDelayMs = 150;
  static const int _minTimeBetweenRepsMs = 400;
  
  CalfPattern({
    this.cueGood = "Squeeze!",
    this.cueBad = "Higher!",
  });
  
  @override RepState get state => _state;
  @override bool get isLocked => _baselineCaptured;
  @override int get repCount => _repCount;
  @override String get feedback => _feedback;
  @override bool get justHitTrigger => _justHitTrigger;
  
  @override
  double get chargeProgress {
    double progress = _currentRisePercent / _triggerRisePercent;
    return progress.clamp(0.0, 1.0);
  }
  
  @override
  void captureBaseline(Map<PoseLandmarkType, PoseLandmark> map) {
    final lAnkle = map[PoseLandmarkType.leftAnkle];
    final rAnkle = map[PoseLandmarkType.rightAnkle];
    final lKnee = map[PoseLandmarkType.leftKnee];
    final rKnee = map[PoseLandmarkType.rightKnee];
    
    if (lAnkle == null || lKnee == null) {
      _feedback = "Body not in frame";
      return;
    }
    
    _baselineAnkleY = rAnkle != null ? (lAnkle.y + rAnkle.y) / 2 : lAnkle.y;
    _baselineKneeY = rKnee != null ? (lKnee.y + rKnee.y) / 2 : lKnee.y;
    
    _smoothedRisePercent = 0;
    _currentRisePercent = 0;
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
    
    final lAnkle = map[PoseLandmarkType.leftAnkle];
    final rAnkle = map[PoseLandmarkType.rightAnkle];
    
    if (lAnkle == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    double currentAnkleY = rAnkle != null ? (lAnkle.y + rAnkle.y) / 2 : lAnkle.y;
    
    double legLength = (_baselineAnkleY - _baselineKneeY).abs();
    if (legLength < 0.01) legLength = 100;
    
    double rise = _baselineAnkleY - currentAnkleY;
    double rawRisePercent = (rise / legLength) * 100;
    
    _smoothedRisePercent = (_smoothingFactor * rawRisePercent) + ((1 - _smoothingFactor) * _smoothedRisePercent);
    _currentRisePercent = _smoothedRisePercent;
    
    bool isUp = _currentRisePercent >= _triggerRisePercent;
    bool isReset = _currentRisePercent <= _resetRisePercent;
    
    switch (_state) {
      case RepState.ready:
      case RepState.up:
        if (isUp) {
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
          if (_currentRisePercent > _resetRisePercent) {
            _feedback = cueBad;
          } else {
            _feedback = "";
          }
        }
        return false;
        
      case RepState.goingDown:
        if (isUp) {
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
            return true;
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
    _smoothedRisePercent = 0;
    _currentRisePercent = 0;
    _justHitTrigger = false;
  }
}

