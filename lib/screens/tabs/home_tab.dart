import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart';
import '../../providers/stats_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/sparkline.dart';
import '../../widgets/premium_animations.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(workoutStatsProvider);
    final lockedWorkout = ref.watch(lockedWorkoutProvider);
    
    return SafeArea(
      child: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.cyberLime),
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading stats',
            style: const TextStyle(color: AppColors.white60),
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(workoutStatsProvider);
          },
          color: AppColors.cyberLime,
          backgroundColor: Colors.black,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100, left: 20, right: 20, top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App branding
                SlideUpAnimation(
                  delay: 0,
                  child: _buildAppHeader(),
                ),
                const SizedBox(height: 32),

                // Streak counter (THE PRESSURE)
                SlideUpAnimation(
                  delay: 100,
                  child: _buildStreakCard(context, stats),
                ),
                const SizedBox(height: 24),

                // Locked workout (if exists)
                if (lockedWorkout != null) ...[
                  SlideUpAnimation(
                    delay: 200,
                    child: _buildReadyToTrainCard(context, ref, lockedWorkout),
                  ),
                  const SizedBox(height: 24),
                ],

                // Quick start (if no locked workout)
                if (lockedWorkout == null) ...[
                  SlideUpAnimation(
                    delay: 200,
                    child: _buildQuickStartSection(context),
                  ),
                  const SizedBox(height: 24),
                ],

                // This week progress
                SlideUpAnimation(
                  delay: 300,
                  child: _buildThisWeekCard(stats),
                ),
                const SizedBox(height: 24),

                // All-time stats
                SlideUpAnimation(
                  delay: 400,
                  child: _buildAllTimeStatsCard(stats),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SKELETAL',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.cyberLime,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: AppColors.cyberLime.withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const Text(
          '-',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.white40,
            letterSpacing: 2,
          ),
        ),
        const Text(
          'PT',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(BuildContext context, WorkoutStats stats) {
    final hasStreak = stats.currentStreak > 0;
    final isAtRisk = !stats.trainedToday && hasStreak;

    final streakCard = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: isAtRisk
                ? [
                    AppColors.neonCrimson.withOpacity(0.3),
                    AppColors.neonCrimson.withOpacity(0.1),
                    Colors.black,
                  ]
                : hasStreak
                    ? [
                        AppColors.cyberLime.withOpacity(0.3),
                        AppColors.cyberLime.withOpacity(0.1),
                        Colors.black,
                      ]
                    : [
                        AppColors.white10,
                        AppColors.white5,
                        Colors.black,
                      ],
          ),
          border: Border.all(
            color: isAtRisk
                ? AppColors.neonCrimson.withOpacity(0.5)
                : hasStreak
                    ? AppColors.cyberLime.withOpacity(0.5)
                    : AppColors.white20,
            width: 2,
          ),
          boxShadow: hasStreak
              ? [
                  BoxShadow(
                    color: (isAtRisk ? AppColors.neonCrimson : AppColors.cyberLime).withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Streak number with animated counter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasStreak ? '🔥' : '💪',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                AnimatedCounter(
                  target: stats.currentStreak,
                  duration: const Duration(milliseconds: 1200),
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: isAtRisk
                        ? AppColors.neonCrimson
                        : hasStreak
                            ? AppColors.cyberLime
                            : AppColors.white60,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Status text
            Text(
              hasStreak
                  ? isAtRisk
                      ? 'DAY STREAK - AT RISK!'
                      : 'DAY STREAK'
                  : 'START YOUR STREAK',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isAtRisk
                    ? AppColors.neonCrimson
                    : hasStreak
                        ? AppColors.cyberLime
                        : AppColors.white50,
                letterSpacing: 2,
              ),
            ),
            
            // Motivational text
            if (hasStreak) ...[
              const SizedBox(height: 12),
              Text(
                isAtRisk
                    ? "Don't break it today!"
                    : stats.trainedToday
                        ? 'Beast! Come back tomorrow.'
                        : 'Keep it going!',
                style: TextStyle(
                  fontSize: 14,
                  color: isAtRisk ? AppColors.white70 : AppColors.white60,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Best streak
            if (stats.longestStreak > stats.currentStreak) ...[
              const SizedBox(height: 12),
              Text(
                'Best: ${stats.longestStreak} days',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.white40,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Wrap with pulsing glow if at risk
    if (isAtRisk) {
      return PulsingGlow(
        glowColor: AppColors.neonCrimson,
        minOpacity: 0.2,
        maxOpacity: 0.6,
        child: streakCard,
      );
    }

    return streakCard;
  }

  Widget _buildReadyToTrainCard(BuildContext context, WidgetRef ref, dynamic lockedWorkout) {
    return PulsingGlow(
      glowColor: AppColors.electricCyan,
      minOpacity: 0.2,
      maxOpacity: 0.5,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            AppColors.electricCyan.withOpacity(0.2),
            AppColors.electricCyan.withOpacity(0.1),
            Colors.black,
          ],
        ),
        border: Border.all(
          color: AppColors.electricCyan.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricCyan.withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.electricCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock,
                  color: AppColors.electricCyan,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'READY TO TRAIN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white60,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Workout name
          Text(
            lockedWorkout.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.electricCyan,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          
          // Stats
          Text(
            '${lockedWorkout.exercises.length} exercises • ~${lockedWorkout.estimatedMinutes} min',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.white60,
            ),
          ),
          const SizedBox(height: 16),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Navigate to Train tab (index 1)
                  final navigator = context.findAncestorWidgetOfExactType<_TabNavigator>();
                  if (navigator != null) {
                    (navigator as dynamic).changeTab(1);
                  }
                },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.electricCyan,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricCyan.withOpacity(0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Text(
                      'START WORKOUT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Clear locked workout
                  final notifier = ref.read(lockedWorkoutProvider.notifier);
                  notifier.state = null;
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.white20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildQuickStartSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK START',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.white50,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickStartButton(
                context,
                label: 'BROWSE\nWORKOUTS',
                icon: Icons.fitness_center,
                color: AppColors.cyberLime,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Navigate to workouts tab (index 2)
                  _navigateToTab(context, 2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStartButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.2,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThisWeekCard(WorkoutStats stats) {
    final hasData = stats.workoutsThisWeek > 0;
    final progress = stats.workoutsThisWeek / 7;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white20, width: 1),
        color: AppColors.white5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'THIS WEEK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white50,
                  letterSpacing: 2,
                ),
              ),
              // Mini sparkline
              if (hasData)
                Builder(builder: (context) {
                  final sparklineData = List<double>.generate(7, (i) {
                    if (i < stats.workoutsThisWeek) {
                      return 1.0 + (i % 3) * 0.5;
                    }
                    return 0.0;
                  });
                  return Sparkline(
                    data: sparklineData,
                    width: 60,
                    height: 20,
                    color: AppColors.cyberLime,
                    strokeWidth: 2,
                  );
                }),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cyberLime,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: hasData
                            ? [
                                BoxShadow(
                                  color: AppColors.cyberLime.withOpacity(0.4),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedCounter(
                target: stats.workoutsThisWeek,
                duration: const Duration(milliseconds: 1000),
                suffix: '/7',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyberLime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Reps comparison
          if (hasData) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL REPS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white40,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedCounter(
                      target: stats.repsThisWeek,
                      duration: const Duration(milliseconds: 1200),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (stats.repsLastWeek > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: stats.repsComparison >= 0
                          ? AppColors.cyberLime.withOpacity(0.2)
                          : AppColors.neonCrimson.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: stats.repsComparison >= 0
                            ? AppColors.cyberLime.withOpacity(0.4)
                            : AppColors.neonCrimson.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          stats.repsComparison >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: stats.repsComparison >= 0 ? AppColors.cyberLime : AppColors.neonCrimson,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.repsComparison.abs()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: stats.repsComparison >= 0 ? AppColors.cyberLime : AppColors.neonCrimson,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ] else ...[
            const Text(
              'No workouts this week yet.\nTime to start!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white60,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllTimeStatsCard(WorkoutStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white20, width: 1),
        color: AppColors.white5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALL-TIME STATS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.white50,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          
          if (stats.totalWorkouts > 0) ...[
            _buildStatRow('💪', 'Total Workouts', '${stats.totalWorkouts}'),
            const SizedBox(height: 16),
            _buildStatRow('🔢', 'Lifetime Reps', '${stats.totalLifetimeReps}'),
            const SizedBox(height: 16),
            _buildStatRow('⏱️', 'Time Trained', stats.formattedTrainingTime),
            if (stats.avgFormScore > 0) ...[
              const SizedBox(height: 16),
              _buildStatRow('⭐', 'Avg Form Score', '${stats.avgFormScore.toStringAsFixed(0)}%'),
            ],
          ] else ...[
            const Text(
              'Complete your first workout to see your stats here!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white60,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String emoji, String label, String value) {
    // Try to parse the value as a number for animated counting
    final numValue = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
    
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.white60,
            ),
          ),
        ),
        numValue != null
            ? AnimatedCounter(
                target: numValue,
                duration: const Duration(milliseconds: 1000),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
      ],
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    final navigator = context.findAncestorWidgetOfExactType<_TabNavigator>();
    if (navigator != null) {
      (navigator as dynamic).changeTab(tabIndex);
    }
  }
}

// InheritedWidget to access tab navigation from HomeScreen
class _TabNavigator extends InheritedWidget {
  final Function(int) changeTab;

  const _TabNavigator({
    required this.changeTab,
    required super.child,
  });

  @override
  bool updateShouldNotify(_TabNavigator old) => false;
}
