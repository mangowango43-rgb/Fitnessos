import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../utils/app_colors.dart';
import '../../utils/haptic_helper.dart';
import '../../services/pose_detector_service.dart';
import '../../widgets/skeleton_painter.dart';
import '../../widgets/power_gauge.dart';
import '../../widgets/shatter_animation.dart';
import '../../widgets/phone_position_guide.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/glow_button.dart';
import '../../models/workout_models.dart';
import '../../providers/workout_provider.dart';

// Import the rep counting system
import '../../services/rep_counter.dart';

class TrainTab extends ConsumerStatefulWidget {
  const TrainTab({super.key});

  @override
  ConsumerState<TrainTab> createState() => _TrainTabState();
}

class _TrainTabState extends ConsumerState<TrainTab> with TickerProviderStateMixin {
  // Locked workout state
  LockedWorkout? _lockedWorkout;
  int _currentExerciseIndex = 0;
  
  // Camera & pose detection
  CameraController? _cameraController;
  PoseDetectorService? _poseDetectorService;
  bool _isCameraInitialized = false;
  String? _cameraError;
  List<PoseLandmark>? _landmarks;
  
  // Rep counter (new proportion-based system)
  RepCounter? _repCounter;
  
  // UI state
  bool _isWorkoutActive = false;
  bool _isResting = false;
  int _restTimeRemaining = 60;
  Timer? _restTimer;
  
  // Current set/rep tracking
  int _currentSet = 1;
  int _currentReps = 0;
  int _targetSets = 3;
  int _targetReps = 10;
  
  // Feedback display
  String _feedback = '';
  double _formScore = 0;
  bool _showRepFlash = false;
  bool _isRecording = false;

  // GAMING FEATURES
  SkeletonState _skeletonState = SkeletonState.idle;
  double _chargeProgress = 0.0;
  double _powerGaugeFill = 0.0;
  
  // Countdown & body detection
  bool _showPhoneGuide = false;
  bool _showCountdown = false;
  bool _bodyDetected = false;
  bool _isScanning = false;
  bool _isLocked = false;
  int _countdownValue = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadLockedWorkout();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _countdownTimer?.cancel();
    _cameraController?.dispose();
    _poseDetectorService?.dispose();
    super.dispose();
  }

  void _loadLockedWorkout() {
    final lockedWorkout = ref.read(lockedWorkoutProvider);
    setState(() {
      _lockedWorkout = lockedWorkout;
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() => _cameraError = 'Camera permission denied');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No cameras available');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      _poseDetectorService = PoseDetectorService();

      // Start image stream
      _cameraController!.startImageStream(_processFrame);

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      setState(() => _cameraError = 'Camera error: $e');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_poseDetectorService == null) return;

    final landmarks = await _poseDetectorService!.detectPose(image);

    if (landmarks != null && mounted) {
      // Check if body is in frame
      final hasLeftShoulder = landmarks.any((l) => l.type == PoseLandmarkType.leftShoulder && l.likelihood > 0.5);
      final hasRightShoulder = landmarks.any((l) => l.type == PoseLandmarkType.rightShoulder && l.likelihood > 0.5);
      final hasLeftHip = landmarks.any((l) => l.type == PoseLandmarkType.leftHip && l.likelihood > 0.5);
      final hasRightHip = landmarks.any((l) => l.type == PoseLandmarkType.rightHip && l.likelihood > 0.5);
      
      final wasBodyDetected = _bodyDetected;
      final bodyInFrame = hasLeftShoulder && hasRightShoulder && hasLeftHip && hasRightHip;
      
      // Update body detection status
      if (bodyInFrame != _bodyDetected) {
        setState(() => _bodyDetected = bodyInFrame);
      }
      
      // Start countdown when body first detected
      if (_showCountdown && bodyInFrame && !wasBodyDetected && !_isScanning && !_isLocked) {
        _startCountdownTimer();
      }
      
      // Reset countdown if body lost during countdown (before scanning)
      if (_showCountdown && !bodyInFrame && wasBodyDetected && !_isScanning && !_isLocked) {
        _countdownTimer?.cancel();
        setState(() => _countdownValue = 3);
      }
      
      // Process reps only after locked
      if (_isLocked && _isWorkoutActive && !_isResting && _repCounter != null) {
        final repCompleted = _repCounter!.processFrame(landmarks);
        
        if (repCompleted) {
          _onRepCompleted();
        }
        
        // Update UI state from rep counter
        setState(() {
          _feedback = _repCounter!.feedback;
          _currentReps = _repCounter!.repCount;
          
          // Update skeleton state based on rep phase
          final percentage = _repCounter!.currentPercentage;
          final state = _repCounter!.state;
          
          if (state == RepState.down) {
            _skeletonState = SkeletonState.charging;
            _chargeProgress = 1.0 - (percentage / 100.0);
            _powerGaugeFill = _chargeProgress;
          } else {
            _skeletonState = SkeletonState.idle;
            _chargeProgress = 0.0;
            _powerGaugeFill = 0.0;
          }
        });
      }

      setState(() {
        _landmarks = landmarks;
      });
    } else {
      // Body lost
      if (_bodyDetected && mounted) {
        setState(() => _bodyDetected = false);
      }
    }
  }

  void _onRepCompleted() {
    print('🎯 REP COMPLETED: ${_repCounter!.repCount}');
    
    setState(() {
      _showRepFlash = true;
      _skeletonState = SkeletonState.perfect;
    });
    
    // Haptic feedback
    HapticHelper.perfectRepHaptic();
    
    // Hide flash after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showRepFlash = false;
          _skeletonState = SkeletonState.idle;
          _chargeProgress = 0.0;
          _powerGaugeFill = 0.0;
        });
      }
    });
    
    // Check if set complete
    if (_currentReps >= _targetReps) {
      _onSetComplete();
    }
  }

  void _onSetComplete() {
    print('✅ SET $_currentSet COMPLETE');
    
    if (_currentSet >= _targetSets) {
      // Exercise complete, move to next
      _nextExercise();
    } else {
      // More sets, start rest
      _startRest();
    }
  }

  Future<void> _startWorkout() async {
    if (_lockedWorkout == null || _lockedWorkout!.exercises.isEmpty) return;

    // Step 1: Show phone positioning guide
    setState(() {
      _showPhoneGuide = true;
    });
  }
  
  void _onPhoneGuideComplete() {
    setState(() {
      _showPhoneGuide = false;
    });
    _continueToCountdown();
  }
  
  Future<void> _continueToCountdown() async {
    // Initialize camera
    await _initializeCamera();
    
    // Show countdown screen
    setState(() {
      _showCountdown = true;
      _bodyDetected = false;
      _isScanning = false;
      _isLocked = false;
      _countdownValue = 3;
      _isWorkoutActive = true;
      _currentExerciseIndex = 0;
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _countdownValue--;
      });
      
      if (_countdownValue <= 0) {
        timer.cancel();
        _startScanning();
      }
    });
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
    
    // Scanning for 2 seconds, then lock
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _bodyDetected) {
        _lockOnUser();
      } else if (mounted) {
        // Body lost during scanning, reset
        setState(() {
          _isScanning = false;
          _countdownValue = 3;
        });
      }
    });
  }

  void _lockOnUser() {
    if (_landmarks == null) return;
    
    // Initialize rep counter for current exercise
    final exercise = _lockedWorkout!.exercises[_currentExerciseIndex];
    final rule = ExerciseRules.getRule(exercise.id);
    
    if (rule != null) {
      _repCounter = RepCounter(rule);
      _repCounter!.captureBaseline(_landmarks!);
      
      setState(() {
        _targetSets = exercise.sets;
        _targetReps = exercise.reps;
        _currentSet = 1;
        _currentReps = 0;
      });
    }
    
    setState(() {
      _isScanning = false;
      _isLocked = true;
    });
    
    // Show LOCKED for 1.5 seconds, then hide countdown overlay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showCountdown = false;
        });
      }
    });
  }

  void _nextExercise() {
    if (_lockedWorkout == null) return;
    
    if (_currentExerciseIndex < _lockedWorkout!.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
      _startRest();
    } else {
      // Workout complete!
      _completeWorkout();
    }
  }

  void _completeWorkout() {
    HapticHelper.workoutCompleteHaptic();
    _endWorkout();
    // TODO: Show completion stats modal
  }

  void _startRest() {
    setState(() {
      _isResting = true;
      _restTimeRemaining = 60;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 0) {
        setState(() => _restTimeRemaining--);
      } else {
        timer.cancel();
        _endRest();
      }
    });
  }

  void _endRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _currentSet++;
      _currentReps = 0;
    });
    
    // Reset rep counter for next set
    _repCounter?.reset();
    
    // Re-lock on user for new set/exercise
    if (_landmarks != null && _repCounter != null) {
      _repCounter!.captureBaseline(_landmarks!);
    }
  }

  void _skipRest() {
    _restTimer?.cancel();
    _endRest();
  }

  void _finishSet() {
    _onSetComplete();
  }

  void _endWorkout() {
    _restTimer?.cancel();
    _countdownTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _cameraController = null;
    _poseDetectorService?.dispose();
    _poseDetectorService = null;
    _repCounter = null;

    setState(() {
      _isWorkoutActive = false;
      _isResting = false;
      _isCameraInitialized = false;
      _landmarks = null;
      _currentExerciseIndex = 0;
      _showCountdown = false;
      _isScanning = false;
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Step 1: Show phone positioning guide
    if (_showPhoneGuide) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PhonePositionGuide(
              onContinue: _onPhoneGuideComplete,
              exerciseName: _lockedWorkout?.exercises.first.name ?? 'Exercise',
            ),
          ),
        ),
      );
    }
    
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_open, size: 80, color: AppColors.white30),
              const SizedBox(height: 24),
              const Text(
                'NO WORKOUT LOCKED',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Go to WORKOUTS tab to lock a workout.',
                style: TextStyle(fontSize: 14, color: AppColors.white60),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
                  const Icon(Icons.lock, color: AppColors.cyberLime, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _lockedWorkout!.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_lockedWorkout!.exercises.length} exercises • ~${_lockedWorkout!.estimatedMinutes} min',
                    style: const TextStyle(fontSize: 14, color: AppColors.white60),
                  ),
                  const SizedBox(height: 20),
                  
                  // Show which exercises have AI tracking
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white5,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI TRACKING:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.white50),
                        ),
                        const SizedBox(height: 8),
                        ..._lockedWorkout!.exercises.map((e) {
                          final hasTracking = ExerciseRules.hasRule(e.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  hasTracking ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: hasTracking ? AppColors.cyberLime : AppColors.white30,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  e.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasTracking ? Colors.white : AppColors.white50,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
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
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingScreen() {
    if (_lockedWorkout == null) return _buildStartScreen();
    
    final exercise = _lockedWorkout!.exercises[_currentExerciseIndex];

    if (_cameraError != null) {
      return Center(child: Text(_cameraError!, style: const TextStyle(color: Colors.white)));
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.cyberLime),
            SizedBox(height: 24),
            Text('Starting camera...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(child: CameraPreview(_cameraController!)),

        // Skeleton overlay
        if (_landmarks != null)
          Positioned.fill(
            child: CustomPaint(
              painter: SkeletonPainter(
                landmarks: _landmarks,
                imageSize: Size(
                  _cameraController!.value.previewSize!.height,
                  _cameraController!.value.previewSize!.width,
                ),
                isFrontCamera: true,
                skeletonState: _skeletonState,
                chargeProgress: _chargeProgress,
              ),
            ),
          ),

        // COUNTDOWN OVERLAY
        if (_showCountdown)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status based on phase
                    if (!_bodyDetected) ...[
                      // Waiting for body
                      const Icon(
                        Icons.accessibility_new,
                        size: 100,
                        color: AppColors.white30,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'GET IN POSITION',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.electricCyan,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Stay 5-7 feet from camera\nFull body visible',
                        style: TextStyle(fontSize: 14, color: AppColors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ] else if (!_isScanning && !_isLocked) ...[
                      // Countdown 3, 2, 1
                      Text(
                        '$_countdownValue',
                        style: TextStyle(
                          fontSize: 150,
                          fontWeight: FontWeight.w900,
                          color: AppColors.electricCyan,
                          shadows: [
                            Shadow(
                              color: AppColors.electricCyan.withOpacity(0.8),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'HOLD POSITION',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                    ] else if (_isScanning) ...[
                      // Scanning
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: AppColors.electricCyan,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'SCANNING...',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.electricCyan,
                          letterSpacing: 4,
                        ),
                      ),
                    ] else if (_isLocked) ...[
                      // Locked!
                      const Icon(
                        Icons.check_circle,
                        size: 100,
                        color: AppColors.cyberLime,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'LOCKED',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cyberLime,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: AppColors.cyberLime.withOpacity(0.8),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        // Power Gauge - Left edge (only show when not in countdown)
        if (!_showCountdown)
          Positioned(
            left: 16,
            top: MediaQuery.of(context).size.height / 2 - 100,
            child: PowerGauge(fillPercent: _powerGaugeFill),
          ),

        // Exercise info - top left
        if (!_showCountdown)
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name.toUpperCase(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  Text(
                    'SET $_currentSet/${exercise.sets}',
                    style: const TextStyle(fontSize: 12, color: AppColors.white60),
                  ),
                ],
              ),
            ),
          ),

        // Close button
        Positioned(
          top: 50,
          right: 16,
          child: GestureDetector(
            onTap: _endWorkout,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
        ),

        // REP COUNTER - Top Right
        if (!_showCountdown)
          Positioned(
            top: 120,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.cyberLime.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyberLime.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_currentReps',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.cyberLime,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/ $_targetReps',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white50,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Rep flash animation
        if (_showRepFlash)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.5),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: 1 - ((value - 0.5) / 1.0),
                    child: const Text(
                      '+1',
                      style: TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cyberLime,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Bottom buttons (only show when not in countdown)
        if (!_showCountdown) ...[
          // Record button - Bottom Left
          Positioned(
            bottom: 40,
            left: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isRecording = !_isRecording;
                });
                print('🎥 Recording: $_isRecording');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isRecording ? AppColors.neonCrimson : Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRecording ? AppColors.neonCrimson : AppColors.white30,
                    width: 2,
                  ),
                  boxShadow: _isRecording ? [
                    BoxShadow(
                      color: AppColors.neonCrimson.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ] : null,
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.fiber_manual_record,
                  color: _isRecording ? Colors.white : AppColors.white70,
                  size: 24,
                ),
              ),
            ),
          ),

          // Finish set button - Bottom center
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _finishSet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cyberLime,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'FINISH SET',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],

        // Cancel button during countdown
        if (_showCountdown)
          Positioned(
            top: 60,
            left: 20,
            child: IconButton(
              onPressed: _endWorkout,
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
      ],
    );
  }

  Widget _buildRestScreen() {
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'REST',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.white40),
            ),
            const SizedBox(height: 32),
            Text(
              '$_restTimeRemaining',
              style: const TextStyle(
                fontSize: 140,
                fontWeight: FontWeight.w900,
                color: AppColors.cyberLime,
              ),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: _skipRest,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.white20),
                ),
                child: const Text(
                  'SKIP REST',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
