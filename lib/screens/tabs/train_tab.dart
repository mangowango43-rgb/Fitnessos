import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart';
import '../../services/pose_detector_service.dart';
import '../../widgets/skeleton_painter.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/glow_button.dart';
import '../../models/workout_models.dart';
import '../../providers/workout_provider.dart';

class TrainTab extends ConsumerStatefulWidget {
  const TrainTab({super.key});

  @override
  ConsumerState<TrainTab> createState() => _TrainTabState();
}

class _TrainTabState extends ConsumerState<TrainTab> with TickerProviderStateMixin {
  // Locked workout state
  LockedWorkout? _lockedWorkout;
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  int _targetReps = 0;
  
  // Workout state
  bool _isWorkoutActive = false;
  bool _isRecording = false;
  bool _isResting = false;
  int _repCount = 0;
  int _restTime = 0;
  String? _formFeedback;
  bool _showRepFlash = false;
  bool _screenFlash = false;

  // Camera & AI state
  CameraController? _cameraController;
  List<PoseLandmark>? _landmarks;
  PoseDetectorService? _poseDetectorService;
  bool _isCameraInitialized = false;
  String? _cameraError;

  Timer? _repTimer;
  Timer? _restTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadLockedWorkout();
  }

  @override
  void dispose() {
    _repTimer?.cancel();
    _restTimer?.cancel();
    _pulseController.dispose();
    _cameraController?.dispose();
    _poseDetectorService?.dispose();
    super.dispose();
  }

  void _loadLockedWorkout() {
    final lockedWorkout = ref.read(lockedWorkoutProvider);
    setState(() {
      _lockedWorkout = lockedWorkout;
      if (_lockedWorkout != null && _lockedWorkout!.exercises.isNotEmpty) {
        _currentExerciseIndex = 0;
        _currentSet = 1;
        _targetReps = _lockedWorkout!.exercises.first.reps;
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _cameraError = 'Camera permission denied. Please enable it in settings.';
        });
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No cameras available';
        });
        return;
      }

      // Use FRONT camera for selfie view
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first, // Fallback to first camera
      );

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Initialize pose detector
      _poseDetectorService = PoseDetectorService();

      // Start image stream for pose detection
      _cameraController!.startImageStream((CameraImage image) {
        _processCameraImage(image);
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      setState(() {
        _cameraError = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_poseDetectorService == null) return;

    final landmarks = await _poseDetectorService!.detectPose(image);
    
    if (landmarks != null && mounted) {
      // Debug: Print landmark count to verify detection
      debugPrint('✅ POSE DETECTED: ${landmarks.length} landmarks');
      setState(() {
        _landmarks = landmarks;
      });
    } else if (mounted) {
      // Debug: No pose detected
      debugPrint('❌ NO POSE DETECTED');
    }
  }

  void _startWorkout() {
    if (_lockedWorkout == null) return;
    
    setState(() {
      _isWorkoutActive = true;
      _currentExerciseIndex = 0;
      _repCount = 0;
      _currentSet = 1;
      _isResting = false;
      _targetReps = _lockedWorkout!.exercises.first.reps;
    });
    
    // Initialize camera when workout starts
    _initializeCamera();
    // NO MORE SIMULATION - real rep counting will happen via pose detection in Phase 2
  }

  void _finishSet() {
    if (_lockedWorkout == null) return;
    
    final exercise = _lockedWorkout!.exercises[_currentExerciseIndex];
    _repTimer?.cancel();
    
    setState(() {
      _isResting = true;
      _restTime = 60; // Default rest time, could be customizable
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTime > 0) {
        setState(() => _restTime--);
      } else {
        timer.cancel();
        setState(() {
          _isResting = false;
          _repCount = 0;
          if (_currentSet < exercise.sets) {
            _currentSet++;
            _targetReps = exercise.reps;
          } else if (_currentExerciseIndex < _lockedWorkout!.exercises.length - 1) {
            _currentExerciseIndex++;
            _currentSet = 1;
            _targetReps = _lockedWorkout!.exercises[_currentExerciseIndex].reps;
          } else {
            // Workout complete!
            _endWorkout();
          }
        });
      }
    });
  }

  void _endWorkout() {
    _repTimer?.cancel();
    _restTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _cameraController = null;
    _poseDetectorService?.dispose();
    _poseDetectorService = null;
    
    setState(() {
      _isWorkoutActive = false;
      _isResting = false;
      _repCount = 0;
      _currentSet = 1;
      _currentExerciseIndex = 0;
      _isCameraInitialized = false;
      _landmarks = null;
      _cameraError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWorkoutActive) {
      return _buildStartScreen();
    }

    if (_isResting) {
      return _buildRestScreen();
    }

    return _buildTrainingScreen();
  }

  Widget _buildStartScreen() {
    if (_lockedWorkout == null) {
      // No workout locked - show message
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_open,
                size: 80,
                color: AppColors.white30,
              ),
              const SizedBox(height: 24),
              const Text(
                'NO WORKOUT LOCKED',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Visit the WORKOUTS tab to lock a workout and start training.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.white60,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GlowButton(
                text: 'GO TO WORKOUTS',
                onPressed: () {
                  // Navigate to Workouts tab
                  DefaultTabController.of(context).animateTo(1); // Workouts tab is index 1
                },
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Workout is locked - show workout summary
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(),
            GlassmorphismCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cyberLime.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: AppColors.cyberLime,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'YOUR LOCKED WORKOUT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white60,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lockedWorkout!.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWorkoutInfo(
                        '${_lockedWorkout!.exercises.length}',
                        'EXERCISES',
                      ),
                      const SizedBox(width: 24),
                      _buildWorkoutInfo(
                        '~${_lockedWorkout!.estimatedMinutes}',
                        'MINUTES',
                      ),
                      if (_lockedWorkout!.isCircuit && _lockedWorkout!.rounds != null) ...[
                        const SizedBox(width: 24),
                        _buildWorkoutInfo(
                          '${_lockedWorkout!.rounds}',
                          'ROUNDS',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white5,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.white10,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXERCISES:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white50,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._lockedWorkout!.exercises.take(4).map((ex) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _lockedWorkout!.isCircuit
                                ? '• ${ex.name} - ${ex.timeSeconds}s'
                                : '• ${ex.name} - ${ex.sets}x${ex.reps}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.white70,
                            ),
                          ),
                        )),
                        if (_lockedWorkout!.exercises.length > 4)
                          Text(
                            '+ ${_lockedWorkout!.exercises.length - 4} more...',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.white40,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlowButton(
              text: '⚡ START WORKOUT',
              onPressed: _startWorkout,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              fontSize: 18,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutInfo(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.cyberLime,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.white50,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingScreen() {
    if (_lockedWorkout == null) return _buildStartScreen();
    
    final exercise = _lockedWorkout!.exercises[_currentExerciseIndex];
    final size = MediaQuery.of(context).size;

    // Show error if camera failed
    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.neonCrimson),
              const SizedBox(height: 24),
              Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text('OPEN SETTINGS'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _endWorkout,
                child: const Text('END WORKOUT'),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading while camera initializes
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.cyberLime),
            SizedBox(height: 24),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // 1. CAMERA PREVIEW (Full screen)
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),

        // 2. VIGNETTE OVERLAY (Subtle dark edges - lighter than before)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3), // Lighter vignette (was 0.4)
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. SKELETON OVERLAY (GLOWING CYBER SKELETON!)
        if (_landmarks != null)
          Positioned.fill(
            child: CustomPaint(
              painter: SkeletonPainter(
                landmarks: _landmarks,
                imageSize: Size(
                  _cameraController!.value.previewSize!.height,
                  _cameraController!.value.previewSize!.width,
                ),
                isFrontCamera: true, // Front camera for selfie mode
              ),
            ),
          ),

        // Minimal tracking indicator
        if (_landmarks != null)
          Positioned(
            top: 120,
            left: 16,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.cyberLime.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cyberLime,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyberLime.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.cyberLime,
                size: 20,
              ),
            ),
          ),

        // Screen flash effect
        if (_screenFlash)
          AnimatedOpacity(
            opacity: _screenFlash ? 0.15 : 0,
            duration: const Duration(milliseconds: 150),
            child: Container(color: AppColors.cyberLime),
          ),

        // 4. EXISTING UI ELEMENTS

        // Compact Exercise Info - Top Left
        Positioned(
          top: 40,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.white20,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white50,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SET $_currentSet / ${exercise.sets}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white40,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Close Button - Top Center
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _endWorkout,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white20,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        // Recording Indicator - Top Right
        if (_isRecording)
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.neonCrimson.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.neonCrimson,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'REC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Form Feedback - Top Right Corner
        if (_formFeedback != null)
          Positioned(
            top: 120,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _formFeedback == 'PERFECT FORM'
                      ? AppColors.cyberLime
                      : AppColors.neonCrimson,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_formFeedback == 'PERFECT FORM'
                            ? AppColors.cyberLime
                            : AppColors.neonCrimson)
                        .withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Text(
                _formFeedback!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _formFeedback == 'PERFECT FORM'
                      ? AppColors.cyberLime
                      : AppColors.neonCrimson,
                ),
              ),
            ),
          ),

        // Next Exercises Dots - Top Center
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _lockedWorkout?.exercises.length ?? 0,
              (index) => Container(
                width: index == _currentExerciseIndex ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _currentExerciseIndex
                      ? AppColors.cyberLime
                      : AppColors.white20,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: index == _currentExerciseIndex
                      ? [
                          BoxShadow(
                            color: AppColors.cyberLime.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),

        // Compact Rep Counter - Top Right
        Positioned(
          top: 40,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.cyberLime.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyberLime.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.2);
                    return Transform.scale(
                      scale: scale,
                      child: Text(
                        '$_repCount',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cyberLime,
                          shadows: [
                            Shadow(
                              color: AppColors.cyberLime
                                  .withOpacity(_pulseController.value),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  '/ ${exercise.reps}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white50,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Rep Flash
        if (_showRepFlash)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.2),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: 1 - ((value - 0.5) / 0.7),
                    child: Text(
                      '+1',
                      style: TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cyberLime,
                        shadows: [
                          Shadow(
                            color: AppColors.cyberLime,
                            blurRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Bottom Buttons
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Record Button
              GestureDetector(
                onTap: () => setState(() => _isRecording = !_isRecording),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording
                          ? AppColors.neonCrimson
                          : AppColors.white30,
                      width: 4,
                    ),
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: AppColors.neonCrimson.withOpacity(0.5),
                              blurRadius: 30,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Container(
                      width: _isRecording ? 20 : 50,
                      height: _isRecording ? 20 : 50,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? AppColors.neonCrimson
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(_isRecording ? 4 : 25),
                        border: _isRecording
                            ? null
                            : Border.all(
                                color: Colors.red,
                                width: 4,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Finish Set Button
              GestureDetector(
                onTap: _finishSet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cyberLime,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyberLime.withOpacity(0.6),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const Text(
                    'FINISH SET',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestScreen() {
    if (_lockedWorkout == null) return _buildStartScreen();
    
    final exercise = _lockedWorkout!.exercises[_currentExerciseIndex];
    
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'REST',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.white40,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 48),
            TweenAnimationBuilder<double>(
              key: ValueKey(_restTime),
              tween: Tween(begin: 1.0, end: 1.1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Text(
                    '$_restTime',
                    style: TextStyle(
                      fontSize: 160,
                      fontWeight: FontWeight.w900,
                      color: AppColors.cyberLime,
                      shadows: [
                        Shadow(
                          color: AppColors.cyberLime,
                          blurRadius: 50,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            if (_currentSet < exercise.sets)
              Text(
                'NEXT: SET ${_currentSet + 1}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white80,
                ),
              )
            else if (_lockedWorkout != null && _currentExerciseIndex < _lockedWorkout!.exercises.length - 1)
              Text(
                'NEXT: ${_lockedWorkout!.exercises[_currentExerciseIndex + 1].name}'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white80,
                ),
              )
            else
              const Text(
                'FINAL SET!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white80,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Last set: $_repCount reps',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.white50,
              ),
            ),
            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    _restTimer?.cancel();
                    setState(() {
                      _isResting = false;
                      _repCount = 0;
                    });
                    // NO MORE SIMULATION
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white5,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.white20,
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'SKIP REST',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _endWorkout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.white10,
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'END WORKOUT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white50,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
