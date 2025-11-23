import 'package:flutter/material.dart';
import '../../models/goal_config.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';

class GoalScreen extends StatefulWidget {
  final VoidCallback onNext;
  final Function(GoalMode) onSave;

  const GoalScreen({
    super.key,
    required this.onNext,
    required this.onSave,
  });

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  GoalMode? _selectedGoal;

  void _handleNext() {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a goal')),
      );
      return;
    }

    widget.onSave(_selectedGoal!);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.blackGradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What\'s your goal?',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 8),
              Text(
                'This shapes your nutrition and training',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white60,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: GoalMode.values.map((mode) {
                    final config = GoalConfig.get(mode);
                    final isSelected = _selectedGoal == mode;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedGoal = mode;
                          });
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isSelected
                                ? config.color.withOpacity(0.15)
                                : AppColors.white5,
                            border: Border.all(
                              color: isSelected
                                  ? config.color
                                  : AppColors.white10,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      config.short,
                                      style: AppTextStyles.h3.copyWith(
                                        color: isSelected
                                            ? config.color
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: config.color,
                                      size: 28,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                config.description,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.white70,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppColors.black30,
                                ),
                                child: Text(
                                  '6-week projection: ${config.projectionDelta > 0 ? "+" : ""}${config.projectionDelta} lbs',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: config.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('CONTINUE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

