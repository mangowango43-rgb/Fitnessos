import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

/// TACTICAL CALIBRATION SYSTEM
/// Uses device gyroscope to auto-adjust joint angle calculations
/// based on camera tilt/pitch for precision tracking
class GyroCalibrationService {
  // Current device orientation (radians)
  double _pitch = 0.0; // Forward/backward tilt
  double _roll = 0.0;  // Left/right tilt
  double _yaw = 0.0;   // Rotation around vertical axis

  // EMA smoothing for gyro data (alpha = 0.1 for stability)
  static const double _emaAlpha = 0.1;

  StreamSubscription? _gyroSubscription;
  StreamSubscription? _accelSubscription;

  // Calibration state
  bool _isCalibrated = false;
  double _baselinePitch = 0.0;
  double _baselineRoll = 0.0;

  /// Initialize and start listening to gyroscope
  void init() {
    // Listen to accelerometer for pitch and roll
    _accelSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 33), // ~30fps
    ).listen((AccelerometerEvent event) {
      // Calculate pitch and roll from accelerometer
      final double newPitch = math.atan2(event.y, math.sqrt(event.x * event.x + event.z * event.z));
      final double newRoll = math.atan2(event.x, math.sqrt(event.y * event.y + event.z * event.z));

      // Apply EMA smoothing
      _pitch = _emaAlpha * newPitch + (1 - _emaAlpha) * _pitch;
      _roll = _emaAlpha * newRoll + (1 - _emaAlpha) * _roll;
    });

    // Listen to gyroscope for yaw
    _gyroSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 33),
    ).listen((GyroscopeEvent event) {
      // Integrate angular velocity for yaw
      _yaw += event.z * 0.033; // Approximate integration

      // Keep yaw in [-π, π]
      if (_yaw > math.pi) _yaw -= 2 * math.pi;
      if (_yaw < -math.pi) _yaw += 2 * math.pi;
    });

    print('🎯 GYRO CALIBRATION: ONLINE');
  }

  /// LOCK-ON: Calibrate baseline orientation
  /// Call this when user is in starting position
  void calibrateBaseline() {
    _baselinePitch = _pitch;
    _baselineRoll = _roll;
    _isCalibrated = true;
    print('🎯 AXIS ALIGNED: Baseline locked at pitch=${(_pitch * 180 / math.pi).toStringAsFixed(1)}°');
  }

  /// Get calibrated angle adjustment
  /// Returns angle correction factor based on current device tilt
  double getAngleCorrection() {
    if (!_isCalibrated) return 0.0;

    // Calculate deviation from baseline
    final double pitchDeviation = _pitch - _baselinePitch;
    final double rollDeviation = _roll - _baselineRoll;

    // Convert to angle correction (degrees)
    final double correction = math.sqrt(
      pitchDeviation * pitchDeviation + rollDeviation * rollDeviation,
    ) * 180 / math.pi;

    return correction;
  }

  /// Get current device pitch in degrees
  double get pitchDegrees => _pitch * 180 / math.pi;

  /// Get current device roll in degrees
  double get rollDegrees => _roll * 180 / math.pi;

  /// Get current device yaw in degrees
  double get yawDegrees => _yaw * 180 / math.pi;

  /// Check if device is stable (for stance lock detection)
  /// Returns true if device hasn't moved significantly in last reading
  bool get isDeviceStable {
    final pitchVelocity = (_pitch - _baselinePitch).abs();
    final rollVelocity = (_roll - _baselineRoll).abs();

    // Consider stable if movement < 0.05 radians (~3 degrees)
    return pitchVelocity < 0.05 && rollVelocity < 0.05;
  }

  /// Reset calibration
  void resetCalibration() {
    _isCalibrated = false;
    _baselinePitch = 0.0;
    _baselineRoll = 0.0;
    print('🎯 CALIBRATION RESET');
  }

  /// Clean up
  void dispose() {
    _gyroSubscription?.cancel();
    _accelSubscription?.cancel();
    print('🎯 GYRO CALIBRATION: OFFLINE');
  }
}
