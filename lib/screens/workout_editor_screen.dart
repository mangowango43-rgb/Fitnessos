import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/workout_models.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/glow_button.dart';
import '../providers/workout_provider.dart';
import '../services/exercise_animation_database.dart';

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  final WorkoutPreset preset;

  const WorkoutEditorScreen({
    super.key,
    required this.preset,
  });

  @override
  ConsumerState<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late List<WorkoutExercise> _exercises;
  late int _rounds;

  @override
  void initState() {
    super.initState();
    // Create mutable copies of exercises
    _exercises = widget.preset.exercises.map((e) => e).toList();
    _rounds = widget.preset.rounds ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final includedCount = _exercises.where((e) => e.included).length;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(includedCount),
            
            // Circuit rounds control (if applicable)
            if (widget.preset.isCircuit) _buildRoundsControl(),

            // Exercise list
            Expanded(
              child: _buildExerciseList(),
            ),

            // Lock button at bottom
            _buildLockButton(includedCount),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int includedCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white5,
        border: Border(
          bottom: BorderSide(
            color: AppColors.white10,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EDIT WORKOUT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white50,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.preset.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cyberLime.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cyberLime.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '$includedCount selected',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.cyberLime,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundsControl() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white10,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.repeat,
            color: AppColors.electricCyan,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'ROUNDS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          _buildStepper(
            value: _rounds,
            onDecrement: () {
              if (_rounds > 1) {
                setState(() => _rounds--);
                HapticFeedback.lightImpact();
              }
            },
            onIncrement: () {
              if (_rounds < 10) {
                setState(() => _rounds++);
                HapticFeedback.lightImpact();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        return _buildExerciseCard(_exercises[index], index);
      },
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise, int index) {
    final gifUrl = ExerciseAnimationDatabase.getAnimationUrl(exercise.id);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox, Exercise GIF and name
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _exercises[index] = exercise.copyWith(
                        included: !exercise.included,
                      );
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: exercise.included
                          ? AppColors.cyberLime
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: exercise.included
                            ? AppColors.cyberLime
                            : AppColors.white30,
                        width: 2,
                      ),
                    ),
                    child: exercise.included
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.black,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Exercise GIF
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: exercise.included
                          ? AppColors.cyberLime.withOpacity(0.5)
                          : AppColors.white20,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: gifUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.white10,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.cyberLime,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.white10,
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppColors.white40,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Text(
                    exercise.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: exercise.included
                          ? Colors.white
                          : AppColors.white40,
                    ),
                  ),
                ),
              ],
            ),
            
            if (exercise.included) ...[
              const SizedBox(height: 16),
              
              // Sets and Reps controls
              if (!widget.preset.isCircuit) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildControlRow(
                        label: 'SETS',
                        value: exercise.sets,
                        onDecrement: () {
                          if (exercise.sets > 1) {
                            setState(() {
                              _exercises[index] = exercise.copyWith(
                                sets: exercise.sets - 1,
                              );
                            });
                            HapticFeedback.lightImpact();
                          }
                        },
                        onIncrement: () {
                          if (exercise.sets < 10) {
                            setState(() {
                              _exercises[index] = exercise.copyWith(
                                sets: exercise.sets + 1,
                              );
                            });
                            HapticFeedback.lightImpact();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildControlRow(
                        label: 'REPS',
                        value: exercise.reps,
                        onDecrement: () {
                          if (exercise.reps > 1) {
                            setState(() {
                              _exercises[index] = exercise.copyWith(
                                reps: exercise.reps - 1,
                              );
                            });
                            HapticFeedback.lightImpact();
                          }
                        },
                        onIncrement: () {
                          if (exercise.reps < 50) {
                            setState(() {
                              _exercises[index] = exercise.copyWith(
                                reps: exercise.reps + 1,
                              );
                            });
                            HapticFeedback.lightImpact();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              
              // Time and Rest controls for circuits
              if (widget.preset.isCircuit) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildControlRow(
                        label: 'WORK',
                        value: exercise.timeSeconds ?? 30,
                        suffix: 's',
                        onDecrement: () {
                          final current = exercise.timeSeconds ?? 30;
                          if (current > 10) {
                            setState(() {
                              _exercises[index] = exercise.copyWith(
                                timeSeconds: current - 5,
                              );
                            });
                            HapticFeedback.lightImpact();
                          }
                        },
                        onIncrement: () {
                          final current = exercise.timeSeconds ?? 30;
                          if (current < 120) {
                            setState(() {
                              _exercises[index] = exercise.copyWith(
                                timeSeconds: current + 5,
                              );
                            });
                            HapticFeedback.lightImpact();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildControlRow(
                        label: 'REST',
                        value: exercise.restSeconds ?? 15,
                        suffix: 's',
                        onDecrement: () {
                          final current = exercise.restSeconds ?? 15;
                          if (current > 5) {
                            setState(() {
                              _exercises[index] = exercise.copyWith(
                                restSeconds: current - 5,
                              );
                            });
                            HapticFeedback.lightImpact();
                          }
                        },
                        onIncrement: () {
                          final current = exercise.restSeconds ?? 15;
                          if (current < 120) {
                            setState(() {
                              _exercises[index] = exercise.copyWith(
                                restSeconds: current + 5,
                              );
                            });
                            HapticFeedback.lightImpact();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlRow({
    required String label,
    required int value,
    String? suffix,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.white50,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStepperButton(Icons.remove, onDecrement),
            Expanded(
              child: Center(
                child: Text(
                  '$value${suffix ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            _buildStepperButton(Icons.add, onIncrement),
          ],
        ),
      ],
    );
  }

  Widget _buildStepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.white20,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.cyberLime,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStepper({
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepperButton(Icons.remove, onDecrement),
        Container(
          width: 60,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        _buildStepperButton(Icons.add, onIncrement),
      ],
    );
  }

  Widget _buildLockButton(int includedCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white5,
        border: Border(
          top: BorderSide(
            color: AppColors.white10,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: GlowButton(
          text: '🔒 LOCK WORKOUT',
          onPressed: includedCount > 0 ? _lockCustomWorkout : () {},
          glowColor: includedCount > 0 ? AppColors.cyberLime : AppColors.white20,
          backgroundColor: includedCount > 0 ? AppColors.cyberLime : AppColors.white20,
          textColor: includedCount > 0 ? Colors.black : AppColors.white40,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Future<void> _lockCustomWorkout() async {
    HapticFeedback.mediumImpact();

    // Create custom preset with edited exercises and rounds
    final customPreset = widget.preset.copyWith(
      exercises: _exercises,
      rounds: widget.preset.isCircuit ? _rounds : null,
    );

    // Lock the workout
    await ref.read(lockedWorkoutProvider.notifier).lockWorkout(
      customPreset,
      customExercises: _exercises,
    );

    if (mounted) {
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: AppColors.cyberLime),
              const SizedBox(width: 12),
              const Text(
                'Custom Workout Locked! 🔒',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.white10,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.cyberLime.withOpacity(0.3)),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Pop back to workouts tab
      Navigator.pop(context, customPreset);
    }
  }
}

