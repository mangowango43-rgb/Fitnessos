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
import '../../widgets/tactical_countdown.dart';
import '../../widgets/tactical_hud.dart';
import '../../widgets/phone_position_guide.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/glow_button.dart';
import '../../models/workout_models.dart';
import '../../models/rep_quality.dart';
import '../../providers/workout_provider.dart';

// NEW: Import the rep counting system
import '../../services/workout_session.dart';
import '../../services/exercise_rules.dart';
import '../../services/rep_counter.dart' show RepState;

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
  
  // NEW: Workout session for rep counting
  WorkoutSession? _session;
  
  // UI state
  bool _isWorkoutActive = false;
  bool _isResting = false;
  int _restTimeRemaining = 60;
  Timer? _restTimer;
  
  // Feedback display
  String _feedback = '';
  double _formScore = 0;
  bool _showRepFlash = false;
  bool _isRecording = false;

  // GAMING FEATURES
  SkeletonState _skeletonState = SkeletonState.idle;
  double _chargeProgress = 0.0;
  double _powerGaugeFill = 0.0;
  RepQuality? _lastRepQuality;
  bool _showShatterAnimation = false;
  
  // Countdown & body detection
  bool _showCountdown = false;
  bool _bodyDetected = false;
  bool _countdownComplete = false;
  bool _showPhoneGuide = false;
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
    _session?.dispose();
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
      // Check if body is in frame (for countdown detection)
      final hasLeftShoulder = landmarks.any((l) => l.type == PoseLandmarkType.leftShoulder);
      final hasRightShoulder = landmarks.any((l) => l.type == PoseLandmarkType.rightShoulder);
      final hasLeftHip = landmarks.any((l) => l.type == PoseLandmarkType.leftHip);
      final hasRightHip = landmarks.any((l) => l.type == PoseLandmarkType.rightHip);
      
      final wasBodyDetected = _bodyDetected;
      final bodyInFrame = hasLeftShoulder && hasRightShoulder && hasLeftHip && hasRightHip;
      
      // Update body detection status
      if (bodyInFrame != _bodyDetected) {
        setState(() => _bodyDetected = bodyInFrame);
      }
      
      // Start countdown when body first detected during countdown phase (before scanning/locked)
      if (_showCountdown && bodyInFrame && !wasBodyDetected && !_isScanning && !_isLocked) {
        _startCountdownTimer();
      }
      
      // Reset countdown if body lost during countdown (before scanning)
      if (_showCountdown && !bodyInFrame && wasBodyDetected && !_isScanning && !_isLocked) {
        _countdownTimer?.cancel();
        setState(() => _countdownValue = 3);
      }
      
      // Only process workout if countdown complete
      if (_countdownComplete && _isWorkoutActive && !_isResting) {
        _session?.processPose(landmarks);
      }

      setState(() {
        _landmarks = landmarks;
        // _feedback removed - voice coach handles feedback now
        _formScore = _session?.formScore ?? 0;

        // GAMING: Update skeleton state and power gauge based on rep phase
        final repState = _session?.repState;
        final chargeProgress = _session?.chargeProgress ?? 0.0;
        
        // Check for bad form feedback - AGGRESSIVE detection
        final hasBadFormFeedback = _feedback.isNotEmpty && 
                                   (_feedback.contains('!') || 
                                    _feedback.contains('Keep') || 
                                    _feedback.contains('Don') ||
                                    _feedback.contains('deeper') ||
                                    _feedback.contains('higher') ||
                                    _feedback.contains('Squeeze') ||
                                    _feedback.contains('cave') ||
                                    _feedback.contains('pike') ||
                                    _feedback.contains('sag'));
        
        // DEBUG: Log form feedback and score
        if (_feedback.isNotEmpty && _feedback != 'Get in frame') {
          print('🔴 FORM CHECK: "$_feedback" | Score: $_formScore | HasBadFeedback: $hasBadFormFeedback');
        }

        if (repState == RepState.down) {
          // User is descending/at bottom - CHARGING state
          _skeletonState = SkeletonState.charging;
          _chargeProgress = chargeProgress;
          _powerGaugeFill = chargeProgress;
        } else if (repState == RepState.up) {
          // User is ascending - IDLE state (or keep charging visual briefly)
          _skeletonState = SkeletonState.idle;
          // Keep power gauge filled briefly during ascent
          _powerGaugeFill = chargeProgress;
        } else {
          // At ready position
          _skeletonState = SkeletonState.idle;
          _chargeProgress = 0.0;
          _powerGaugeFill = 0.0;
        }
      });
    } else {
      // Body lost
      if (_bodyDetected && mounted) {
        setState(() => _bodyDetected = false);
      }
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
    // Step 2: Initialize camera
    await _initializeCamera();
    
    // Step 3: Show countdown screen (waiting for body detection)
    setState(() {
      _showCountdown = true;
      _countdownComplete = false;
      _isScanning = false;
      _isLocked = false;
      _countdownValue = 3;
    });
    
    // If body already detected, start countdown immediately
    if (_bodyDetected) {
      _startCountdownTimer();
    }
    
    // Initialize workout session
    _session = WorkoutSession();
    await _session!.init();
    
    // Set up callbacks
    _session!.onRepCounted = (reps, score) {
      print('🎯 REP COMPLETED: Rep $reps with score $score');
      
      setState(() {
        _showRepFlash = true;
        _formScore = score;
        
        // GAMING: Flash skeleton to PERFECT state
        _skeletonState = SkeletonState.perfect;
      });
      
      // Trigger haptic based on form score
      if (score >= 85) {
        // PERFECT REP
        print('📳 Triggering PERFECT haptic');
        HapticHelper.perfectRepHaptic();
      } else if (score >= 60) {
        // GOOD REP
        print('📳 Triggering GOOD haptic');
        HapticHelper.goodRepHaptic();
      } else {
        // MISSED REP
        print('📳 Triggering MISSED haptic');
        HapticHelper.missedRepHaptic();
      }
      
      // Hide flash and return to idle after animation
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
    };
    
    _session!.onSetComplete = (setComplete, totalSets) {
      if (setComplete >= totalSets) {
        // Move to next exercise
        _nextExercise();
      } else {
        // Start rest timer
        _startRest();
      }
    };
    
    _session!.onFeedback = (feedback) {
      setState(() => _feedback = feedback);
    };

    _session!.onRepQuality = (quality, score) {
      setState(() => _lastRepQuality = quality);
    };

    setState(() {
      _isWorkoutActive = true;
      _currentExerciseIndex = 0;
    });

    // Start first exercise
    _startCurrentExercise();
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
        _finishLockAndStartWorkout();
      } else if (mounted) {
        // Body lost during scanning, reset
        setState(() {
          _isScanning = false;
          _countdownValue = 3;
        });
      }
    });
  }

  void _finishLockAndStartWorkout() {
    setState(() {
      _isScanning = false;
      _isLocked = true;
    });
    
    // Show LOCKED for 1.5 seconds, then hide countdown and start workout
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showCountdown = false;
          _countdownComplete = true;
        });
      }
    });
  }

  void _advanceToNextExercise() {
    if (_lockedWorkout == null) return;
    
    if (_currentExerciseIndex < _lockedWorkout!.exercises.length - 1) {
      // More exercises remaining
      setState(() {
        _currentExerciseIndex++;
      });
      print('▶️ Starting exercise ${_currentExerciseIndex + 1}: ${_lockedWorkout!.exercises[_currentExerciseIndex].name}');
      _startCurrentExercise();
    } else {
      // ALL EXERCISES COMPLETE - Workout done!
      print('🏆 WORKOUT COMPLETE!');
      _completeWorkout();
    }
  }

  void _completeWorkout() {
    // Play completion haptic
    HapticHelper.workoutCompleteHaptic();
    
    // End the workout
    _endWorkout();
    
    // TODO: Show completion stats modal
  }

  void _startCurrentExercise() {
    if (_lockedWorkout == null) return;
    
    final exercise = _lockedWorkout!.exercises[_currentExerciseIndex];
    
    // Check if we have a tracking rule for this exercise
    if (ExerciseRules.hasRule(exercise.id)) {
      _session?.startExercise(
        exerciseId: exercise.id,
        sets: exercise.sets,
        reps: exercise.reps,
      );
    } else {
      // No AI tracking for this exercise - just manual mode
      print('⚠️ No tracking rule for ${exercise.name}, using manual mode');
    }
  }

  void _nextExercise() {
    if (_lockedWorkout == null) return;
    
    if (_currentExerciseIndex < _lockedWorkout!.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
      _startRest(); // Rest between exercises
    } else {
      // Workout complete!
      _completeWorkout();
    }
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
    setState(() => _isResting = false);
    
    // Check if we need to do more sets of current exercise
    final currentSet = _session?.currentSet ?? 0;
    final targetSets = _session?.targetSets ?? 0;
    
    print('🔄 END REST: Set $currentSet of $targetSets');
    
    if (currentSet <= targetSets) {
      // More sets to go for THIS exercise (or starting the last one)
      _session?.startNextSet();
    } else {
      // All sets complete for this exercise - MOVE TO NEXT
      print('✅ Exercise complete, moving to next');
      _advanceToNextExercise();
    }
  }

  void _skipRest() {
    _restTimer?.cancel();
    _endRest();
  }

  void _finishSet() {
    _session?.skipToNextSet();
  }

  void _endWorkout() {
    _restTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _cameraController = null;
    _poseDetectorService?.dispose();
    _poseDetectorService = null;
    _session?.dispose();
    _session = null;

    setState(() {
      _isWorkoutActive = false;
      _isResting = false;
      _isCameraInitialized = false;
      _landmarks = null;
      _currentExerciseIndex = 0;
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
    
    // Step 2: Show countdown screen (waiting for body detection)
    if (_showCountdown) {
      return _buildCountdownScreen();
    }
    
    if (!_isWorkoutActive) {
      return _buildStartScreen();
    }

    if (_isResting) {
      return _buildRestScreen();
    }

    return _buildTrainingScreen();
  }


  Widget _buildCountdownScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_cameraController != null && _isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),
          
          // Skeleton overlay (shows body detection)
          if (_landmarks != null && _cameraController != null)
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
                  chargeProgress: 0.0,
                ),
              ),
            ),
          
          // Dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          
          // Countdown content - NEW FLOW: Get in position → 3,2,1 → Scanning → ✓ Locked
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Phase 1: GET IN POSITION (no body detected yet)
                if (!_bodyDetected && !_isScanning && !_isLocked) ...[
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
                ]
                // Phase 2: COUNTDOWN 3, 2, 1 (body detected, counting down)
                else if (_bodyDetected && !_isScanning && !_isLocked) ...[
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
                ]
                // Phase 3: SCANNING (after 3,2,1 countdown)
                else if (_isScanning) ...[
                  SizedBox(
                    width: 80,
                    height: 80,
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
                ]
                // Phase 4: LOCKED ✓ (scan complete, about to start)
                else if (_isLocked) ...[
                  Icon(
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
          
          // Cancel button
          Positioned(
            top: 60,
            left: 20,
            child: IconButton(
              onPressed: () {
                _countdownTimer?.cancel();
                setState(() {
                  _showCountdown = false;
                  _isWorkoutActive = false;
                });
                _endWorkout();
              },
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
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
    final size = MediaQuery.of(context).size;

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

        // GAMING: Power Gauge - Left edge
        Positioned(
          left: 16,
          top: MediaQuery.of(context).size.height / 2 - 100, // Vertically centered
          child: PowerGauge(fillPercent: _powerGaugeFill),
        ),

        // GAMING: Shatter Animation - Full screen overlay
        if (_showShatterAnimation)
          Positioned.fill(
            child: ShatterAnimation(
              onComplete: () {
                if (mounted) setState(() => _showShatterAnimation = false);
              },
            ),
          ),
        
        // TACTICAL: Countdown & Body Detection HUD
        if (_showCountdown)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // HUD showing body detection status
                  TacticalHUD(
                    status: _bodyDetected ? 'BODY DETECTED' : 'ENTER FRAME',
                    subStatus: _bodyDetected 
                        ? 'Hold position...' 
                        : 'Step into view',
                    statusColor: _bodyDetected 
                        ? AppColors.cyberLime 
                        : AppColors.electricCyan,
                    showPulse: _bodyDetected,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Device placement guide
                  if (!_bodyDetected)
                    Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.electricCyan.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 48,
                            color: AppColors.electricCyan,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'DEVICE PLACEMENT',
                            style: TextStyle(
                              color: AppColors.electricCyan,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Place device 6-8 feet away\nat waist height\nFull body should be visible',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white70,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 48),
                  
                  // Countdown starts when body detected
                  if (_bodyDetected)
                    TacticalCountdown(
                      bodyDetected: _bodyDetected,
                      onComplete: () {
                        setState(() {
                          _showCountdown = false;
                          _countdownComplete = true;
                          _isWorkoutActive = true;
                        });
                        _startCurrentExercise();
                      },
                    ),
                ],
              ),
            ),
          ),

        // Exercise info - top left
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
                  'SET ${_session?.currentSet ?? 1}/${exercise.sets}',
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

        // REP COUNTER - Top Right (compact)
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
                  '${_session?.currentReps ?? 0}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.cyberLime,
                    height: 1,
                  ),
                ),
                Text(
                  '/ ${exercise.reps}',
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

        // Text feedback REMOVED - voice coach handles all feedback now
        // Screen shows: camera, skeleton, power gauge, rep counter only

        // Debug info - current angle and phase
        Positioned(
          top: 120,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Angle: ${_session?.currentAngle.toStringAsFixed(0)}°',
                  style: const TextStyle(fontSize: 10, color: AppColors.white60),
                ),
                Text(
                  'Phase: ${_session?.phase ?? ""}',
                  style: const TextStyle(fontSize: 10, color: AppColors.white60),
                ),
              ],
            ),
          ),
        ),

        // Record button - Bottom Left
        Positioned(
          bottom: 40,
          left: 20,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isRecording = !_isRecording;
              });
              // TODO: Implement video recording
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

        // Bottom center button
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
