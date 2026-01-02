import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_rules.dart';

/// Rep state using HYSTERESIS (Google's recommendation)
/// State only changes when crossing specific thresholds
enum RepState {
  up,      // At top position, waiting to go down
  goingDown, // Descending
  down,    // Hit bottom threshold
  goingUp,  // Ascending back to top
}

/// Pro-level rep counter with:
/// 1. EMA smoothing (kills jitter)
/// 2. Hysteresis state machine (prevents double counting)
/// 3. Partial rep detection ("Go deeper!")
/// 4. Form coaching (back straight, etc.)
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
  
  RepCounter(this.rule) {
    _calculateThresholds();
  }
  
  void _calculateThresholds() {
    // Hysteresis: Create a "dead zone" between up and down
    // Down threshold: 10° past the contracted angle (must go deeper)
    // Up threshold: 10° before the extended angle (must fully extend)
    
    final range = rule.extendedAngle - rule.contractedAngle;
    final buffer = range * 0.15; // 15% buffer zone
    
    _downThreshold = rule.contractedAngle + buffer;
    _upThreshold = rule.extendedAngle - buffer;
    
    print('📐 Thresholds: DOWN < ${_downThreshold.toStringAsFixed(0)}° | UP > ${_upThreshold.toStringAsFixed(0)}°');
  }
  
  // Getters
  int get repCount => _repCount;
  double get currentAngle => _currentAngle;
  double get formScore => _formScore;
  String get feedback => _feedback;
  String get state => _state.name;
  bool get isCalibrating => _isCalibrating;
  RepState get repState => _state;

  /// GAMING: Get charge progress (0.0 to 1.0) - how far into the rep descent
  /// Returns 1.0 when at full depth, 0.0 when at top
  double get chargeProgress {
    if (_state == RepState.up) return 0.0;

    // Calculate progress from top to bottom
    final range = _upThreshold - _downThreshold;
    if (range <= 0) return 0.0;

    // How far from top threshold?
    final progress = (_upThreshold - _currentAngle) / range;
    return progress.clamp(0.0, 1.0);
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
        // Update existing with EMA
        _smoothedLandmarks[lm.type]!.update(lm.x, lm.y, _emaAlpha);
      } else {
        // First frame - initialize
        _smoothedLandmarks[lm.type] = _SmoothedPoint(lm.x, lm.y);
      }
    }
  }
  
  /// Hysteresis state machine - prevents double counting
  bool _updateState() {
    switch (_state) {
      case RepState.up:
        // At top - waiting to start going down
        if (_currentAngle < _upThreshold) {
          _state = RepState.goingDown;
          _repStartTime = DateTime.now();
          _lowestAngleThisRep = _currentAngle;
        }
        break;
        
      case RepState.goingDown:
        // Check if hit the DOWN threshold
        if (_currentAngle <= _downThreshold) {
          _state = RepState.down;
          
          // If calibrating, save this depth
          if (_isCalibrating) {
            _calibratedDepth = _lowestAngleThisRep;
            _downThreshold = _calibratedDepth! * 1.1; // 10% buffer
            _isCalibrating = false;
            _feedback = "Calibrated! Depth: ${_calibratedDepth!.toStringAsFixed(0)}°";
          }
          
          // Count rep on the way DOWN if configured
          if (rule.countOnContraction) {
            return _countRep();
          }
        }
        // Check if reversed early (PARTIAL REP!)
        else if (_currentAngle > _lowestAngleThisRep + 20) {
          // Started going back up without hitting depth
          _state = RepState.goingUp;
          _partialRepWarning = true;
          _feedback = "Go deeper!";
        }
        break;
        
      case RepState.down:
        // At bottom - waiting to come back up
        if (_currentAngle > _downThreshold + 15) {
          _state = RepState.goingUp;
          _highestAngleThisRep = _currentAngle;
        }
        break;
        
      case RepState.goingUp:
        // Check if hit the UP threshold (fully extended)
        if (_currentAngle >= _upThreshold) {
          _state = RepState.up;
          
          // Count rep on the way UP if configured
          if (!rule.countOnContraction && !_partialRepWarning) {
            return _countRep();
          }
          
          // Reset for next rep
          _resetRepTracking();
        }
        break;
    }
    
    return false;
  }
  
  bool _countRep() {
    _repCount++;
    _calculateFormScore();
    _lastRepTime = DateTime.now();
    
    // Check rep tempo
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
    // Score based on depth achieved
    final targetDepth = _calibratedDepth ?? rule.contractedAngle;
    final achieved = _lowestAngleThisRep;
    
    if (achieved <= targetDepth) {
      _formScore = 100;
    } else {
      // Lose points for not hitting depth
      final diff = achieved - targetDepth;
      _formScore = max(50, 100 - (diff * 2));
    }
  }
  
  /// Check form issues (back straight, knees, etc.)
  void _checkForm(List<PoseLandmark> landmarks) {
    // Only check during movement
    if (_state == RepState.up) return;
    
    final landmarkMap = {for (var lm in landmarks) lm.type: lm};
    
    // Check shoulder tilt (back straight)
    final leftShoulder = landmarkMap[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarkMap[PoseLandmarkType.rightShoulder];
    
    if (leftShoulder != null && rightShoulder != null) {
      final shoulderTilt = (leftShoulder.y - rightShoulder.y).abs();
      final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
      final tiltRatio = shoulderTilt / (shoulderWidth + 0.001);
      
      if (tiltRatio > 0.3) { // More than ~17 degrees of tilt
        _feedback = "Keep shoulders level!";
        _formScore = min(_formScore, 70);
      }
    }
    
    // For squats: check knee cave
    if (rule.id == 'air_squats' || rule.id == 'squats') {
      final leftKnee = landmarkMap[PoseLandmarkType.leftKnee];
      final rightKnee = landmarkMap[PoseLandmarkType.rightKnee];
      final leftAnkle = landmarkMap[PoseLandmarkType.leftAnkle];
      final rightAnkle = landmarkMap[PoseLandmarkType.rightAnkle];
      
      if (leftKnee != null && rightKnee != null && 
          leftAnkle != null && rightAnkle != null) {
        final kneeWidth = (leftKnee.x - rightKnee.x).abs();
        final ankleWidth = (leftAnkle.x - rightAnkle.x).abs();
        
        if (kneeWidth < ankleWidth * 0.8 && _state == RepState.down) {
          _feedback = "Knees out!";
          _formScore = min(_formScore, 75);
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
    
    final cosAngle = dot / (magBA * magBC + 0.0001);
    final angle = acos(cosAngle.clamp(-1.0, 1.0));
    
    return angle * 180 / pi;
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
    _smoothedLandmarks.clear();
  }
}

/// EMA-smoothed point for landmark coordinates
class _SmoothedPoint {
  double x;
  double y;
  
  _SmoothedPoint(this.x, this.y);
  
  void update(double newX, double newY, double alpha) {
    // EMA formula: smoothed = alpha * new + (1 - alpha) * old
    x = alpha * newX + (1 - alpha) * x;
    y = alpha * newY + (1 - alpha) * y;
  }
}
