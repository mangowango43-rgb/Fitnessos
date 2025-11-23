import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';

class PreferencesScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Function(String, String, List<String>, String) onSave;

  const PreferencesScreen({
    super.key,
    required this.onComplete,
    required this.onSave,
  });

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _experienceController = TextEditingController();
  final _injuriesController = TextEditingController();
  final _dietaryController = TextEditingController();
  final List<String> _selectedDays = [];

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    _experienceController.dispose();
    _injuriesController.dispose();
    _dietaryController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    widget.onSave(
      _experienceController.text,
      _injuriesController.text,
      _selectedDays,
      _dietaryController.text,
    );
    widget.onComplete();
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
                'A few more details',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 8),
              Text(
                'Optional but helps us personalize your experience',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white60,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Fitness experience'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _experienceController,
                        style: AppTextStyles.bodyLarge,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g., Been lifting for 2 years, did CrossFit before...',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Any injuries or limitations?'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _injuriesController,
                        style: AppTextStyles.bodyLarge,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Lower back, shoulder issues...',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Preferred training days'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _days.map((day) {
                          final isSelected = _selectedDays.contains(day);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedDays.remove(day);
                                } else {
                                  _selectedDays.add(day);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected
                                    ? AppColors.amber400
                                    : AppColors.white10,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.amber400
                                      : AppColors.white20,
                                ),
                              ),
                              child: Text(
                                day.substring(0, 3),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? Colors.black
                                      : AppColors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Dietary restrictions'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dietaryController,
                        style: AppTextStyles.bodyLarge,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g., Vegetarian, lactose intolerant, no red meat...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleComplete,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('COMPLETE SETUP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.white70,
        fontSize: 14,
      ),
    );
  }
}

