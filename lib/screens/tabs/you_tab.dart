import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/glassmorphism_card.dart';

class YouTab extends StatelessWidget {
  const YouTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 20, right: 20, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'YOUR PROFILE',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AppColors.cyberLime,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 32),

          // This Week Calendar
          GlassmorphismCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THIS WEEK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white50,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _buildWeekDays(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Overall Stats
          GlassmorphismCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OVERALL STATS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white50,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatRow('Total Workouts', '147'),
                const SizedBox(height: 20),
                _buildStatRow('Total Reps', '12,483'),
                const SizedBox(height: 20),
                _buildStatRow('Best Streak', '23 days'),
                const SizedBox(height: 20),
                _buildStatRow('Favorite Muscle', 'Chest'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Personal Records
          GlassmorphismCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERSONAL RECORDS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white50,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPRCard('Bench Press', '225 lbs', '🔥'),
                const SizedBox(height: 12),
                _buildPRCard('Squat', '315 lbs', '💪'),
                const SizedBox(height: 12),
                _buildPRCard('Deadlift', '405 lbs', '⚡'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeekDays() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final workoutDays = [false, true, false, true, true, false, true];
    final dates = [21, 22, 23, 24, 25, 26, 27];

    return List.generate(7, (index) {
      return Column(
        children: [
          Text(
            days[index],
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.white50,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: workoutDays[index]
                  ? AppColors.cyberLime
                  : AppColors.white5,
              shape: BoxShape.circle,
              border: Border.all(
                color: workoutDays[index]
                    ? Colors.transparent
                    : AppColors.white10,
                width: 1,
              ),
              boxShadow: workoutDays[index]
                  ? [
                      BoxShadow(
                        color: AppColors.cyberLime.withOpacity(0.4),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${dates[index]}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: workoutDays[index] ? Colors.black : AppColors.white30,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.white60,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.cyberLime,
          ),
        ),
      ],
    );
  }

  Widget _buildPRCard(String exercise, String weight, String icon) {
    return Container(
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
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              exercise,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            weight,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.cyberLime,
            ),
          ),
        ],
      ),
    );
  }
}
