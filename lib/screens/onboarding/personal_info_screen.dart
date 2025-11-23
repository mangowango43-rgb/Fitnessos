import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';

class PersonalInfoScreen extends StatefulWidget {
  final VoidCallback onNext;
  final Function(String, int, double, double) onSave;

  const PersonalInfoScreen({
    super.key,
    required this.onNext,
    required this.onSave,
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _targetWeightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    widget.onSave(
      _nameController.text,
      int.parse(_ageController.text),
      double.parse(_weightController.text),
      double.parse(_targetWeightController.text),
    );
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
                'Let\'s get to know you',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 8),
              Text(
                'This helps us personalize your experience',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white60,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Your name'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: AppTextStyles.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Alex',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Age'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'e.g., 28',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Current weight (lbs)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTextStyles.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'e.g., 185',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Target weight (lbs)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _targetWeightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTextStyles.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'e.g., 175',
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

