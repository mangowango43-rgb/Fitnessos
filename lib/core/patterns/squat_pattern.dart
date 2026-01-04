import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'base_pattern.dart';

/// =============================================================================
/// SQUAT PATTERN - Hip-to-Ankle Distance
/// =============================================================================
/// Used for: squats, lunges, jump_squats, leg_press, sit_ups, burpees, etc.
/// 
/// Logic: Track distance from hip to ankle.
/// Uses hip-to-hip width as a "ruler" to handle distance changes from camera.
/// When you squat down, hip-to-ankle distance SHRINKS relative to hip width.
/// =============================================================================

class SquatPattern implements BasePattern {
  // Config
  final double triggerPercent; // e.g. 0.78 = trigger when distance drops to 78%
  final double resetPercent; // e.g. 0.92 = reset when distance returns to 92%
  final String cueGood;
  final String cueBad;
  
  // State
  RepState _state = RepState.ready;
  bool _baselineCaptured = false;
  int _repCount = 0;
  String _feedback = "";
  
  // Baseline
  double _baselineTarget = 0; // Hip-to-ankle distance at start
  double _baselineRuler = 0; // Hip-to-hip width (doesn't change)
  
  // Current values
  double _currentPercentage = 100;
  double _smoothedPercentage = 100;
  
  // Anti-ghost
  static const double _smoothingFactor = 0.3;
  DateTime? _intentTimer;
  DateTime _lastRepTime = DateTime.now();
  static const int _intentDelayMs = 250;
  static const int _minTimeBetweenRepsMs = 500;
  
  SquatPattern({
    this.triggerPercent = 0.78,
    this.resetPercent = 0.92,
    this.cueGood = "Depth!",
    this.cueBad = "Hit parallel!",
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
    double trigger = triggerPercent * 100;
    double progress = (100 - _currentPercentage) / (100 - trigger);
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
    final lHip = map[PoseLandmarkType.leftHip];
    final rHip = map[PoseLandmarkType.rightHip];
    final lAnkle = map[PoseLandmarkType.leftAnkle];
    
    if (lHip == null || lAnkle == null) {
      _feedback = "Body not in frame";
      return;
    }
    
    // Target: hip to ankle distance
    _baselineTarget = _dist3D(lHip, lAnkle);
    
    // Ruler: hip to hip width (doesn't change when squatting)
    if (rHip != null && lHip.likelihood > 0.5 && rHip.likelihood > 0.5) {
      _baselineRuler = _dist3D(lHip, rHip);
    } else {
      _baselineRuler = _baselineTarget;
    }
    
    if (_baselineRuler < 0.01 || _baselineTarget < 0.01) {
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
    
    final lHip = map[PoseLandmarkType.leftHip];
    final rHip = map[PoseLandmarkType.rightHip];
    final lAnkle = map[PoseLandmarkType.leftAnkle];
    
    if (lHip == null || lAnkle == null) {
      _feedback = "Stay in frame";
      return false;
    }
    
    // Calculate current distance
    double currentTarget = _dist3D(lHip, lAnkle);
    
    // Current ruler (hip-to-hip)
    double currentRuler = _baselineRuler;
    if (rHip != null && lHip.likelihood > 0.5 && rHip.likelihood > 0.5) {
      currentRuler = _dist3D(lHip, rHip);
    }
    if (currentRuler < 0.01) currentRuler = _baselineRuler;
    
    // Calculate percentage using ratio
    double baselineRatio = _baselineTarget / _baselineRuler;
    double currentRatio = currentTarget / currentRuler;
    double rawPercentage = (currentRatio / baselineRatio) * 100;
    
    // Smooth it
    _smoothedPercentage = (_smoothingFactor * rawPercentage) + ((1 - _smoothingFactor) * _smoothedPercentage);
    _currentPercentage = _smoothedPercentage.clamp(0, 150);
    
    // Check triggers
    bool isDown = _currentPercentage <= (triggerPercent * 100);
    bool isReset = _currentPercentage >= (resetPercent * 100);
    
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
  }
}

