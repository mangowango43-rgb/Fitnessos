import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_data.dart';
import '../models/workout_models.dart';
import '../utils/app_colors.dart';
import '../widgets/exercise_animation_widget.dart';
import '../widgets/glow_button.dart';
import '../providers/workout_provider.dart';
import '../services/storage_service.dart';

class CustomWorkoutsScreen extends ConsumerStatefulWidget {
  const CustomWorkoutsScreen({super.key});

  @override
  ConsumerState<CustomWorkoutsScreen> createState() => _CustomWorkoutsScreenState();
}

class _CustomWorkoutsScreenState extends ConsumerState<CustomWorkoutsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _workoutNameController = TextEditingController(text: 'My Custom Workout');
  
  String _selectedCategory = 'all';
  List<Exercise> _selectedExercises = [];
  Map<String, ExerciseSettings> _exerciseSettings = {};
  
  // Get all exercises from WorkoutData
  List<Exercise> get _allExercises {
    final List<Exercise> exercises = [];
    WorkoutData.muscleSplits.forEach((category, categoryExercises) {
      exercises.addAll(categoryExercises);
    });
    exercises.addAll(WorkoutData.atHomeExercises);
    exercises.addAll(WorkoutData.cardioExercises);
    
    // Remove duplicates by id
    final Map<String, Exercise> uniqueExercises = {};
    for (var exercise in exercises) {
      uniqueExercises[exercise.id] = exercise;
    }
    
    return uniqueExercises.values.toList();
  }
  
  List<Exercise> get _filteredExercises {
    List<Exercise> exercises = _allExercises;
    
    // Filter by category
    if (_selectedCategory != 'all') {
      if (_selectedCategory == 'upper') {
        exercises = exercises.where((e) => 
          WorkoutData.muscleSplits['chest']!.any((c) => c.id == e.id) ||
          WorkoutData.muscleSplits['back']!.any((c) => c.id == e.id) ||
          WorkoutData.muscleSplits['shoulders']!.any((c) => c.id == e.id) ||
          WorkoutData.muscleSplits['arms']!.any((c) => c.id == e.id)
        ).toList();
      } else if (_selectedCategory == 'lower') {
        // Fix: Only reference 'legs' - glutes don't exist as separate category
        exercises = exercises.where((e) => 
          WorkoutData.muscleSplits['legs']!.any((c) => c.id == e.id)
        ).toList();
      } else if (_selectedCategory == 'core') {
        // Fix: Use 'core' key which exists in muscleSplits
        exercises = exercises.where((e) => 
          WorkoutData.muscleSplits['core']!.any((c) => c.id == e.id)
        ).toList();
      } else if (_selectedCategory == 'cardio') {
        exercises = exercises.where((e) => 
          WorkoutData.cardioExercises.any((c) => c.id == e.id)
        ).toList();
      }
    }
    
    // Filter by search
    if (_searchController.text.isNotEmpty) {
      exercises = exercises.where((e) => 
        e.name.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }
    
    return exercises;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _workoutNameController.dispose();
    super.dispose();
  }

  void _addExercise(Exercise exercise) {
    if (!_selectedExercises.any((e) => e.id == exercise.id)) {
      setState(() {
        _selectedExercises.add(exercise);
        _exerciseSettings[exercise.id] = ExerciseSettings(
          sets: 3,
          reps: 10,
          restSeconds: 60,
        );
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _removeExercise(Exercise exercise) {
    setState(() {
      _selectedExercises.removeWhere((e) => e.id == exercise.id);
      _exerciseSettings.remove(exercise.id);
    });
    HapticFeedback.lightImpact();
  }

  void _updateExerciseSettings(String exerciseId, ExerciseSettings settings) {
    setState(() {
      _exerciseSettings[exerciseId] = settings;
    });
  }

  Future<void> _commitWorkout() async {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: AppColors.neonCrimson,
        ),
      );
      return;
    }

    // Ask if user wants to save the workout
    final shouldSave = await _showSaveDialog();

    HapticFeedback.heavyImpact();

    // Create WorkoutPreset from custom workout
    final customPreset = WorkoutPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _workoutNameController.text.isEmpty ? 'My Custom Workout' : _workoutNameController.text,
      category: 'Custom',
      subcategory: 'custom',
      isCircuit: false,
      duration: '${_selectedExercises.length * 5} min', // Rough estimate
      exercises: _selectedExercises.map((e) {
        final settings = _exerciseSettings[e.id]!;
        return WorkoutExercise(
          id: e.id,
          name: e.name,
          sets: settings.sets,
          reps: settings.reps,
          restSeconds: settings.restSeconds,
        );
      }).toList(),
    );

    // Save if user chose to
    if (shouldSave == true) {
      final storage = await StorageService.getInstance();
      await storage.saveCustomWorkout(customPreset);
    }

    // Commit the workout
    await ref.read(committedWorkoutProvider.notifier).commitWorkout(customPreset);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.cyberLime),
              const SizedBox(width: 12),
              Text(
                shouldSave == true 
                    ? 'Custom Workout Saved & Committed! ✅'
                    : 'Custom Workout Committed! ✅',
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
        ),
      );

      // Navigate back to workouts tab (will auto-switch to home)
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showSaveDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.cyberLime.withOpacity(0.3), width: 2),
        ),
        title: const Text(
          'Save Workout?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Do you want to save this workout to use again later?',
          style: TextStyle(
            color: AppColors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'NO, JUST COMMIT',
              style: TextStyle(
                color: AppColors.white50,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.cyberLime.withOpacity(0.2),
            ),
            child: const Text(
              'YES, SAVE IT',
              style: TextStyle(
                color: AppColors.cyberLime,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildCategoryFilter(),
                _buildSearchBar(),
                Expanded(
                  child: _buildExerciseLibrary(),
                ),
              ],
            ),
          ),

          // Floating workout builder panel
          if (_selectedExercises.isNotEmpty)
            _buildWorkoutBuilderPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CUSTOM WORKOUTS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.cyberLime,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create your perfect workout',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.white50,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedExercises.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_selectedExercises.length} exercises • Est. ${_calculateCalories()} cal',
                      style: const TextStyle(
                        color: AppColors.cyberLime,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Load saved workouts button
          IconButton(
            onPressed: _showSavedWorkouts,
            icon: const Icon(Icons.folder_open, color: AppColors.cyberLime, size: 28),
            tooltip: 'My Saved Workouts',
          ),
        ],
      ),
    );
  }

  Future<void> _showSavedWorkouts() async {
    final storage = await StorageService.getInstance();
    final savedWorkouts = storage.getCustomWorkoutsList();

    if (!mounted) return;

    if (savedWorkouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved workouts yet!'),
          backgroundColor: AppColors.white10,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MY SAVED WORKOUTS',
                    style: TextStyle(
                      color: AppColors.cyberLime,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // List of saved workouts
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: savedWorkouts.length,
                itemBuilder: (context, index) {
                  final workout = savedWorkouts[index];
                  return _buildSavedWorkoutCard(workout);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedWorkoutCard(WorkoutPreset workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _loadWorkout(workout);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.cyberLime.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.cyberLime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${workout.exercises.length} exercises',
                        style: const TextStyle(
                          color: AppColors.white50,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final storage = await StorageService.getInstance();
                    await storage.deleteCustomWorkout(workout.id);
                    Navigator.pop(context);
                    _showSavedWorkouts();
                  },
                  icon: const Icon(Icons.delete_outline, color: AppColors.neonCrimson),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _loadWorkout(WorkoutPreset workout) {
    setState(() {
      _workoutNameController.text = workout.name;
      _selectedExercises.clear();
      _exerciseSettings.clear();
      
      for (final exercise in workout.exercises) {
        // Find the matching exercise from allExercises
        final matchedExercise = _allExercises.firstWhere(
          (e) => e.id == exercise.id,
          orElse: () => Exercise(
            id: exercise.id,
            name: exercise.name,
            difficulty: 'intermediate',
            equipment: 'weights',
          ),
        );
        
        _selectedExercises.add(matchedExercise);
        _exerciseSettings[exercise.id] = ExerciseSettings(
          sets: exercise.sets,
          reps: exercise.reps,
          restSeconds: exercise.restSeconds ?? 60,
        );
      }
    });
    
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded: ${workout.name}'),
        backgroundColor: AppColors.cyberLime,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'name': 'All', 'icon': '💯'},
      {'id': 'upper', 'name': 'Upper', 'icon': '💪'},
      {'id': 'lower', 'name': 'Lower', 'icon': '🦵'},
      {'id': 'core', 'name': 'Core', 'icon': '🔥'},
      {'id': 'cardio', 'name': 'Cardio', 'icon': '🏃'},
    ];

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category['id']!);
              HapticFeedback.selectionClick();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cyberLime.withOpacity(0.2) : AppColors.white5,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.cyberLime : AppColors.white10,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category['icon']!,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['name']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.cyberLime : AppColors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search exercises...',
          hintStyle: TextStyle(color: AppColors.white40),
          icon: Icon(Icons.search, color: AppColors.white40),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildExerciseLibrary() {
    final exercises = _filteredExercises;

    if (exercises.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: AppColors.white30),
            SizedBox(height: 16),
            Text(
              'No exercises found',
              style: TextStyle(color: AppColors.white50, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        _selectedExercises.isEmpty ? 20 : 300, // Extra padding if panel is shown
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isSelected = _selectedExercises.any((e) => e.id == exercise.id);

        return _buildExerciseCard(exercise, isSelected);
      },
    );
  }

  Widget _buildExerciseCard(Exercise exercise, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.cyberLime : AppColors.white10,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isSelected) {
              _removeExercise(exercise);
            } else {
              _addExercise(exercise);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Exercise GIF preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: AppColors.white10,
                    child: ExerciseAnimationWidget(
                      exerciseId: exercise.id,
                      width: 60,
                      height: 60,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildBadge(exercise.equipment, AppColors.electricCyan),
                          const SizedBox(width: 8),
                          _buildBadge(exercise.difficulty, AppColors.white40),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Add/Remove button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cyberLime.withOpacity(0.2) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.cyberLime : AppColors.white30,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.add,
                    color: isSelected ? AppColors.cyberLime : AppColors.white30,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildWorkoutBuilderPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.45, // Increased from 0.35 to make it more visible
      minChildSize: 0.20, // Increased from 0.15
      maxChildSize: 0.85, // Increased from 0.7 for better expansion
      snap: true,
      snapSizes: const [0.20, 0.45, 0.85], // Snap points for smooth interaction
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a1a1a),
                Colors.black,
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Workout name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _workoutNameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Workout Name',
                    hintStyle: TextStyle(color: AppColors.white40),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Exercise list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _selectedExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _selectedExercises[index];
                    final settings = _exerciseSettings[exercise.id]!;

                    return _buildSelectedExerciseItem(exercise, settings, index);
                  },
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.white10),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_selectedExercises.length} exercises',
                          style: const TextStyle(
                            color: AppColors.white50,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedExercises.clear();
                              _exerciseSettings.clear();
                            });
                          },
                          child: const Text(
                            'CLEAR ALL',
                            style: TextStyle(
                              color: AppColors.white40,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlowButton(
                      text: '✅ COMMIT WORKOUT',
                      onPressed: _commitWorkout,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedExerciseItem(Exercise exercise, ExerciseSettings settings, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${index + 1}.',
                style: const TextStyle(
                  color: AppColors.cyberLime,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeExercise(exercise),
                icon: const Icon(Icons.close, color: AppColors.white40, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSettingControl(
                  'Sets',
                  settings.sets,
                  (val) => _updateExerciseSettings(
                    exercise.id,
                    settings.copyWith(sets: val),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSettingControl(
                  'Reps',
                  settings.reps,
                  (val) => _updateExerciseSettings(
                    exercise.id,
                    settings.copyWith(reps: val),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSettingControl(
                  'Rest',
                  settings.restSeconds ~/ 15, // Simplified to 15s increments
                  (val) => _updateExerciseSettings(
                    exercise.id,
                    settings.copyWith(restSeconds: val * 15),
                  ),
                  suffix: 's',
                  multiplier: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingControl(
    String label,
    int value,
    Function(int) onChanged, {
    String suffix = '',
    int multiplier = 1,
  }) {
    final displayValue = value * multiplier;
    final controller = TextEditingController(text: displayValue.toString());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white50,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cyberLime.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cyberLime, width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.cyberLime,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              suffix: Text(
                suffix,
                style: const TextStyle(
                  color: AppColors.cyberLime,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onChanged: (text) {
              final parsed = int.tryParse(text);
              if (parsed != null && parsed > 0) {
                final actualValue = parsed ~/ multiplier;
                if (actualValue != value) {
                  onChanged(actualValue);
                  HapticFeedback.selectionClick();
                }
              }
            },
            onSubmitted: (text) {
              final parsed = int.tryParse(text) ?? (value * multiplier);
              final clamped = parsed < 1 ? 1 : parsed;
              controller.text = clamped.toString();
              onChanged(clamped ~/ multiplier);
            },
          ),
        ),
      ],
    );
  }

  int _calculateCalories() {
    int total = 0;
    for (final exercise in _selectedExercises) {
      final settings = _exerciseSettings[exercise.id] ?? 
          ExerciseSettings(sets: 3, reps: 10, restSeconds: 60);
      total += settings.sets * _getCaloriesPerSet(exercise.name);
    }
    return total;
  }

  int _getCaloriesPerSet(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('squat') || lower.contains('deadlift') || 
        lower.contains('burpee')) return 12;
    if (lower.contains('press') || lower.contains('row') || 
        lower.contains('pull')) return 9;
    if (lower.contains('curl') || lower.contains('extension')) return 5;
    return 7;
  }
}

class ExerciseSettings {
  final int sets;
  final int reps;
  final int restSeconds;

  ExerciseSettings({
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  ExerciseSettings copyWith({
    int? sets,
    int? reps,
    int? restSeconds,
  }) {
    return ExerciseSettings(
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }
}

