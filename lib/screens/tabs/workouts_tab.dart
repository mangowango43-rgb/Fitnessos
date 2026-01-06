import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workout_data.dart';
import '../../models/workout_models.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/exercise_animation_widget.dart';
import '../../providers/workout_provider.dart';
import '../workout_editor_screen.dart';
import '../home_screen.dart' show TabNavigator;

class WorkoutsTab extends ConsumerStatefulWidget {
  const WorkoutsTab({super.key});

  @override
  ConsumerState<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends ConsumerState<WorkoutsTab> {
  String _selectedMode = 'gym'; // 'gym' or 'home'
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    if (_selectedCategory == null) {
      return _buildMainScreen();
    } else {
      return _buildPresetList();
    }
  }

  Widget _buildMainScreen() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WORKOUTS',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyberLime,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lock a workout to start training',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.white50,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // GYM/HOME Toggle
        _buildModeToggle(),
        
        // Category Cards
        Expanded(
          child: _buildCategoryCards(),
        ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(4),
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
          Expanded(
            child: _buildToggleButton('GYM', 'gym'),
          ),
          Expanded(
            child: _buildToggleButton('HOME', 'home'),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, String mode) {
    final isActive = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
          _selectedCategory = null;
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cyberLime : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.cyberLime.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isActive ? Colors.black : AppColors.white60,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCards() {
    final categories = _getCategoriesForMode();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedMode == 'gym' ? 'GYM WORKOUTS' : 'HOME WORKOUTS',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedMode == 'gym'
                ? 'Build strength with equipment'
                : 'Train anywhere, anytime',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.white50,
            ),
          ),
          const SizedBox(height: 24),
          ...categories.map((category) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCategoryCard(category),
          )),
        ],
      ),
    );
  }

  List<Map<String, String>> _getCategoriesForMode() {
    if (_selectedMode == 'gym') {
      return [
        {
          'id': 'muscle_splits',
          'name': 'MUSCLE SPLITS',
          'icon': '💪',
          'desc': 'Target specific muscle groups',
        },
        {
          'id': 'muscle_groupings',
          'name': 'MUSCLE GROUPINGS',
          'icon': '🎯',
          'desc': 'Pre-built workout combinations',
        },
        {
          'id': 'gym_circuits',
          'name': 'GYM CIRCUITS',
          'icon': '⚡',
          'desc': 'High-intensity timed workouts',
        },
        {
          'id': 'booty_builder',
          'name': 'BOOTY BUILDER',
          'icon': '🍑',
          'desc': "Women's glute-focused workouts",
        },
      ];
    } else {
      return [
        {
          'id': 'bodyweight_basics',
          'name': 'BODYWEIGHT BASICS',
          'icon': '🏠',
          'desc': 'No equipment needed',
        },
        {
          'id': 'hiit_circuits',
          'name': 'HIIT CIRCUITS',
          'icon': '⚡',
          'desc': 'High intensity, no equipment',
        },
        {
          'id': 'home_booty',
          'name': 'HOME BOOTY',
          'icon': '🍑',
          'desc': 'Glute workouts at home',
        },
        {
          'id': 'recovery',
          'name': 'RECOVERY & MOBILITY',
          'icon': '🧘',
          'desc': 'Stretching and mobility work',
        },
      ];
    }
  }

  Widget _buildCategoryCard(Map<String, String> category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category['id'];
        });
        HapticFeedback.lightImpact();
      },
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Text(
              category['icon']!,
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name']!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['desc']!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.white40,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetList() {
    final presets = _getPresetsForCategory();

    return SafeArea(
      child: Column(
        children: [
          // Header with back button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                  });
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
                child: Text(
                  _getCategoryName(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Preset cards
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
            child: Column(
              children: presets.map((preset) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPresetCard(preset),
              )).toList(),
            ),
          ),
        ),
        ],
      ),
    );
  }

  List<WorkoutPreset> _getPresetsForCategory() {
    switch (_selectedCategory) {
      // GYM MODE
      case 'muscle_splits':
        return WorkoutData.gymMuscleSplits;
      case 'muscle_groupings':
        return WorkoutData.gymMuscleGroupings;
      case 'gym_circuits':
        return WorkoutData.gymCircuits;
      case 'booty_builder':
        return WorkoutData.gymBootyBuilder;
      // HOME MODE
      case 'bodyweight_basics':
        return WorkoutData.homeBodyweightBasics;
      case 'hiit_circuits':
        return WorkoutData.homeHIITCircuits;
      case 'home_booty':
        return WorkoutData.homeBooty;
      case 'recovery':
        return WorkoutData.homeRecovery;
      default:
        return [];
    }
  }

  String _getCategoryName() {
    final categories = _getCategoriesForMode();
    final category = categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => {'name': 'WORKOUTS'},
    );
    return category['name']!;
  }

  Widget _buildPresetCard(WorkoutPreset preset) {
    final includedExercises = preset.exercises.where((e) => e.included).toList();
    
    return GlassmorphismCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preset name and icon
          Row(
            children: [
              if (preset.icon != null) ...[
                Text(
                  preset.icon!,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  preset.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Exercise count and duration
          Row(
            children: [
              _buildInfoBadge('${includedExercises.length} exercises'),
              const SizedBox(width: 8),
              _buildInfoBadge('~${preset.estimatedMinutes} min'),
              if (preset.isCircuit && preset.rounds != null) ...[
                const SizedBox(width: 8),
                _buildInfoBadge('${preset.rounds} rounds'),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Exercise list with animations (ONE PER EXERCISE)
          ...includedExercises.map((ex) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Exercise Animation (left)
                ExerciseAnimationWidget(
                  exerciseId: ex.id,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                // Exercise Details (right)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.isCircuit
                            ? '${ex.timeSeconds}s work / ${ex.restSeconds}s rest'
                            : '${ex.sets} sets × ${ex.reps} reps',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 20),

          // LOCK and EDIT buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GlowButton(
                  text: '🔒 LOCK',
                  onPressed: () => _lockWorkout(preset),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _editWorkout(preset),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.cyberLime,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '✏️ EDIT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cyberLime,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.white10,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.white70,
        ),
      ),
    );
  }

  Future<void> _lockWorkout(WorkoutPreset preset) async {
    HapticFeedback.mediumImpact();
    
    // Lock the workout
    await ref.read(lockedWorkoutProvider.notifier).lockWorkout(preset);
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: AppColors.cyberLime),
              const SizedBox(width: 12),
              Text(
                'Workout Locked! 🔒',
                style: const TextStyle(
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
      
      // Navigate to home tab to show the locked workout in hero card
      final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
      if (navigator != null) {
        (navigator as dynamic).changeTab(0); // Home tab
      }
    }
  }

  Future<void> _editWorkout(WorkoutPreset preset) async {
    HapticFeedback.lightImpact();
    
    // Navigate to editor
    final result = await Navigator.push<WorkoutPreset>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutEditorScreen(preset: preset),
      ),
    );
    
    // If user locked from editor, result will be returned
    if (result != null) {
      // Already locked in editor screen
    }
  }
}
