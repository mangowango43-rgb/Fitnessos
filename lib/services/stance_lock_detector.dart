import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

/// TACTICAL STANCE LOCK SYSTEM
/// 4-Stage state machine for precision rep detection
enum TacticalState {
  idle,      // IDLE: Waiting for stance lock (feet still for 1s)
  locked,    // STANCE LOCKED: Ready to engage
  engaged,   // ENGAGED: Movement detected + consistent velocity
  peak,      // PEAK: Target depth reached
  validated, // VALIDATED: Rep completed, returning to start
}

class StanceLockDetector {
  TacticalState _state = TacticalState.idle;

  // Stance lock detection
  final Map<PoseLandmarkType, _LandmarkHistory> _landmarkHistory = {};
  DateTime? _stanceLockStartTime;
  static const Duration _lockDuration = Duration(milliseconds: 1000);

  // Movement detection
  bool _movementDetected = false;
  double _velocityThreshold = 0.02; // meters per frame

  // Current state
  int _repCount = 0;

  // Getters
  TacticalState get state => _state;
  int get repCount => _repCount;
  String get stateDescription => _getStateDescription();
  bool get isLocked => _state == TacticalState.locked ||
                       _state == TacticalState.engaged ||
                       _state == TacticalState.peak;

  /// Process landmarks and update state machine
  void processPose(List<PoseLandmark> landmarks) {
    switch (_state) {
      case TacticalState.idle:
        _checkForStanceLock(landmarks);
        break;

      case TacticalState.locked:
        _checkForEngagement(landmarks);
        break;

      case TacticalState.engaged:
        // Handled by rep counter - transition to peak
        break;

      case TacticalState.peak:
        // Handled by rep counter - transition to validated
        break;

      case TacticalState.validated:
        _repCount++;
        _state = TacticalState.locked; // Ready for next rep
        break;
    }
  }

  /// IDLE → LOCKED: Check if feet are still for 1s
  void _checkForStanceLock(List<PoseLandmark> landmarks) {
    // Track ankle positions (feet stability)
    final leftAnkle = landmarks.firstWhere(
      (lm) => lm.type == PoseLandmarkType.leftAnkle,
      orElse: () => throw Exception('No left ankle'),
    );
    final rightAnkle = landmarks.firstWhere(
      (lm) => lm.type == PoseLandmarkType.rightAnkle,
      orElse: () => throw Exception('No right ankle'),
    );

    // Store history
    _updateHistory(PoseLandmarkType.leftAnkle, leftAnkle);
    _updateHistory(PoseLandmarkType.rightAnkle, rightAnkle);

    // Check if ankles have been stable
    final leftStable = _isLandmarkStable(PoseLandmarkType.leftAnkle);
    final rightStable = _isLandmarkStable(PoseLandmarkType.rightAnkle);

    if (leftStable && rightStable) {
      // Start lock timer if not already started
      _stanceLockStartTime ??= DateTime.now();

      // Check if locked long enough
      final lockDuration = DateTime.now().difference(_stanceLockStartTime!);
      if (lockDuration >= _lockDuration) {
        _state = TacticalState.locked;
        print('🎯 STANCE LOCKED');
      }
    } else {
      // Reset lock timer if movement detected
      _stanceLockStartTime = null;
    }
  }

  /// LOCKED → ENGAGED: Check for consistent movement
  void _checkForEngagement(List<PoseLandmark> landmarks) {
    // Check for significant joint movement
    for (final landmark in landmarks) {
      _updateHistory(landmark.type, landmark);

      final velocity = _getLandmarkVelocity(landmark.type);
      if (velocity > _velocityThreshold) {
        _movementDetected = true;
      }
    }

    if (_movementDetected) {
      _state = TacticalState.engaged;
      print('🎯 TARGET ENGAGED');
      _movementDetected = false; // Reset for next time
    }
  }

  /// Mark peak reached (called externally by rep counter)
  void markPeak() {
    if (_state == TacticalState.engaged) {
      _state = TacticalState.peak;
      print('🎯 PEAK REACHED');
    }
  }

  /// Mark rep validated (called externally by rep counter)
  void markValidated() {
    if (_state == TacticalState.peak) {
      _state = TacticalState.validated;
      print('🎯 REP VALIDATED');
    }
  }

  /// Update landmark history
  void _updateHistory(PoseLandmarkType type, PoseLandmark landmark) {
    if (!_landmarkHistory.containsKey(type)) {
      _landmarkHistory[type] = _LandmarkHistory();
    }
    _landmarkHistory[type]!.add(landmark.x, landmark.y, landmark.z);
  }

  /// Check if landmark has been stable for lock duration
  bool _isLandmarkStable(PoseLandmarkType type) {
    if (!_landmarkHistory.containsKey(type)) return false;

    final history = _landmarkHistory[type]!;
    if (history.positions.length < 30) return false; // Need ~1s of data @ 30fps

    // Check if max movement in last second < threshold
    final maxMovement = history.getMaxMovement();
    return maxMovement < 0.05; // 5cm movement threshold
  }

  /// Get velocity of landmark
  double _getLandmarkVelocity(PoseLandmarkType type) {
    if (!_landmarkHistory.containsKey(type)) return 0.0;

    final history = _landmarkHistory[type]!;
    if (history.positions.length < 2) return 0.0;

    return history.getVelocity();
  }

  /// Get tactical state description
  String _getStateDescription() {
    switch (_state) {
      case TacticalState.idle:
        return 'AWAITING STANCE LOCK';
      case TacticalState.locked:
        return 'LOCK-ON CONFIRMED';
      case TacticalState.engaged:
        return 'TARGET ENGAGED';
      case TacticalState.peak:
        return 'DEPTH ACHIEVED';
      case TacticalState.validated:
        return 'REP VALIDATED';
    }
  }

  /// Reset detector
  void reset() {
    _state = TacticalState.idle;
    _landmarkHistory.clear();
    _stanceLockStartTime = null;
    _movementDetected = false;
    _repCount = 0;
  }
}

/// Track recent positions of a landmark
class _LandmarkHistory {
  final List<_Position> positions = [];
  static const int maxHistory = 30; // 1 second @ 30fps

  void add(double x, double y, double z) {
    positions.add(_Position(x, y, z, DateTime.now()));
    if (positions.length > maxHistory) {
      positions.removeAt(0);
    }
  }

  double getMaxMovement() {
    if (positions.length < 2) return 0.0;

    double maxDist = 0.0;
    for (int i = 1; i < positions.length; i++) {
      final dist = positions[i].distanceTo(positions[i - 1]);
      if (dist > maxDist) maxDist = dist;
    }
    return maxDist;
  }

  double getVelocity() {
    if (positions.length < 2) return 0.0;

    final current = positions.last;
    final previous = positions[positions.length - 2];

    final distance = current.distanceTo(previous);
    final timeDelta = current.timestamp.difference(previous.timestamp).inMicroseconds / 1000000.0;

    return distance / timeDelta;
  }
}

class _Position {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  _Position(this.x, this.y, this.z, this.timestamp);

  double distanceTo(_Position other) {
    return math.sqrt(
      math.pow(x - other.x, 2) +
      math.pow(y - other.y, 2) +
      math.pow(z - other.z, 2),
    );
  }
}
