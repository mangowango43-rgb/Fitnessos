import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';

/// Service for detecting human poses using Google ML Kit
/// Processes camera frames and returns skeleton landmarks
class PoseDetectorService {
  late PoseDetector _poseDetector;
  bool _isProcessing = false;

  PoseDetectorService() {
    // Initialize with accurate mode for best tracking
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream, // Optimized for video streams
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
        return null;
      }

      // Detect pose
      final poses = await _poseDetector.processImage(inputImage);
      
      _isProcessing = false;

      // Return landmarks from first detected pose
      if (poses.isNotEmpty) {
        return poses.first.landmarks.values.toList();
      }

      return null;
    } catch (e) {
      _isProcessing = false;
      return null;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit processing
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Build image bytes from planes
      final allBytes = BytesBuilder();
      for (final Plane plane in image.planes) {
        allBytes.add(plane.bytes);
      }
      final bytes = allBytes.toBytes();

      // Get image size
      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      // Get rotation (most phones need 90° rotation)
      const InputImageRotation imageRotation = InputImageRotation.rotation90deg;

      // Get format
      const InputImageFormat inputImageFormat = InputImageFormat.yuv_420_888;

      // Build metadata
      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      // Create InputImage
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    _poseDetector.close();
  }
}
