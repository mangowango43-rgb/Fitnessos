import 'package:flutter/material.dart';
import '../../models/goal_config.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';

class EquipmentScreen extends StatefulWidget {
  final VoidCallback onNext;
  final Function(EquipmentMode) onSave;

  const EquipmentScreen({
    super.key,
    required this.onNext,
    required this.onSave,
  });

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  EquipmentMode? _selectedEquipment;

  void _handleNext() {
    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select equipment')),
      );
      return;
    }

    widget.onSave(_selectedEquipment!);
    widget.onNext();
  }

  IconData _getIcon(EquipmentMode mode) {
    switch (mode) {
      case EquipmentMode.bodyweight:
        return Icons.accessibility_new;
      case EquipmentMode.dumbbells:
        return Icons.fitness_center;
      case EquipmentMode.gym:
        return Icons.sports_gymnastics;
    }
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
                'What equipment do you have?',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll build your workouts around what you actually have',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white60,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: EquipmentMode.values.map((mode) {
                    final config = EquipmentConfig.get(mode);
                    final isSelected = _selectedEquipment == mode;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedEquipment = mode;
                          });
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isSelected
                                ? AppColors.emerald400.withOpacity(0.15)
                                : AppColors.white5,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.emerald400
                                  : AppColors.white10,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: isSelected
                                      ? AppColors.emerald400.withOpacity(0.2)
                                      : AppColors.white10,
                                ),
                                child: Icon(
                                  _getIcon(mode),
                                  size: 32,
                                  color: isSelected
                                      ? AppColors.emerald400
                                      : AppColors.white60,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            config.label,
                                            style: AppTextStyles.h4.copyWith(
                                              color: isSelected
                                                  ? AppColors.emerald400
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: AppColors.emerald400,
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      config.description,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.white60,
                                      ),
                                    ),
                                  ],
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

