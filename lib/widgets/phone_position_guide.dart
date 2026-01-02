import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PhonePositionGuide extends StatelessWidget {
  final VoidCallback onContinue;
  final String exerciseName;

  const PhonePositionGuide({
    super.key,
    required this.onContinue,
    required this.exerciseName,
  });

  String get _positionAdvice {
    final exercise = exerciseName.toLowerCase();
    
    if (exercise.contains('push') || exercise.contains('plank')) {
      return 'Place phone 4-6 feet away, at ground level, facing you from the side';
    } else if (exercise.contains('squat') || exercise.contains('lunge')) {
      return 'Place phone 6-8 feet away, at hip height, facing you from the front or side';
    } else if (exercise.contains('bridge') || exercise.contains('superman')) {
      return 'Place phone 4-6 feet away, at ground level, facing you from the side';
    } else if (exercise.contains('climber')) {
      return 'Place phone 4-6 feet away, at ground level, angled to see your full body';
    } else {
      return 'Place phone 5-7 feet away at waist height for full body visibility';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.electricCyan.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.phone_android, color: AppColors.electricCyan, size: 28),
              const SizedBox(width: 12),
              const Text(
                'PHONE SETUP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Visual diagram
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white5,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.white10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Distance markers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDistanceMarker('📱', 'Phone'),
                    _buildArrow(),
                    _buildDistanceMarker('5-7 ft', ''),
                    _buildArrow(),
                    _buildDistanceMarker('🏃', 'You'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Position advice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cyberLime.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cyberLime.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.cyberLime, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _positionAdvice,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tips
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TipRow(icon: Icons.wb_sunny_outlined, text: 'Good lighting helps tracking'),
              SizedBox(height: 8),
              _TipRow(icon: Icons.stay_current_portrait, text: 'Use portrait mode'),
              SizedBox(height: 8),
              _TipRow(icon: Icons.visibility, text: 'Ensure full body is visible'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyberLime,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'GOT IT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceMarker(String label, String sublabel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 32),
        ),
        if (sublabel.isNotEmpty)
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.white50,
            ),
          ),
      ],
    );
  }

  Widget _buildArrow() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          child: Divider(
            color: AppColors.electricCyan,
            thickness: 2,
          ),
        ),
        Icon(Icons.arrow_forward, color: AppColors.electricCyan, size: 16),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.white50, size: 18),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.white70,
          ),
        ),
      ],
    );
  }
}

