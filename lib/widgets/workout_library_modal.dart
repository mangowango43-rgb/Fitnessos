import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../models/workout_data.dart';
import '../screens/custom_workouts_screen.dart';

/// Modal for selecting a workout from the library
class WorkoutLibraryModal extends StatefulWidget {
  const WorkoutLibraryModal({super.key});

  @override
  State<WorkoutLibraryModal> createState() => _WorkoutLibraryModalState();
}

class _WorkoutLibraryModalState extends State<WorkoutLibraryModal> {
  String _selectedCategory = 'gym';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose Workout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Category tabs
            _buildCategoryTabs(),

            const SizedBox(height: 16),

            // Workout list
            Expanded(
              child: _buildWorkoutList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'id': 'gym', 'label': 'GYM TRAINING', 'icon': '💪'},
      {'id': 'home', 'label': 'HOME TRAINING', 'icon': '🏠'},
      {'id': 'custom', 'label': 'CUSTOM', 'icon': '✨'},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['id'] as String;
              });
              HapticFeedback.selectionClick();
              
              // If CUSTOM is selected, navigate to custom workouts screen
              if (category['id'] == 'custom') {
                Navigator.pop(context); // Close modal first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomWorkoutsScreen(),
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.electricCyan, AppColors.cyberLime],
                      )
                    : null,
                color: isSelected ? null : AppColors.white5,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.electricCyan : AppColors.white10,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    category['icon'] as String,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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

  Widget _buildWorkoutList() {
    final workouts = _getWorkoutsForCategory();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return _buildWorkoutCard(workout);
      },
    );
  }

  List<Map<String, dynamic>> _getWorkoutsForCategory() {
    final List<Map<String, dynamic>> allWorkouts = [];

    // GYM TRAINING: Show all gym presets (muscle splits, circuits, training splits)
    if (_selectedCategory == 'gym') {
      // Add muscle splits
      WorkoutData.muscleSplits.forEach((key, exercises) {
        allWorkouts.add({
          'type': 'split',
          'id': key,
          'name': WorkoutData.muscleSplitInfo[key] ?? key.toUpperCase(),
          'exercises': exercises,
          'duration': '${exercises.length * 3} min',
          'difficulty': 'Intermediate',
        });
      });

      // Add circuits
      for (final circuit in WorkoutData.circuits) {
        allWorkouts.add({
          'type': 'circuit',
          'id': circuit.id,
          'name': circuit.name,
          'exercises': circuit.exercises.map((e) => e.name).toList(),
          'duration': circuit.duration,
          'difficulty': circuit.difficulty,
        });
      }

      // Add training splits
      for (final split in WorkoutData.trainingSplits) {
        for (final day in split.days) {
          allWorkouts.add({
            'type': 'training',
            'id': '${split.id}_${day.name.toLowerCase().replaceAll(' ', '_')}',
            'name': day.name,
            'exercises': day.exercises,
            'duration': '${day.exercises.length * 4} min',
            'difficulty': 'Advanced',
          });
        }
      }
    }

    // HOME TRAINING: Show all home/bodyweight presets
    if (_selectedCategory == 'home') {
      // Add at-home exercises as workouts
      final homeExercises = WorkoutData.atHomeExercises;
      allWorkouts.add({
        'type': 'home',
        'id': 'home_fullbody',
        'name': 'HOME FULL BODY',
        'exercises': homeExercises.take(8).toList(),
        'duration': '30 min',
        'difficulty': 'Beginner',
      });

      // Add bodyweight circuits
      allWorkouts.add({
        'type': 'home',
        'id': 'home_cardio',
        'name': 'HOME CARDIO BLAST',
        'exercises': ['Burpees', 'Mountain Climbers', 'Jump Squats', 'High Knees'],
        'duration': '20 min',
        'difficulty': 'Intermediate',
      });

      allWorkouts.add({
        'type': 'home',
        'id': 'home_strength',
        'name': 'HOME STRENGTH',
        'exercises': ['Push-ups', 'Pull-ups', 'Planks', 'Lunges', 'Squats'],
        'duration': '25 min',
        'difficulty': 'Beginner',
      });
    }

    // CUSTOM: No workouts shown here, handled by navigation
    if (_selectedCategory == 'custom') {
      // Empty - custom tab navigates to CustomWorkoutsScreen
    }

    return allWorkouts;
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final exerciseCount = workout['exercises'] is List ? (workout['exercises'] as List).length : 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, workout);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.white5,
              AppColors.white5.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white10),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.electricCyan, AppColors.cyberLime],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.list,
                        '$exerciseCount exercises',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.timer_outlined,
                        workout['duration'] as String,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.cyberLime,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.white50),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.white50,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

