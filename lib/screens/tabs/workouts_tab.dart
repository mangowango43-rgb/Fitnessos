import 'package:flutter/material.dart';
import '../../models/workout_data.dart';
import '../../utils/app_colors.dart';
import '../../widgets/glassmorphism_card.dart';

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  String? _selectedCategory;
  String? _selectedSubcategory;

  @override
  Widget build(BuildContext context) {
    if (_selectedCategory == null) {
      return _buildCategorySelection();
    }

    if (_selectedCategory == 'splits' && _selectedSubcategory == null) {
      return _buildMuscleSplitSelection();
    }

    if (_selectedCategory == 'circuits') {
      return _buildCircuitsList();
    }

    if (_selectedCategory == 'training_splits') {
      return _buildTrainingSplitsList();
    }

    if (_selectedCategory == 'at_home') {
      return _buildExercisesList(WorkoutData.atHomeExercises, 'AT HOME');
    }

    if (_selectedCategory == 'cardio') {
      return _buildExercisesList(WorkoutData.cardioExercises, 'CARDIO ONLY');
    }

    if (_selectedCategory == 'splits' && _selectedSubcategory != null) {
      final exercises = WorkoutData.muscleSplits[_selectedSubcategory] ?? [];
      final title = WorkoutData.muscleSplitInfo[_selectedSubcategory] ?? 'EXERCISES';
      return _buildExercisesList(exercises, title);
    }

    return _buildCategorySelection();
  }

  Widget _buildCategorySelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'CHOOSE MODE',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AppColors.cyberLime,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your training style',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.white50,
            ),
          ),
          const SizedBox(height: 32),
          ...WorkoutData.categories.map((category) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCategoryCard(category),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(WorkoutCategory category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category.id;
          _selectedSubcategory = null;
        });
      },
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Text(
              category.icon,
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.description,
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

  Widget _buildMuscleSplitSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedCategory = null),
                child: const Text(
                  '← Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.white50,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'MUSCLE SPLITS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ...WorkoutData.muscleSplitInfo.entries.map((entry) {
            final exercises = WorkoutData.muscleSplits[entry.key] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => setState(() => _selectedSubcategory = entry.key),
                child: GlassmorphismCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        entry.value.split(' ').last,
                        style: const TextStyle(fontSize: 50),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.split(' ').first,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${exercises.length} exercises',
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
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildExercisesList(List<Exercise> exercises, String title) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  if (_selectedSubcategory != null) {
                    _selectedSubcategory = null;
                  } else {
                    _selectedCategory = null;
                  }
                }),
                child: const Text(
                  '← Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.white50,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...exercises.map((exercise) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                // Add to workout logic
              },
              child: GlassmorphismCard(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cyberLime.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.cyberLime,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exercise.difficulty.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _getDifficultyColor(exercise.difficulty),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.white30,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCircuitsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedCategory = null),
                child: const Text(
                  '← Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.white50,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'CIRCUITS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...WorkoutData.circuits.map((circuit) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () {
                // Start circuit
              },
              child: GlassmorphismCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          circuit.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(circuit.difficulty).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            circuit.difficulty.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _getDifficultyColor(circuit.difficulty),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCircuitBadge('⏱️ ${circuit.duration}'),
                        const SizedBox(width: 8),
                        _buildCircuitBadge('${circuit.exercises.length} exercises'),
                        const SizedBox(width: 8),
                        _buildCircuitBadge('${circuit.rounds} rounds'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...circuit.exercises.take(3).map((ex) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${ex.name} - ${ex.timeSeconds}s / ${ex.restSeconds}s rest',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.white60,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCircuitBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.white60,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTrainingSplitsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedCategory = null),
                child: const Text(
                  '← Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.white50,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'TRAINING SPLITS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...WorkoutData.trainingSplits.map((split) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassmorphismCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        split.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          split.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...split.days.map((day) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white5,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.white10,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyberLime,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: day.exercises
                                .map((ex) => Text(
                                      '$ex • ',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.white60,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.emerald400;
      case 'intermediate':
        return AppColors.amber400;
      case 'advanced':
        return AppColors.neonCrimson;
      default:
        return AppColors.white60;
    }
  }
}

