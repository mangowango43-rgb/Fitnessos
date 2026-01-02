import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Random;
import 'dart:math' show min, max;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../utils/app_colors.dart';
import '../../utils/haptic_helper.dart';
import '../../services/pose_detector_service.dart';
import '../../widgets/skeleton_painter.dart';
import '../../widgets/power_gauge.dart';
import '../../widgets/combo_counter.dart';
import '../../widgets/rep_quality_popup.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/glow_button.dart';
import '../../models/workout_models.dart';
import '../../models/rep_quality.dart';
import '../../providers/workout_provider.dart';

// NEW: Import the rep counting system
import '../../services/workout_session.dart';
import '../../services/exercise_rules.dart';

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

  // GAMING FEATURES - Phase 1
  SkeletonState _skeletonState = SkeletonState.idle;
  double _chargeProgress = 0.0;
  double _powerGaugeFill = 0.0;
  
  // GAMING FEATURES - Phase 2: Combo System
  int _comboCount = 0;
  int _maxCombo = 0;
  RepQuality? _lastRepQuality;
  bool _showShatterAnimation = false;
  bool _showRepQualityPopup = false;
  
  // Screen shake animation
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadLockedWorkout();
    
    // Initialize screen shake controller
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_shakeController);
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _cameraController?.dispose();
    _poseDetectorService?.dispose();
    _session?.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _loadLockedWorkout() {
    final lockedWorkout = ref.read(lockedWorkoutProvider);
    setState(() {
      _lockedWorkout = lockedWorkout;
    });
  }

  /// Trigger screen shake effect (for perfect reps)
  void _triggerScreenShake() {
    // Generate random offset for shake (3-5px)
    final dx = (_random.nextDouble() * 10 - 5) / MediaQuery.of(context).size.width;
    final dy = (_random.nextDouble() * 10 - 5) / MediaQuery.of(context).size.height;
    
    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(dx, dy),
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));
    
    _shakeController
      ..reset()
      ..forward();
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
    if (_poseDetectorService == null || !_isWorkoutActive || _isResting) return;

    final landmarks = await _poseDetectorService!.detectPose(image);
    
    if (landmarks != null && mounted) {
      setState(() => _landmarks = landmarks);
      
      // NEW: Process pose through workout session
      _session?.processPose(landmarks);
      
      // Calculate charge progress and update skeleton state
      final currentAngle = _session?.currentAngle ?? 0;
      final currentExercise = _getCurrentExercise();
      
      if (currentExercise != null && ExerciseRules.hasRule(currentExercise.id)) {
        final rule = ExerciseRules.getRule(currentExercise.id)!;
        
        // Calculate how deep into the rep (0.0 = extended, 1.0 = fully contracted)
        final progress = _calculateChargeProgress(currentAngle, rule);
        
        // Update skeleton state based on rep phase
        final repPhase = _session?.phase ?? 'idle';
        
        setState(() {
          _chargeProgress = progress;
          _powerGaugeFill = progress;
          
          // Update skeleton state
          if (_skeletonState == SkeletonState.perfect) {
            // Don't interrupt perfect flash
            return;
          }
          
          if (repPhase == 'extending' || repPhase == 'contracting') {
            _skeletonState = SkeletonState.charging;
          } else {
            _skeletonState = SkeletonState.idle;
          }
          
          // Check for bad form
          if (_formScore > 0 && _formScore < 50) {
            _skeletonState = SkeletonState.error;
          }
        });
      }
      
      // Update UI with session state
      setState(() {
        _feedback = _session?.feedback ?? '';
        _formScore = _session?.formScore ?? 0;
      });
    }
  }

  Future<void> _startWorkout() async {
    if (_lockedWorkout == null || _lockedWorkout!.exercises.isEmpty) return;

    // Initialize camera
    await _initializeCamera();
    
    // Initialize workout session
    _session = WorkoutSession();
    await _session!.init();
    
    // Set up callbacks
    _session!.onRepCounted = (reps, score) {
      setState(() {
        _showRepFlash = true;
        _formScore = score;
        
        // GAMING: Flash skeleton to PERFECT state
        _skeletonState = SkeletonState.perfect;
      });
      
      // Trigger haptic and shake based on form score
      if (score >= 85) {
        // PERFECT REP
        HapticHelper.perfectRepHaptic();
        _triggerScreenShake();
      } else if (score >= 60) {
        // GOOD REP
        HapticHelper.goodRepHaptic();
      } else {
        // MISSED REP
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

    // GAMING: Combo callbacks
    _session!.onComboChange = (combo, maxCombo) {
      setState(() {
        final oldCombo = _comboCount;
        _comboCount = combo;
        _maxCombo = maxCombo;
        
        // Check for combo break
        if (oldCombo >= 3 && combo == 0) {
          _showShatterAnimation = true;
          HapticHelper.comboBreakHaptic();
          
          // Hide shatter after animation
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _showShatterAnimation = false);
          });
        }
        
        // Check for milestones (5X, 10X)
        if (combo == 5 || combo == 10) {
          HapticHelper.comboMilestoneHaptic();
        }
      });
    };
    
    _session!.onRepQuality = (quality, score) {
      setState(() {
        _lastRepQuality = quality;
        _showRepQualityPopup = true;
      });
      
      // Hide popup after animation
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showRepQualityPopup = false);
      });
    };

    setState(() {
      _isWorkoutActive = true;
      _currentExerciseIndex = 0;
    });

    // Start first exercise
    _startCurrentExercise();
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
        
        // Reset gaming state for new exercise
        _skeletonState = SkeletonState.idle;
        _chargeProgress = 0.0;
        _powerGaugeFill = 0.0;
      });
      _startRest(); // Rest between exercises
    } else {
      // Workout complete!
      _endWorkout();
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
    
    // Start next set or next exercise
    if ((_session?.currentSet ?? 0) < (_session?.targetSets ?? 0)) {
      _session?.startNextSet();
    } else {
      _startCurrentExercise();
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

  /// Get current exercise from locked workout
  WorkoutExercise? _getCurrentExercise() {
    if (_lockedWorkout == null || 
        _currentExerciseIndex >= _lockedWorkout!.exercises.length) {
      return null;
    }
    return _lockedWorkout!.exercises[_currentExerciseIndex];
  }

  /// Calculate charge progress (0.0 to 1.0) based on current angle
  /// 0.0 = fully extended (start), 1.0 = fully contracted (bottom/deepest)
  double _calculateChargeProgress(double currentAngle, ExerciseRule rule) {
    final extendedAngle = rule.extendedAngle;
    final contractedAngle = rule.contractedAngle;
    
    // Clamp angle to valid range
    final clampedAngle = currentAngle.clamp(
      math.min(contractedAngle, extendedAngle),
      math.max(contractedAngle, extendedAngle),
    );
    
    // Calculate progress
    // If extended > contracted (e.g., squat: 170° → 90°)
    if (extendedAngle > contractedAngle) {
      return 1.0 - ((clampedAngle - contractedAngle) / (extendedAngle - contractedAngle));
    } else {
      // If extended < contracted (e.g., bicep curl: 45° → 160°)
      return (clampedAngle - extendedAngle) / (contractedAngle - extendedAngle);
    }
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

    return SlideTransition(
      position: _shakeAnimation,
      child: Stack(
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

        // GAMING: Combo Counter - Top left
        Positioned(
          top: 100,
          left: 16,
          child: ComboCounter(
            comboCount: _comboCount,
            maxCombo: _maxCombo,
          ),
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

        // Form feedback - Just above finish button
        if (_feedback.isNotEmpty)
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _formScore >= 80 
                    ? AppColors.cyberLime.withOpacity(0.9)
                    : AppColors.neonCrimson.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _feedback,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),

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
    )
  };
