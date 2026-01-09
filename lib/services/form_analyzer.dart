import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Form issue detected during exercise
class FormIssue {
  final String type;
  final String message;
  final double severity;
  final double penalty;

  const FormIssue({
    required this.type,
    required this.message,
    required this.severity,
    required this.penalty,
  });

  static const none = FormIssue(type: 'none', message: '', severity: 0, penalty: 0);
}

/// Form Analyzer - Exercise-specific form checks
class FormAnalyzer {
  
  static FormIssue analyze({
    required String formCheckType,
    required Map<PoseLandmarkType, PoseLandmark> landmarks,
    required String exerciseId,
  }) {
    switch (formCheckType) {
      case 'hip_sag':
        return _checkHipSag(landmarks);
      case 'back_rounding':
        return _checkBackRounding(landmarks);
      case 'knee_cave':
        return _checkKneeCave(landmarks);
      case 'elbow_drift':
        return _checkElbowDrift(landmarks);
      case 'elbow_tuck':
        return _checkElbowTuck(landmarks);
      case 'rib_flare':
        return _checkRibFlare(landmarks);
      case 'forward_lean':
        return _checkForwardLean(landmarks);
      case 'body_swing':
        return _checkBodySwing(landmarks);
      case 'glute_lockout':
        return _checkGluteLockout(landmarks);
      case 'none':
      default:
        return FormIssue.none;
    }
  }

  /// HIP SAG (Push-ups, Planks) - S-H-A should be straight
  static FormIssue _checkHipSag(Map<PoseLandmarkType, PoseLandmark> lm) {
    final shoulder = lm[PoseLandmarkType.rightShoulder];
    final hip = lm[PoseLandmarkType.rightHip];
    final ankle = lm[PoseLandmarkType.rightAnkle];

    if (shoulder == null || hip == null || ankle == null) return FormIssue.none;

    final angle = _calculateAngle(shoulder, hip, ankle);

    if (angle < 160) {
      return FormIssue(
        type: 'hip_sag',
        message: 'Hips sagging!',
        severity: (160 - angle) / 30,
        penalty: 25,
      );
    }
    return FormIssue.none;
  }

  /// BACK ROUNDING (Deadlifts, Rows)
  static FormIssue _checkBackRounding(Map<PoseLandmarkType, PoseLandmark> lm) {
    final shoulder = lm[PoseLandmarkType.rightShoulder];
    final hip = lm[PoseLandmarkType.rightHip];
    final knee = lm[PoseLandmarkType.rightKnee];

    if (shoulder == null || hip == null || knee == null) return FormIssue.none;

    final angle = _calculateAngle(shoulder, hip, knee);

    if (angle < 145) {
      return FormIssue(
        type: 'back_rounding',
        message: 'Back flat!',
        severity: (145 - angle) / 30,
        penalty: 30,
      );
    }
    return FormIssue.none;
  }

  /// KNEE CAVE (Squats, Lunges)
  static FormIssue _checkKneeCave(Map<PoseLandmarkType, PoseLandmark> lm) {
    final leftKnee = lm[PoseLandmarkType.leftKnee];
    final rightKnee = lm[PoseLandmarkType.rightKnee];
    final leftAnkle = lm[PoseLandmarkType.leftAnkle];
    final rightAnkle = lm[PoseLandmarkType.rightAnkle];

    if (leftKnee == null || rightKnee == null ||
        leftAnkle == null || rightAnkle == null) return FormIssue.none;

    final kneeWidth = (leftKnee.x - rightKnee.x).abs();
    final ankleWidth = (leftAnkle.x - rightAnkle.x).abs();

    if (kneeWidth < ankleWidth * 0.85) {
      return FormIssue(
        type: 'knee_cave',
        message: 'Knees out!',
        severity: 0.6,
        penalty: 20,
      );
    }
    return FormIssue.none;
  }

  /// ELBOW DRIFT (Curls)
  static FormIssue _checkElbowDrift(Map<PoseLandmarkType, PoseLandmark> lm) {
    final shoulder = lm[PoseLandmarkType.rightShoulder];
    final elbow = lm[PoseLandmarkType.rightElbow];
    final hip = lm[PoseLandmarkType.rightHip];

    if (shoulder == null || elbow == null || hip == null) return FormIssue.none;

    final elbowToHipDist = (elbow.x - hip.x).abs();
    final shoulderToHipDist = (shoulder.x - hip.x).abs();

    if (elbowToHipDist > shoulderToHipDist * 0.4) {
      return FormIssue(
        type: 'elbow_drift',
        message: 'Elbows pinned!',
        severity: 0.5,
        penalty: 15,
      );
    }
    return FormIssue.none;
  }

  /// ELBOW TUCK (Bench, Triceps)
  static FormIssue _checkElbowTuck(Map<PoseLandmarkType, PoseLandmark> lm) {
    final leftElbow = lm[PoseLandmarkType.leftElbow];
    final rightElbow = lm[PoseLandmarkType.rightElbow];
    final leftShoulder = lm[PoseLandmarkType.leftShoulder];
    final rightShoulder = lm[PoseLandmarkType.rightShoulder];

    if (leftElbow == null || rightElbow == null ||
        leftShoulder == null || rightShoulder == null) return FormIssue.none;

    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
    final elbowWidth = (leftElbow.x - rightElbow.x).abs();

    if (elbowWidth > shoulderWidth * 1.3) {
      return FormIssue(
        type: 'elbow_flare',
        message: 'Elbows in!',
        severity: 0.5,
        penalty: 15,
      );
    }
    return FormIssue.none;
  }

  /// RIB FLARE (Overhead Press)
  static FormIssue _checkRibFlare(Map<PoseLandmarkType, PoseLandmark> lm) {
    final shoulder = lm[PoseLandmarkType.rightShoulder];
    final hip = lm[PoseLandmarkType.rightHip];
    final knee = lm[PoseLandmarkType.rightKnee];

    if (shoulder == null || hip == null || knee == null) return FormIssue.none;

    final torsoAngle = _calculateAngle(shoulder, hip, knee);

    if (torsoAngle > 195) {
      return FormIssue(
        type: 'rib_flare',
        message: 'Ribs down!',
        severity: (torsoAngle - 195) / 20,
        penalty: 15,
      );
    }
    return FormIssue.none;
  }

  /// FORWARD LEAN (Squats)
  static FormIssue _checkForwardLean(Map<PoseLandmarkType, PoseLandmark> lm) {
    final shoulder = lm[PoseLandmarkType.rightShoulder];
    final hip = lm[PoseLandmarkType.rightHip];

    if (shoulder == null || hip == null) return FormIssue.none;

    final verticalDiff = shoulder.y - hip.y;
    final horizontalDiff = (shoulder.x - hip.x).abs();

    if (horizontalDiff > verticalDiff.abs() * 0.5) {
      return FormIssue(
        type: 'forward_lean',
        message: 'Chest up!',
        severity: 0.5,
        penalty: 15,
      );
    }
    return FormIssue.none;
  }

  /// BODY SWING (Curls, Pull-ups)
  static FormIssue _checkBodySwing(Map<PoseLandmarkType, PoseLandmark> lm) {
    final hip = lm[PoseLandmarkType.rightHip];
    final ankle = lm[PoseLandmarkType.rightAnkle];

    if (hip == null || ankle == null) return FormIssue.none;

    final drift = (hip.x - ankle.x).abs();
    final hipHeight = (hip.y - ankle.y).abs();

    if (drift > hipHeight * 0.25) {
      return FormIssue(
        type: 'body_swing',
        message: 'No swinging!',
        severity: 0.5,
        penalty: 15,
      );
    }
    return FormIssue.none;
  }

  /// GLUTE LOCKOUT (Hip Thrust, Bridges)
  static FormIssue _checkGluteLockout(Map<PoseLandmarkType, PoseLandmark> lm) {
    final shoulder = lm[PoseLandmarkType.rightShoulder];
    final hip = lm[PoseLandmarkType.rightHip];
    final knee = lm[PoseLandmarkType.rightKnee];

    if (shoulder == null || hip == null || knee == null) return FormIssue.none;

    final angle = _calculateAngle(shoulder, hip, knee);

    if (angle < 165) {
      return FormIssue(
        type: 'incomplete_lockout',
        message: 'Squeeze glutes!',
        severity: (165 - angle) / 25,
        penalty: 15,
      );
    }
    return FormIssue.none;
  }

  static double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
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
}