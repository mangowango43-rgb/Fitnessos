import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// CURL PATTERN - Wrist Y Position (Hip to Shoulder)
/// =============================================================================
/// Used for: bicep_curls, hammer_curls, barbell_curl, etc.
/// 
/// Logic: Track where the wrist is vertically between hip and shoulder.
/// At rest, wrist is near hip (0%).
/// At top of curl, wrist is near shoulder (100%).
/// =============================================================================

class CurlPattern implements BasePattern {
  // Config
  final String cueGood;
  final String cueBad;
  
  // State
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  
  // Current values - wrist position as % between hip and shoulder
  double _curlProgress = 0; // 0% = at hip, 100% = at shoulder
  double _smoothedCurlProgress = 0;
  
  // Anti-ghost
  static const double _smoothingFactor = 0.3;
  DateTime? _intentTimer;
  DateTime _lastRepTime = DateTime.now();
  static const int _intentDelayMs = 250;
  static const int _minTimeBetweenRepsMs = 500;
  
  CurlPattern({
    this.cueGood = "Full curl!",
    this.cueBad = "Squeeze!",
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
    return (_curlProgress / 100.0).clamp(0.0, 1.0);
  }
  
  @override
  void captureBaseline(Map<PoseLandmarkType, PoseLandmark> map) {
    final lShoulder = map[PoseLandmarkType.leftShoulder];
    final rShoulder = map[PoseLandmarkType.rightShoulder];
    final lHip = map[PoseLandmarkType.leftHip];
    final rHip = map[PoseLandmarkType.rightHip];
    final lWrist = map[PoseLandmarkType.leftWrist];
    final rWrist = map[PoseLandmarkType.rightWrist];
    
    if (lShoulder == null || rShoulder == null || 
        lHip == null || rHip == null || 
        lWrist == null || rWrist == null) {
      _feedback = "Body not in frame";
      return;
    }
    
    _smoothedCurlProgress = 0;
    _curlProgress = 0;
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
    
    final lShoulder = map[PoseLandmarkType.leftShoulder];
    final rShoulder = map[PoseLandmarkType.rightShoulder];
    final lHip = map[PoseLandmarkType.leftHip];
    final rHip = map[PoseLandmarkType.rightHip];
    final lWrist = map[PoseLandmarkType.leftWrist];
    final rWrist = map[PoseLandmarkType.rightWrist];
    
    if (lShoulder == null || rShoulder == null || 
        lHip == null || rHip == null || 
        lWrist == null || rWrist == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    // Calculate Y positions
    double shoulderY = (lShoulder.y + rShoulder.y) / 2;
    double hipY = (lHip.y + rHip.y) / 2;
    double wristY = (lWrist.y + rWrist.y) / 2;
    
    // Total range from shoulder to hip (in screen coords, hip Y > shoulder Y)
    double totalRange = hipY - shoulderY;
    
    // How far wrist is from shoulder
    double wristFromShoulder = wristY - shoulderY;
    
    // Calculate progress: 0% = at hip, 100% = at shoulder
    double rawCurlProgress = 0;
    if (totalRange > 0.01) {
      rawCurlProgress = ((totalRange - wristFromShoulder) / totalRange) * 100;
    }
    
    // Smooth it
    _smoothedCurlProgress = (_smoothingFactor * rawCurlProgress) + ((1 - _smoothingFactor) * _smoothedCurlProgress);
    _curlProgress = _smoothedCurlProgress.clamp(0, 100);
    
    // Check triggers
    bool isDown = _curlProgress >= 70; // Wrist 70% of way to shoulder = curl complete
    bool isReset = _curlProgress <= 30; // Wrist dropped back below 30% = arm down
    
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
    _smoothedCurlProgress = 0;
    _curlProgress = 0;
  }
}

