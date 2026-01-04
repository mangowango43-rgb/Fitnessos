import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// =============================================================================
/// BASE PATTERN CONTRACT
/// =============================================================================
/// Every pattern file MUST implement these methods.
/// This ensures all patterns talk to the app the same way.
/// =============================================================================

enum RepState { ready, goingDown, down, goingUp, up }

abstract class BasePattern {
  // State
  RepState get state;
  bool get isLocked;
  int get repCount;
  String get feedback;
  double get chargeProgress; // 0.0 to 1.0 for power gauge
  
  // Actions
  void captureBaseline(Map<PoseLandmarkType, PoseLandmark> landmarks);
  bool processFrame(Map<PoseLandmarkType, PoseLandmark> landmarks); // Returns true if rep counted
  void reset();
}

