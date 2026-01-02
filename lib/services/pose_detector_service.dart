import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:ui' show Size;
import 'dart:io' show Platform;
import 'dart:math' as math;

/// Service for detecting human poses using Google ML Kit
/// ENHANCED with EMA smoothing and velocity gating for SKELATAL-grade precision
class PoseDetectorService {
  late PoseDetector _poseDetector;
  bool _isProcessing = false;

  // EMA SMOOTHING LAYER (alpha = 0.3 for tactical responsiveness)
  final Map<PoseLandmarkType, _SmoothedLandmark> _smoothedLandmarks = {};
  static const double _emaAlpha = 0.3;

  // VELOCITY GATE (reject noise > 1m/frame @ 30fps)
  static const double _maxVelocityMetersPerFrame = 1.0;
  DateTime? _lastFrameTime;

  PoseDetectorService() {
    // Initialize with stream mode for real-time video
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    );
    _poseDetector = PoseDetector(options: options);
  }

  /// Process a camera frame and return detected pose landmarks
  /// Returns null if no pose detected or if still processing previous frame
  Future<List<PoseLandmark>?> detectPose(CameraImage image) async {
    // Drop frame if still processing previous one (performance optimization)
    if (_isProcessing) {
      return null;
    }

    _isProcessing = true;

    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        print('❌ Failed to convert camera image');
        return null;
      }

      // Detect pose
      final poses = await _poseDetector.processImage(inputImage);

      _isProcessing = false;

      // Return landmarks from first detected pose
      if (poses.isNotEmpty) {
        final rawLandmarks = poses.first.landmarks.values.toList();

        // APPLY SMOOTHING AND VELOCITY GATING
        final smoothedLandmarks = _applySmoothingAndGating(rawLandmarks);

        if (smoothedLandmarks != null) {
          return smoothedLandmarks;
        }
      }

      return null;
    } catch (e) {
      _isProcessing = false;
      print('❌ Error detecting pose: $e');
      return null;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit processing
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Determine rotation based on platform
      // Front camera typically needs 270° on Android, 0° or 90° on iOS
      InputImageRotation imageRotation;
      if (Platform.isAndroid) {
        imageRotation = InputImageRotation.rotation270deg;
      } else {
        imageRotation = InputImageRotation.rotation0deg;
      }

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      // Android uses YUV_420_888, need to convert to NV21
      if (Platform.isAndroid) {
        return _convertYUV420ToInputImage(image, imageSize, imageRotation);
      } else {
        // iOS uses BGRA format
        return _convertBGRAToInputImage(image, imageSize, imageRotation);
      }
    } catch (e) {
      print('❌ Error converting camera image: $e');
      return null;
    }
  }

  /// Convert YUV_420_888 (Android) to NV21 format for ML Kit
  InputImage? _convertYUV420ToInputImage(
    CameraImage image,
    Size imageSize,
    InputImageRotation rotation,
  ) {
    try {
      final int width = image.width;
      final int height = image.height;
      
      final int yRowStride = image.planes[0].bytesPerRow;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      // NV21 format: Y plane followed by interleaved VU
      final int ySize = width * height;
      final int uvSize = width * height ~/ 2;
      final Uint8List nv21 = Uint8List(ySize + uvSize);

      // Copy Y plane
      final Uint8List yPlane = image.planes[0].bytes;
      int yIndex = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          nv21[yIndex++] = yPlane[y * yRowStride + x];
        }
      }

      // Interleave V and U planes (NV21 is VUVU...)
      final Uint8List uPlane = image.planes[1].bytes;
      final Uint8List vPlane = image.planes[2].bytes;
      
      int uvIndex = ySize;
      for (int y = 0; y < height ~/ 2; y++) {
        for (int x = 0; x < width ~/ 2; x++) {
          final int uvOffset = y * uvRowStride + x * uvPixelStride;
          nv21[uvIndex++] = vPlane[uvOffset]; // V first for NV21
          nv21[uvIndex++] = uPlane[uvOffset]; // U second
        }
      }

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      );

      return InputImage.fromBytes(
        bytes: nv21,
        metadata: metadata,
      );
    } catch (e) {
      print('❌ Error converting YUV420: $e');
      return null;
    }
  }

  /// Convert BGRA (iOS) to InputImage
  InputImage? _convertBGRAToInputImage(
    CameraImage image,
    Size imageSize,
    InputImageRotation rotation,
  ) {
    try {
      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: metadata,
      );
    } catch (e) {
      print('❌ Error converting BGRA: $e');
      return null;
    }
  }

  /// TACTICAL SMOOTHING LAYER: EMA + Velocity Gate
  /// Returns null if velocity gate rejects as noise
  List<PoseLandmark>? _applySmoothingAndGating(List<PoseLandmark> rawLandmarks) {
    final now = DateTime.now();
    final double deltaTime = _lastFrameTime != null
        ? now.difference(_lastFrameTime!).inMicroseconds / 1000000.0
        : 0.033; // Assume 30fps if first frame

    _lastFrameTime = now;

    List<PoseLandmark> smoothedLandmarks = [];

    for (final landmark in rawLandmarks) {
      if (_smoothedLandmarks.containsKey(landmark.type)) {
        // VELOCITY GATE: Check if movement is physically possible
        final smoothed = _smoothedLandmarks[landmark.type]!;
        final distance = math.sqrt(
          math.pow(landmark.x - smoothed.x, 2) +
          math.pow(landmark.y - smoothed.y, 2) +
          math.pow(landmark.z - smoothed.z, 2),
        );

        final velocity = distance / deltaTime;

        // REJECT if velocity exceeds 1m/frame (noise spike detected)
        if (velocity > _maxVelocityMetersPerFrame) {
          // Keep previous smoothed value, reject noisy input
          smoothedLandmarks.add(smoothed.toLandmark(landmark.type));
          continue;
        }

        // APPLY EMA SMOOTHING
        smoothed.update(
          landmark.x,
          landmark.y,
          landmark.z,
          landmark.likelihood,
          _emaAlpha,
        );

        smoothedLandmarks.add(smoothed.toLandmark(landmark.type));
      } else {
        // FIRST FRAME: Initialize smoothed landmark
        _smoothedLandmarks[landmark.type] = _SmoothedLandmark(
          x: landmark.x,
          y: landmark.y,
          z: landmark.z,
          likelihood: landmark.likelihood,
        );
        smoothedLandmarks.add(landmark);
      }
    }

    return smoothedLandmarks.isEmpty ? null : smoothedLandmarks;
  }

  /// Clean up resources
  void dispose() {
    _poseDetector.close();
    _smoothedLandmarks.clear();
  }
}

/// EMA-smoothed pose landmark data
class _SmoothedLandmark {
  double x;
  double y;
  double z;
  double likelihood;

  _SmoothedLandmark({
    required this.x,
    required this.y,
    required this.z,
    required this.likelihood,
  });

  /// Update using Exponential Moving Average
  void update(double newX, double newY, double newZ, double newLikelihood, double alpha) {
    // EMA formula: smoothed = alpha * new + (1 - alpha) * old
    x = alpha * newX + (1 - alpha) * x;
    y = alpha * newY + (1 - alpha) * y;
    z = alpha * newZ + (1 - alpha) * z;
    likelihood = alpha * newLikelihood + (1 - alpha) * likelihood;
  }

  /// Convert to PoseLandmark for output
  PoseLandmark toLandmark(PoseLandmarkType type) {
    return PoseLandmark(
      type: type,
      x: x,
      y: y,
      z: z,
      likelihood: likelihood,
    );
  }
}
