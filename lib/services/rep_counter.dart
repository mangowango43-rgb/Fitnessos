import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_rules.dart';

/// Rep state using HYSTERESIS (Google's recommendation)
/// State only changes when crossing specific thresholds
enum RepState {
  up,        // At top position, waiting to go down
  goingDown, // Descending
  down,      // Hit bottom threshold
  goingUp,   // Ascending back to top
}

/// Pro-level rep counter with:
/// 1. EMA smoothing (kills jitter)
/// 2. Hysteresis state machine (prevents double counting)
/// 3. Partial rep detection ("Go deeper!")
/// 4. Form coaching (back straight, etc.)
/// 5. FIXED: chargeProgress works for ALL exercise types
class RepCounter {
  final ExerciseRule rule;
  
  // Core state
  int _repCount = 0;
  RepState _state = RepState.up;
  double _currentAngle = 0;
  
  // EMA smoothed landmarks (Google recommendation: alpha = 0.2)
  final Map<PoseLandmarkType, _SmoothedPoint> _smoothedLandmarks = {};
  static const double _emaAlpha = 0.2;
  
  // Hysteresis thresholds (calculated from rule)
  late double _downThreshold;   // Must go BELOW this to count as "down"
  late double _upThreshold;     // Must go ABOVE this to reset to "up"
  
  // Tracking for form coaching
  double _lowestAngleThisRep = 999;
  double _highestAngleThisRep = 0;
  DateTime? _repStartTime;
  DateTime? _lastRepTime;
  
  // Form feedback
  double _formScore = 100;
  String _feedback = '';
  bool _partialRepWarning = false;
  
  // Calibration (optional)
  double? _calibratedDepth;
  bool _isCalibrating = false;
  
  // Track if this is a "reverse" exercise (angle increases during rep)
  late bool _isReverseExercise;
  late bool _isIsometric;
  
  RepCounter(this.rule) {
    _calculateThresholds();
  }
  
  void _calculateThresholds() {
    // Determine exercise type
    _isIsometric = (rule.extendedAngle - rule.contractedAngle).abs() < 10;
    _isReverseExercise = rule.extendedAngle < rule.contractedAngle;
    
    if (_isIsometric) {
      // Isometric: no real thresholds needed
      _downThreshold = rule.contractedAngle;
      _upThreshold = rule.extendedAngle;
      print('📐 ISOMETRIC exercise: ${rule.name}');
    } else if (_isReverseExercise) {
      // Reverse exercise (glute bridge, hip thrust): angle INCREASES during rep
      final range = rule.contractedAngle - rule.extendedAngle;
      final buffer = range * 0.15;
      
      _downThreshold = rule.contractedAngle - buffer; // Higher angle = "down" (contracted)
      _upThreshold = rule.extendedAngle + buffer;     // Lower angle = "up" (extended)
      
      print('📐 REVERSE Thresholds for ${rule.name}: DOWN > ${_downThreshold.toStringAsFixed(0)}° | UP < ${_upThreshold.toStringAsFixed(0)}°');
    } else {
      // Normal exercise (push-ups, squats): angle DECREASES during rep
      final range = rule.extendedAngle - rule.contractedAngle;
      final buffer = range * 0.15;
      
      _downThreshold = rule.contractedAngle + buffer;
      _upThreshold = rule.extendedAngle - buffer;
      
      print('📐 NORMAL Thresholds for ${rule.name}: DOWN < ${_downThreshold.toStringAsFixed(0)}° | UP > ${_upThreshold.toStringAsFixed(0)}°');
    }
  }
  
  // Getters
  int get repCount => _repCount;
  double get currentAngle => _currentAngle;
  double get formScore => _formScore;
  String get feedback => _feedback;
  String get state => _state.name;
  bool get isCalibrating => _isCalibrating;
  RepState get repState => _state;

  /// GAMING: Get charge progress (0.0 to 1.0) - how far into the rep
  /// FIXED: Now handles ALL exercise types correctly
  double get chargeProgress {
    if (_state == RepState.up) return 0.0;
    
    // Handle isometric exercises (plank, wall sit, etc.)
    if (_isIsometric) {
      return (_state == RepState.down || _state == RepState.goingDown) ? 1.0 : 0.0;
    }
    
    if (_isReverseExercise) {
      // Reverse exercises (glute bridge, hip thrust) - angle goes from LOW to HIGH
      final range = _downThreshold - _upThreshold;
      if (range <= 0) return 0.0;
      final progress = (_currentAngle - _upThreshold) / range;
      return progress.clamp(0.0, 1.0);
    } else {
      // Normal exercises (push-ups, squats) - angle goes from HIGH to LOW
      final range = _upThreshold - _downThreshold;
      if (range <= 0) return 0.0;
      final progress = (_upThreshold - _currentAngle) / range;
      return progress.clamp(0.0, 1.0);
    }
  }
  
  /// Start calibration mode - next rep sets the target depth
  void startCalibration() {
    _isCalibrating = true;
    _calibratedDepth = null;
    _feedback = "Do one perfect rep to calibrate";
  }
  
  /// Process a new pose - returns true if rep completed
  bool processPose(List<PoseLandmark> landmarks) {
    // Step 1: Apply EMA smoothing to landmarks
    _smoothLandmarks(landmarks);
    
    // Step 2: Get smoothed landmarks for angle calculation
    final a = _smoothedLandmarks[rule.jointA];
    final b = _smoothedLandmarks[rule.jointB];
    final c = _smoothedLandmarks[rule.jointC];
    
    if (a == null || b == null || c == null) {
      _feedback = "Get in frame";
      return false;
    }
    
    // Step 3: Calculate angle from smoothed points
    _currentAngle = _calculateAngle(a, b, c);
    
    // Track min/max for this rep
    if (_currentAngle < _lowestAngleThisRep) _lowestAngleThisRep = _currentAngle;
    if (_currentAngle > _highestAngleThisRep) _highestAngleThisRep = _currentAngle;
    
    // Step 4: Run hysteresis state machine
    bool repCompleted = _updateState();
    
    // Step 5: Check form
    _checkForm(landmarks);
    
    return repCompleted;
  }
  
  /// Apply EMA smoothing to all landmarks
  void _smoothLandmarks(List<PoseLandmark> landmarks) {
    for (final lm in landmarks) {
      if (_smoothedLandmarks.containsKey(lm.type)) {
        _smoothedLandmarks[lm.type]!.update(lm.x, lm.y, _emaAlpha);
      } else {
        _smoothedLandmarks[lm.type] = _SmoothedPoint(lm.x, lm.y);
      }
    }
  }
  
  /// Hysteresis state machine - prevents double counting
  /// FIXED: Now handles reverse exercises correctly
  bool _updateState() {
    if (_isIsometric) {
      return _updateStateIsometric();
    } else if (_isReverseExercise) {
      return _updateStateReverse();
    } else {
      return _updateStateNormal();
    }
  }
  
  /// State machine for NORMAL exercises (angle decreases: push-ups, squats)
  bool _updateStateNormal() {
    switch (_state) {
      case RepState.up:
        if (_currentAngle < _upThreshold) {
          _state = RepState.goingDown;
          _repStartTime = DateTime.now();
          _lowestAngleThisRep = _currentAngle;
        }
        break;
        
      case RepState.goingDown:
        if (_currentAngle <= _downThreshold) {
          _state = RepState.down;
          
          if (_isCalibrating) {
            _calibratedDepth = _lowestAngleThisRep;
            _downThreshold = _calibratedDepth! * 1.1;
            _isCalibrating = false;
            _feedback = "Calibrated! Depth: ${_calibratedDepth!.toStringAsFixed(0)}°";
          }
          
          if (rule.countOnContraction) {
            return _countRep();
          }
        } else if (_currentAngle > _lowestAngleThisRep + 20) {
          _state = RepState.goingUp;
          _partialRepWarning = true;
          _feedback = "Go deeper!";
        }
        break;
        
      case RepState.down:
        if (_currentAngle > _downThreshold + 15) {
          _state = RepState.goingUp;
          _highestAngleThisRep = _currentAngle;
        }
        break;
        
      case RepState.goingUp:
        if (_currentAngle >= _upThreshold) {
          _state = RepState.up;
          
          if (!rule.countOnContraction && !_partialRepWarning) {
            return _countRep();
          }
          
          _resetRepTracking();
        }
        break;
    }
    
    return false;
  }
  
  /// State machine for REVERSE exercises (angle increases: glute bridge, hip thrust)
  bool _updateStateReverse() {
    switch (_state) {
      case RepState.up:
        // At starting position (low angle like 120°)
        if (_currentAngle > _upThreshold) {
          _state = RepState.goingDown; // Actually going "up" in terms of body, but angle increasing
          _repStartTime = DateTime.now();
          _highestAngleThisRep = _currentAngle;
        }
        break;
        
      case RepState.goingDown:
        // Moving toward contracted position (high angle like 175°)
        if (_currentAngle >= _downThreshold) {
          _state = RepState.down;
          
          if (rule.countOnContraction) {
            return _countRep();
          }
        } else if (_currentAngle < _highestAngleThisRep - 20) {
          // User reversed early
          _state = RepState.goingUp;
          _partialRepWarning = true;
          _feedback = "Hips higher!";
        }
        break;
        
      case RepState.down:
        // At top of movement (hips high)
        if (_currentAngle < _downThreshold - 15) {
          _state = RepState.goingUp;
          _lowestAngleThisRep = _currentAngle;
        }
        break;
        
      case RepState.goingUp:
        // Returning to start position
        if (_currentAngle <= _upThreshold) {
          _state = RepState.up;
          
          if (!rule.countOnContraction && !_partialRepWarning) {
            return _countRep();
          }
          
          _resetRepTracking();
        }
        break;
    }
    
    return false;
  }
  
  /// State machine for ISOMETRIC exercises (plank, wall sit)
  bool _updateStateIsometric() {
    // For isometric, we just track time in position
    // Could implement hold time tracking here
    final shoulder = _smoothedLandmarks[rule.jointA];
    final hip = _smoothedLandmarks[rule.jointB];
    final ankle = _smoothedLandmarks[rule.jointC];
    
    if (shoulder != null && hip != null && ankle != null) {
      // Check if in proper position
      final inPosition = _currentAngle >= rule.goodFormMin && 
                         _currentAngle <= rule.goodFormMax;
      
      if (inPosition) {
        _state = RepState.down;
        _feedback = rule.cueGood;
      } else {
        _state = RepState.up;
        _feedback = rule.cueBad;
      }
    }
    
    return false; // Isometric doesn't count reps the same way
  }
  
  bool _countRep() {
    _repCount++;
    _calculateFormScore();
    _lastRepTime = DateTime.now();
    
    if (_repStartTime != null) {
      final duration = DateTime.now().difference(_repStartTime!).inMilliseconds;
      if (duration < 500) {
        _feedback = "Slow down! Control it.";
      } else if (duration > 4000) {
        _feedback = "Pick up the pace!";
      } else {
        _feedback = rule.cueGood;
      }
    }
    
    return true;
  }
  
  void _resetRepTracking() {
    _lowestAngleThisRep = 999;
    _highestAngleThisRep = 0;
    _partialRepWarning = false;
    _repStartTime = null;
  }
  
  void _calculateFormScore() {
    if (_isReverseExercise) {
      // For reverse exercises, check highest angle achieved
      final targetDepth = _calibratedDepth ?? rule.contractedAngle;
      final achieved = _highestAngleThisRep;
      
      if (achieved >= targetDepth) {
        _formScore = 100;
      } else {
        final diff = targetDepth - achieved;
        _formScore = max(50, 100 - (diff * 2));
      }
    } else {
      // For normal exercises, check lowest angle achieved
      final targetDepth = _calibratedDepth ?? rule.contractedAngle;
      final achieved = _lowestAngleThisRep;
      
      if (achieved <= targetDepth) {
        _formScore = 100;
      } else {
        final diff = achieved - targetDepth;
        _formScore = max(50, 100 - (diff * 2));
      }
    }
  }
  
  /// ENHANCED: Check form issues with exercise-specific checks
  /// NOW CHECKS FORM CONTINUOUSLY (removed early return on RepState.up)
  void _checkForm(List<PoseLandmark> landmarks) {
    // REMOVED: if (_state == RepState.up) return;
    // Form checking now happens ALWAYS to catch bad form immediately
    
    final landmarkMap = {for (var lm in landmarks) lm.type: lm};
    
    // =====================
    // UNIVERSAL: Shoulder Tilt Check
    // =====================
    final leftShoulder = landmarkMap[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarkMap[PoseLandmarkType.rightShoulder];
    
    if (leftShoulder != null && rightShoulder != null) {
      final shoulderTilt = (leftShoulder.y - rightShoulder.y).abs();
      final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
      final tiltRatio = shoulderTilt / (shoulderWidth + 0.001);
      
      if (tiltRatio > 0.3) {
        _feedback = "Keep shoulders level!";
        _formScore = min(_formScore, 70);
        return;
      }
    }
    
    // =====================
    // PUSH-UPS: Back Sag/Pike Check
    // =====================
    if (rule.id == 'push_ups' || rule.id == 'pushups' || 
        rule.id == 'wide_pushups' || rule.id == 'diamond_pushups' ||
        rule.id == 'wide_push_ups') {
      final shoulder = _smoothedLandmarks[PoseLandmarkType.rightShoulder];
      final hip = _smoothedLandmarks[PoseLandmarkType.rightHip];
      final ankle = _smoothedLandmarks[PoseLandmarkType.rightAnkle];
      
      if (shoulder != null && hip != null && ankle != null) {
        final bodyAngle = _calculateAngle(shoulder, hip, ankle);
        
        if (bodyAngle < 160) {
          _feedback = "Keep hips up! Straight body.";
          _formScore = min(_formScore, 65);
          return;
        }
        if (bodyAngle > 195) {
          _feedback = "Don't pike! Flatten back.";
          _formScore = min(_formScore, 65);
          return;
        }
      }
    }
    
    // =====================
    // SQUATS: Knee Cave & Forward Lean
    // =====================
    if (rule.id == 'air_squats' || rule.id == 'squats' || 
        rule.id == 'squats_bw' || rule.id == 'goblet_squats') {
      final leftKnee = landmarkMap[PoseLandmarkType.leftKnee];
      final rightKnee = landmarkMap[PoseLandmarkType.rightKnee];
      final leftAnkle = landmarkMap[PoseLandmarkType.leftAnkle];
      final rightAnkle = landmarkMap[PoseLandmarkType.rightAnkle];
      
      if (leftKnee != null && rightKnee != null && 
          leftAnkle != null && rightAnkle != null) {
        final kneeWidth = (leftKnee.x - rightKnee.x).abs();
        final ankleWidth = (leftAnkle.x - rightAnkle.x).abs();
        
        if (kneeWidth < ankleWidth * 0.8 && _state == RepState.down) {
          _feedback = "Knees out! Don't cave!";
          _formScore = min(_formScore, 60);
          return;
        }
      }
    }
    
    // =====================
    // LUNGES: Knee Position
    // =====================
    if (rule.id == 'lunges' || rule.id == 'walking_lunges') {
      final knee = landmarkMap[PoseLandmarkType.rightKnee];
      final toe = landmarkMap[PoseLandmarkType.rightFootIndex];
      
      if (knee != null && toe != null && _state == RepState.down) {
        if (knee.x > toe.x + 30) {
          _feedback = "Knee behind toes!";
          _formScore = min(_formScore, 65);
          return;
        }
      }
    }
    
    // =====================
    // GLUTE BRIDGE: Hip Height
    // =====================
    if (rule.id == 'glute_bridge' || rule.id == 'hip_thrust' ||
        rule.id == 'single_leg_glute_bridge') {
      if (_state == RepState.down && _currentAngle < 160) {
        _feedback = "Squeeze glutes! Hips higher!";
        _formScore = min(_formScore, 70);
        return;
      }
    }
    
    // =====================
    // PLANK: Hip Position
    // =====================
    if (rule.id == 'plank' || rule.id == 'plank_hold') {
      final shoulder = _smoothedLandmarks[PoseLandmarkType.rightShoulder];
      final hip = _smoothedLandmarks[PoseLandmarkType.rightHip];
      final ankle = _smoothedLandmarks[PoseLandmarkType.rightAnkle];
      
      if (shoulder != null && hip != null && ankle != null) {
        final bodyAngle = _calculateAngle(shoulder, hip, ankle);
        
        if (bodyAngle < 165) {
          _feedback = "Hips sagging! Tighten core!";
          _formScore = min(_formScore, 60);
          return;
        }
        if (bodyAngle > 190) {
          _feedback = "Hips too high! Flatten out!";
          _formScore = min(_formScore, 60);
          return;
        }
      }
    }
    
    // =====================
    // MOUNTAIN CLIMBERS: Hip Stability
    // =====================
    if (rule.id == 'mountain_climbers') {
      final shoulder = _smoothedLandmarks[PoseLandmarkType.rightShoulder];
      final hip = _smoothedLandmarks[PoseLandmarkType.rightHip];
      
      if (shoulder != null && hip != null) {
        if (hip.y < shoulder.y * 0.7) {
          _feedback = "Keep hips down!";
          _formScore = min(_formScore, 70);
          return;
        }
      }
    }
  }
  
  double _calculateAngle(_SmoothedPoint a, _SmoothedPoint b, _SmoothedPoint c) {
    final baX = a.x - b.x;
    final baY = a.y - b.y;
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;
    
    final dot = baX * bcX + baY * bcY;
    final magBA = sqrt(baX * baX + baY * baY);
    final magBC = sqrt(bcX * bcX + bcY * bcY);
    
    final cosine = dot / (magBA * magBC + 0.000001);
    final angleRad = acos(cosine.clamp(-1.0, 1.0));
    
    return angleRad * 180 / pi;
  }
  
  void reset() {
    _repCount = 0;
    _state = RepState.up;
    _currentAngle = 0;
    _lowestAngleThisRep = 999;
    _highestAngleThisRep = 0;
    _formScore = 100;
    _feedback = '';
    _partialRepWarning = false;
    _repStartTime = null;
    _lastRepTime = null;
  }
}

/// Smoothed landmark point with EMA
class _SmoothedPoint {
  double x;
  double y;
  
  _SmoothedPoint(this.x, this.y);
  
  void update(double newX, double newY, double alpha) {
    x = alpha * newX + (1 - alpha) * x;
    y = alpha * newY + (1 - alpha) * y;
  }
}
