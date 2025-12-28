import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_rules.dart';

/// Tracks the phase of a rep
enum RepPhase {
  extended, // Arms straight / standing
  contracting, // Going down
  contracted, // At bottom
  extending, // Coming up
}

/// Simple, testable rep counter for one exercise at a time
class RepCounter {
  final ExerciseRule rule;
  
  int _repCount = 0;
  RepPhase _phase = RepPhase.extended;
  double _currentAngle = 0;
  double _minAngleThisRep = 999;
  double _maxAngleThisRep = 0;
  bool _repCounted = false;
  
  // Form tracking
  double _formScore = 0;
  String _feedback = '';
  
  RepCounter(this.rule);
  
  // Getters
  int get repCount => _repCount;
  double get currentAngle => _currentAngle;
  double get formScore => _formScore;
  String get feedback => _feedback;
  RepPhase get phase => _phase;
  
  /// Process a new pose and return true if a rep was just completed
  bool processPose(List<PoseLandmark> landmarks) {
    // Get the landmarks we need
    final landmarkMap = {for (var lm in landmarks) lm.type: lm};
    
    final a = landmarkMap[rule.jointA];
    final b = landmarkMap[rule.jointB];
    final c = landmarkMap[rule.jointC];
    
    if (a == null || b == null || c == null) {
      _feedback = "Can't see you clearly";
      return false;
    }
    
    // Calculate angle at joint B
    _currentAngle = _calculateAngle(a, b, c);
    
    // Track min/max for form scoring
    if (_currentAngle < _minAngleThisRep) _minAngleThisRep = _currentAngle;
    if (_currentAngle > _maxAngleThisRep) _maxAngleThisRep = _currentAngle;
    
    // State machine for rep counting
    bool repCompleted = _updatePhase();
    
    // Update form feedback
    _updateFormFeedback();
    
    return repCompleted;
  }
  
  /// State machine that tracks the rep phases
  bool _updatePhase() {
    final threshold = 15.0; // Degrees of buffer
    
    switch (_phase) {
      case RepPhase.extended:
        // Waiting at top, check if starting to go down
        if (_currentAngle < rule.extendedAngle - threshold) {
          _phase = RepPhase.contracting;
          _repCounted = false;
        }
        break;
        
      case RepPhase.contracting:
        // Going down, check if reached bottom
        if (_currentAngle <= rule.contractedAngle + threshold) {
          _phase = RepPhase.contracted;
          
          // Count rep on the way DOWN if configured
          if (rule.countOnContraction && !_repCounted) {
            _repCount++;
            _repCounted = true;
            _calculateFormScore();
            return true;
          }
        }
        // Check if changed direction (started going back up early)
        else if (_currentAngle > _maxAngleThisRep - threshold && _maxAngleThisRep > rule.contractedAngle + 20) {
          _phase = RepPhase.extending;
        }
        break;
        
      case RepPhase.contracted:
        // At bottom, check if starting to come up
        if (_currentAngle > rule.contractedAngle + threshold) {
          _phase = RepPhase.extending;
        }
        break;
        
      case RepPhase.extending:
        // Coming up, check if reached top
        if (_currentAngle >= rule.extendedAngle - threshold) {
          _phase = RepPhase.extended;
          
          // Count rep on the way UP if configured
          if (!rule.countOnContraction && !_repCounted) {
            _repCount++;
            _repCounted = true;
            _calculateFormScore();
            return true;
          }
          
          // Reset tracking for next rep
          _minAngleThisRep = 999;
          _maxAngleThisRep = 0;
          _repCounted = false;
        }
        break;
    }
    
    return false;
  }
  
  /// Calculate form score based on how deep they went
  void _calculateFormScore() {
    // For exercises that count on contraction, check min angle
    // For exercises that count on extension, check max angle
    
    double targetAngle;
    double actualAngle;
    
    if (rule.countOnContraction) {
      targetAngle = rule.contractedAngle;
      actualAngle = _minAngleThisRep;
    } else {
      targetAngle = rule.extendedAngle;
      actualAngle = _maxAngleThisRep;
    }
    
    // Perfect form if within good range
    if (actualAngle >= rule.goodFormMin && actualAngle <= rule.goodFormMax) {
      _formScore = 100;
    } else {
      // Scale based on how close they got
      double diff = (actualAngle - targetAngle).abs();
      _formScore = max(0, 100 - (diff * 2));
    }
  }
  
  /// Update the feedback string
  void _updateFormFeedback() {
    if (_phase == RepPhase.contracted || _phase == RepPhase.contracting) {
      // Check if they're hitting good depth
      if (_currentAngle <= rule.goodFormMax && _currentAngle >= rule.goodFormMin) {
        _feedback = rule.cueGood;
      } else if (_currentAngle > rule.goodFormMax) {
        _feedback = rule.cueBad;
      }
    } else {
      _feedback = '';
    }
  }
  
  /// Calculate angle between three points (in degrees)
  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    // Vector from B to A
    final baX = a.x - b.x;
    final baY = a.y - b.y;
    
    // Vector from B to C
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;
    
    // Dot product
    final dot = baX * bcX + baY * bcY;
    
    // Magnitudes
    final magBA = sqrt(baX * baX + baY * baY);
    final magBC = sqrt(bcX * bcX + bcY * bcY);
    
    // Angle in radians, then convert to degrees
    final cosAngle = dot / (magBA * magBC + 0.0001); // Avoid div by zero
    final angle = acos(cosAngle.clamp(-1.0, 1.0));
    
    return angle * 180 / pi;
  }
  
  /// Reset the counter
  void reset() {
    _repCount = 0;
    _phase = RepPhase.extended;
    _currentAngle = 0;
    _minAngleThisRep = 999;
    _maxAngleThisRep = 0;
    _repCounted = false;
    _formScore = 0;
    _feedback = '';
  }
}

