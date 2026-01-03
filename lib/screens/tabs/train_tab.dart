import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../utils/app_colors.dart';

import '../../services/pose_detector_service.dart';
import '../../widgets/skeleton_painter.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../models/workout_models.dart';
import '../../providers/workout_provider.dart';

// NEW: Import the proportion-based rep counter
import '../../services/rep_counter.dart';
import '../../services/voice_coach.dart';

/// Startup phase for the workout
enum StartupPhase {
  idle,        // Not started yet
  countdown,   // 3... 2... 1...
  scanning,    // Body detected, scanning effect
  locked,      // SYSTEM LOCKED - baseline captured
  active,      // Workout in progress
  resting,     // Rest between sets
  complete,    // Workout finished
}

class TrainTab extends ConsumerStatefulWidget {
  const TrainTab({super.key});

  @override
  ConsumerState<TrainTab> createState() => _TrainTabState();
}

class _TrainTabState extends ConsumerState<TrainTab> with TickerProviderStateMixin {
  // Workout state
  LockedWorkout? _lockedWorkout;
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  int _totalSets = 3;
  int _targetReps = 10;
  
  // Camera & pose detection
  CameraController? _cameraController;
  PoseDetectorService? _poseDetectorService;
  bool _isCameraInitialized = false;
  String? _cameraError;
  List<PoseLandmark>? _landmarks;
  
  // NEW: Proportion-based rep counter
  RepCounter? _repCounter;
  VoiceCoach? _voiceCoach;
  
  // Startup sequence
  StartupPhase _phase = StartupPhase.idle;
  int _countdownValue = 3;
  Timer? _countdownTimer;
  double _scanProgress = 0;
  
  // Rep tracking
  int _currentReps = 0;
  bool _showRepFlash = false;
  int _comboCount = 0;
  int _maxCombo = 0;
  
  // Rest timer
  int _restTimeRemaining = 60;
  Timer? _restTimer;
  
  // Skeleton state - SIMPLIFIED
  // White = idle, Cyan = tracking, Green = rep flash
  Color _skeletonColor = AppColors.white70;
  double _skeletonGlow = 6.0;
  
  // Animation controllers
  late AnimationController _scanAnimController;
  late AnimationController _repFlashController;

  @override
  void initState() {
    super.initState();
    _loadLockedWorkout();
    
    // Scan animation (sweeping line effect)
    _scanAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Rep flash animation
    _repFlashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _repFlashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showRepFlash = false;
          _skeletonColor = AppColors.electricCyan;
          _skeletonGlow = 6.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _restTimer?.cancel();
    _cameraController?.dispose();
    _poseDetectorService?.dispose();
    _voiceCoach?.dispose();
    _scanAnimController.dispose();
    _repFlashController.dispose();
    super.dispose();
  }

  void _loadLockedWorkout() {
    final lockedWorkout = ref.read(lockedWorkoutProvider);
    setState(() {
      _lockedWorkout = lockedWorkout;
    });
  }

  // ===========================================================================
  // STARTUP SEQUENCE
  // ===========================================================================

  Future<void> _startWorkout() async {
    if (_lockedWorkout == null || _lockedWorkout!.exercises.isEmpty) return;
    
    // Initialize voice coach
    _voiceCoach = VoiceCoach();
    await _voiceCoach!.init();
    
    // Initialize camera
    await _initializeCamera();
    if (!_isCameraInitialized) return;
    
    // Start the countdown
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _phase = StartupPhase.countdown;
      _countdownValue = 3;
    });
    
    _voiceCoach?.speakNow('Get ready');
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
        _voiceCoach?.speakNow('$_countdownValue');
      } else {
        timer.cancel();
        _startScanning();
      }
    });
  }

  void _startScanning() {
    setState(() {
      _phase = StartupPhase.scanning;
      _scanProgress = 0;
    });
    
    _scanAnimController.forward(from: 0);
    
    // Scan takes 1.5 seconds, then lock
    Future.delayed(const Duration(milliseconds: 1500), () {
      _lockSystem();
    });
  }

  void _lockSystem() {
    // Get the exercise rule
    final exercise = _lockedWorkout!.exercises[_currentExerciseIndex];
    final rule = ExerciseRules.getRule(exercise.id);
    
    print('🎯 _lockSystem called');
    print('   Exercise: ${exercise.name} (id: ${exercise.id})');
    print('   Rule found: ${rule != null}');
    print('   Landmarks: ${_landmarks?.length ?? 0}');
    
    if (rule == null) {
      // No rule for this exercise - skip tracking, just go
      print('⚠️ No rule found, starting without tracking');
      _voiceCoach?.speakNow('Starting ${exercise.name}');
      setState(() => _phase = StartupPhase.locked);
      Future.delayed(const Duration(milliseconds: 800), () {
        _beginExercise();
      });
      return;
    }
    
    // Create rep counter
    _repCounter = RepCounter(rule);
    
    // Try to capture baseline if we have landmarks
    if (_landmarks != null && _landmarks!.isNotEmpty) {
      _repCounter!.captureBaseline(_landmarks!);
    }
    
    // Check if locked successfully
    if (_repCounter!.isLocked) {
      print('✅ LOCKED SUCCESSFULLY');
      setState(() {
        _phase = StartupPhase.locked;
        _skeletonColor = AppColors.electricCyan;
      });
      
      _voiceCoach?.speakNow('System locked');
      
      // Brief pause then start
      Future.delayed(const Duration(milliseconds: 800), () {
        _beginExercise();
      });
    } else {
      // Not locked yet - keep scanning, try again in 500ms
      // Don't restart the whole countdown, just keep trying
      print('⏳ Not locked yet, retrying in 500ms');
      setState(() {
        _phase = StartupPhase.scanning;
      });
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_phase == StartupPhase.scanning && mounted) {
          _lockSystem(); // Try again
        }
      });
    }
  }

  void _beginExercise() {
    final exercise = _lockedWorkout!.exercises[_currentExerciseIndex];
    
    setState(() {
      _phase = StartupPhase.active;
      _currentReps = 0;
      _currentSet = 1;
      _totalSets = exercise.sets;
      _targetReps = exercise.reps;
      _comboCount = 0;
    });
    
    _voiceCoach?.speakNow('${exercise.name}. ${exercise.sets} sets of ${exercise.reps}. Go!');
  }

  // ===========================================================================
  // CAMERA & POSE PROCESSING
  // ===========================================================================

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
    
    // Always detect pose (for skeleton display)
    final landmarks = await _poseDetectorService!.detectPose(image);
    
    if (landmarks != null && mounted) {
      setState(() => _landmarks = landmarks);
      
      // Only count reps when active
      if (_phase == StartupPhase.active && _repCounter != null) {
        bool repCompleted = _repCounter!.processFrame(landmarks);
        
        if (repCompleted) {
          _onRepCompleted();
        }
        
        // Update skeleton color based on movement
        _updateSkeletonVisuals();
      }
    }
  }

  void _updateSkeletonVisuals() {
    if (_repCounter == null) return;
    
    final percentage = _repCounter!.currentPercentage;
    
    // Skeleton gets brighter as you go deeper into rep
    if (percentage < 90) {
      // Going down - intensify cyan
      final intensity = (90 - percentage) / 30; // 0 to 1
      setState(() {
        _skeletonGlow = 6.0 + (intensity * 8.0); // 6 to 14
      });
    }
  }

  void _onRepCompleted() {
    setState(() {
      _currentReps++;
      _comboCount++;
      if (_comboCount > _maxCombo) _maxCombo = _comboCount;
      
      // GREEN FLASH
      _showRepFlash = true;
      _skeletonColor = AppColors.cyberLime;
      _skeletonGlow = 14.0;
    });
    
    // Haptic feedback
    // Visual feedback does the job - phone is on floor anyway
    
    // Voice announces rep number
    _voiceCoach?.announceRep(_currentReps);
    
    // Animate flash
    _repFlashController.forward(from: 0);
    
    // Check if set complete
    if (_currentReps >= _targetReps) {
      _onSetComplete();
    }
  }

  void _onSetComplete() {
    if (_currentSet >= _totalSets) {
      // Exercise complete - move to next
      _nextExercise();
    } else {
      // More sets to go - rest
      _startRest();
    }
  }

  void _startRest() {
    setState(() {
      _phase = StartupPhase.resting;
      _restTimeRemaining = 60;
    });
    
    _voiceCoach?.speakNow('Set ${_currentSet} complete. Rest.');

    
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _restTimeRemaining--);
      
      if (_restTimeRemaining == 10) {
        _voiceCoach?.speakNow('10 seconds');
      } else if (_restTimeRemaining <= 0) {
        timer.cancel();
        _startNextSet();
      }
    });
  }

  void _startNextSet() {
    setState(() {
      _currentSet++;
      _currentReps = 0;
      _phase = StartupPhase.active;
      _comboCount = 0;
    });
    
    _repCounter?.reset();
    _voiceCoach?.speakNow('Set $_currentSet. Go!');
  }

  void _skipRest() {
    _restTimer?.cancel();
    _startNextSet();
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _lockedWorkout!.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
      
      _voiceCoach?.speakNow('Exercise complete. Next up.');
      
      // Re-lock for new exercise
      Future.delayed(const Duration(seconds: 2), () {
        _startCountdown();
      });
    } else {
      // Workout complete!
      setState(() => _phase = StartupPhase.complete);
      _voiceCoach?.speakNow('Workout complete. Great job!');

    }
  }

  // ===========================================================================
  // BUILD UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case StartupPhase.idle:
        return _buildIdleScreen();
      case StartupPhase.countdown:
        return _buildCountdownScreen();
      case StartupPhase.scanning:
        return _buildScanningScreen();
      case StartupPhase.locked:
        return _buildLockedScreen();
      case StartupPhase.active:
        return _buildActiveScreen();
      case StartupPhase.resting:
        return _buildRestScreen();
      case StartupPhase.complete:
        return _buildCompleteScreen();
    }
  }

  // ---------------------------------------------------------------------------
  // IDLE - Before workout starts
  // ---------------------------------------------------------------------------
  Widget _buildIdleScreen() {
    if (_lockedWorkout == null) {
      return const Center(
        child: Text(
          'No workout selected.\nGo to Workouts tab to pick one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.white50, fontSize: 16),
        ),
      );
    }
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _lockedWorkout!.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_lockedWorkout!.exercises.length} exercises',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.white50,
              ),
            ),
            const SizedBox(height: 48),
            
            // Exercise list preview
            ...(_lockedWorkout!.exercises.take(5).map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${e.name} - ${e.sets}x${e.reps}',
                style: const TextStyle(color: AppColors.white70),
              ),
            ))),
            
            if (_lockedWorkout!.exercises.length > 5)
              Text(
                '+${_lockedWorkout!.exercises.length - 5} more',
                style: const TextStyle(color: AppColors.white40),
              ),
            
            const SizedBox(height: 48),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white5,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.white10),
              ),
              child: const Column(
                children: [
                  Text(
                    '📱 Place phone 5-7 feet away',
                    style: TextStyle(color: AppColors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '🧍 Make sure full body is visible',
                    style: TextStyle(color: AppColors.white70),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // START BUTTON
            GestureDetector(
              onTap: _startWorkout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.cyberLime,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyberLime.withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Text(
                  'START WORKOUT',
                  style: TextStyle(
                    fontSize: 18,
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
    );
  }

  // ---------------------------------------------------------------------------
  // COUNTDOWN - 3... 2... 1...
  // ---------------------------------------------------------------------------
  Widget _buildCountdownScreen() {
    return Stack(
      children: [
        // Camera preview
        if (_isCameraInitialized && _cameraController != null)
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),
        
        // Dark overlay
        Container(color: Colors.black.withOpacity(0.7)),
        
        // Skeleton (if visible)
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
                skeletonState: SkeletonState.idle,
              ),
            ),
          ),
        
        // Countdown number
        Center(
          child: Text(
            '$_countdownValue',
            style: TextStyle(
              fontSize: 200,
              fontWeight: FontWeight.w900,
              color: AppColors.cyberLime,
              shadows: [
                Shadow(
                  color: AppColors.cyberLime.withOpacity(0.8),
                  blurRadius: 40,
                ),
              ],
            ),
          ),
        ),
        
        // "Get Ready" text
        const Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Text(
            'GET READY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.white70,
              letterSpacing: 4,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCANNING - Body detected, scanning effect
  // ---------------------------------------------------------------------------
  Widget _buildScanningScreen() {
    return Stack(
      children: [
        // Camera preview
        if (_isCameraInitialized && _cameraController != null)
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),
        
        // Skeleton
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
                skeletonState: SkeletonState.charging,
              ),
            ),
          ),
        
        // Scan line effect
        AnimatedBuilder(
          animation: _scanAnimController,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height * _scanAnimController.value,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.electricCyan,
                      AppColors.cyberLime,
                      AppColors.electricCyan,
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricCyan.withOpacity(0.8),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // "SCANNING" text
        const Center(
          child: Text(
            'SCANNING',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.electricCyan,
              letterSpacing: 8,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LOCKED - System locked, baseline captured
  // ---------------------------------------------------------------------------
  Widget _buildLockedScreen() {
    return Stack(
      children: [
        // Camera preview
        if (_isCameraInitialized && _cameraController != null)
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),
        
        // Skeleton (locked = bright cyan)
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
                skeletonState: SkeletonState.perfect, // Bright for locked
              ),
            ),
          ),
        
        // "SYSTEM LOCKED" text
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock,
                size: 64,
                color: AppColors.cyberLime,
              ),
              const SizedBox(height: 16),
              Text(
                'SYSTEM LOCKED',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyberLime,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: AppColors.cyberLime.withOpacity(0.8),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIVE - Workout in progress
  // ---------------------------------------------------------------------------
  Widget _buildActiveScreen() {
    final exercise = _lockedWorkout!.exercises[_currentExerciseIndex];
    
    return Stack(
      children: [
        // Camera preview (full screen)
        if (_isCameraInitialized && _cameraController != null)
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),
        
        // Skeleton overlay
        if (_landmarks != null)
          Positioned.fill(
            child: CustomPaint(
              painter: _SimpleSkeleton(
                landmarks: _landmarks!,
                imageSize: Size(
                  _cameraController!.value.previewSize!.height,
                  _cameraController!.value.previewSize!.width,
                ),
                color: _skeletonColor,
                glowIntensity: _skeletonGlow,
              ),
            ),
          ),
        
        // Exercise name - top left
        Positioned(
          top: 60,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'SET $_currentSet / $_totalSets',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.white50,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Rep counter - center right
        Positioned(
          right: 20,
          top: MediaQuery.of(context).size.height / 2 - 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _showRepFlash ? AppColors.cyberLime : AppColors.white20,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$_currentReps',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: _showRepFlash ? AppColors.cyberLime : Colors.white,
                    height: 1,
                  ),
                ),
                Text(
                  '/ $_targetReps',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.white50,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Combo counter - top right (only show if combo >= 3)
        if (_comboCount >= 3)
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _comboCount >= 10 
                    ? AppColors.neonCrimson.withOpacity(0.9)
                    : _comboCount >= 5
                        ? Colors.orange.withOpacity(0.9)
                        : AppColors.cyberLime.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_comboCount}x COMBO',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        
        // Rep flash overlay
        if (_showRepFlash)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.5),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: 1 - ((value - 0.5) / 1.0),
                    child: Text(
                      '+1',
                      style: TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cyberLime,
                        shadows: [
                          Shadow(
                            color: AppColors.cyberLime.withOpacity(0.8),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        
        // Finish set button - bottom center
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => _onSetComplete(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.white30),
                ),
                child: const Text(
                  'FINISH SET',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REST - Between sets
  // ---------------------------------------------------------------------------
  Widget _buildRestScreen() {
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'REST',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.white40,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$_restTimeRemaining',
              style: const TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.w900,
                color: AppColors.cyberLime,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Next: Set $_currentSet of $_totalSets',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.white50,
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
                  border: Border.all(color: AppColors.white30),
                ),
                child: const Text(
                  'SKIP REST',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPLETE - Workout finished
  // ---------------------------------------------------------------------------
  Widget _buildCompleteScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎉',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            const Text(
              'WORKOUT COMPLETE',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.cyberLime,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Max Combo: ${_maxCombo}x',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.white70,
              ),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: () {
                setState(() {
                  _phase = StartupPhase.idle;
                  _currentExerciseIndex = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.cyberLime,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// =============================================================================
// SIMPLE SKELETON PAINTER - Just draws the skeleton, no fancy states
// =============================================================================

class _SimpleSkeleton extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final Size imageSize;
  final Color color;
  final double glowIntensity;
  
  _SimpleSkeleton({
    required this.landmarks,
    required this.imageSize,
    required this.color,
    required this.glowIntensity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowIntensity);
    
    final jointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowIntensity + 2);
    
    // Create landmark map
    final map = {for (var lm in landmarks) lm.type: lm};
    
    // Helper to get screen position
    Offset? getPos(PoseLandmarkType type) {
      final lm = map[type];
      if (lm == null || lm.likelihood < 0.5) return null;
      
      // Mirror for front camera and scale to screen
      final x = size.width - (lm.x / imageSize.width * size.width);
      final y = lm.y / imageSize.height * size.height;
      return Offset(x, y);
    }
    
    // Draw line between two landmarks
    void drawLine(PoseLandmarkType a, PoseLandmarkType b) {
      final posA = getPos(a);
      final posB = getPos(b);
      if (posA != null && posB != null) {
        canvas.drawLine(posA, posB, paint);
      }
    }
    
    // Draw joint
    void drawJoint(PoseLandmarkType type, {double radius = 6}) {
      final pos = getPos(type);
      if (pos != null) {
        canvas.drawCircle(pos, radius, jointPaint);
      }
    }
    
    // === BODY LINES ===
    
    // Torso
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    
    // Left arm
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    
    // Right arm
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    
    // Left leg
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    
    // Right leg
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    
    // === JOINTS ===
    
    // Large joints
    drawJoint(PoseLandmarkType.leftShoulder, radius: 8);
    drawJoint(PoseLandmarkType.rightShoulder, radius: 8);
    drawJoint(PoseLandmarkType.leftHip, radius: 8);
    drawJoint(PoseLandmarkType.rightHip, radius: 8);
    
    // Small joints
    drawJoint(PoseLandmarkType.leftElbow);
    drawJoint(PoseLandmarkType.rightElbow);
    drawJoint(PoseLandmarkType.leftWrist);
    drawJoint(PoseLandmarkType.rightWrist);
    drawJoint(PoseLandmarkType.leftKnee);
    drawJoint(PoseLandmarkType.rightKnee);
    drawJoint(PoseLandmarkType.leftAnkle);
    drawJoint(PoseLandmarkType.rightAnkle);
    
    // Head (nose)
    drawJoint(PoseLandmarkType.nose, radius: 10);
  }
  
  @override
  bool shouldRepaint(_SimpleSkeleton oldDelegate) {
    return oldDelegate.landmarks != landmarks ||
           oldDelegate.color != color ||
           oldDelegate.glowIntensity != glowIntensity;
  }
}
