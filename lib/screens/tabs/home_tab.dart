import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart';
import '../../providers/stats_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/sparkline.dart';
import '../../widgets/premium_animations.dart';
import '../../widgets/viral_analytics.dart';
import '../home_screen.dart' show TabNavigator;

/// =============================================================================
/// HOME TAB - THE MOST ADDICTIVE FITNESS EXPERIENCE EVER BUILT
/// =============================================================================
/// This is designed to be CRACK:
/// - Every tap does something
/// - Real-time animations everywhere
/// - Progress you can SEE
/// - Dopamine triggers at every interaction
/// =============================================================================

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(workoutStatsProvider);
    final lockedWorkout = ref.watch(lockedWorkoutProvider);
    
    return SafeArea(
      child: statsAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.cyberLime),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your gains...',
                style: TextStyle(
                  color: AppColors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.neonCrimson, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Error loading stats',
                style: TextStyle(color: AppColors.white60, fontSize: 16),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.invalidate(workoutStatsProvider);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cyberLime,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'RETRY',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
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
                  child: _buildAppHeader(context),
                ),
                const SizedBox(height: 24),

                // Streak counter (THE PRESSURE)
                SlideUpAnimation(
                  delay: 50,
                  child: _buildStreakCard(context, stats),
                ),
                const SizedBox(height: 20),

                // Circular stats (VIRAL)
                SlideUpAnimation(
                  delay: 100,
                  child: _buildCircularStats(context, stats),
                ),
                const SizedBox(height: 20),

                // Locked workout OR Create workout button
                if (lockedWorkout != null) ...[
                  SlideUpAnimation(
                    delay: 150,
                    child: _buildReadyToTrainCard(context, ref, lockedWorkout),
                  ),
                ] else ...[
                  SlideUpAnimation(
                    delay: 150,
                    child: _buildCreateWorkoutButton(context),
                  ),
                ],
                const SizedBox(height: 20),

                // Quick start buttons
                SlideUpAnimation(
                  delay: 200,
                  child: _buildQuickStartSection(context),
                ),
                const SizedBox(height: 20),

                // Weekly progress bars (ANIMATED)
                SlideUpAnimation(
                  delay: 250,
                  child: _buildWeeklyProgressCard(context, stats),
                ),
                const SizedBox(height: 20),

                // Achievements (UNLOCKABLES)
                SlideUpAnimation(
                  delay: 300,
                  child: _buildAchievementsSection(context, stats),
                ),
                const SizedBox(height: 20),

                // Trend stats
                SlideUpAnimation(
                  delay: 350,
                  child: _buildTrendStats(context, stats),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SKELETAL-PT',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.cyberLime,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: AppColors.cyberLime.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your AI Coach',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.white40,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            // Navigate to settings (tab 3)
            final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
            if (navigator != null) {
              (navigator as dynamic).changeTab(3);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white5,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white10),
            ),
            child: const Icon(
              Icons.settings,
              color: AppColors.white70,
              size: 20,
            ),
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
        if (isAtRisk) {
          // Navigate to workouts tab
          final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
          if (navigator != null) {
            (navigator as dynamic).changeTab(1);
          }
        }
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
                ? AppColors.neonCrimson.withOpacity(0.6)
                : hasStreak
                    ? AppColors.cyberLime.withOpacity(0.6)
                    : AppColors.white20,
            width: 2,
          ),
        ),
        child: Column(
          children: [
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
            const SizedBox(height: 12),
            
            Text(
              hasStreak
                  ? isAtRisk
                      ? 'DAY STREAK - AT RISK!'
                      : 'DAY STREAK'
                  : 'START YOUR STREAK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isAtRisk
                    ? AppColors.neonCrimson
                    : hasStreak
                        ? AppColors.cyberLime
                        : AppColors.white50,
                letterSpacing: 2,
              ),
            ),
            
            if (hasStreak) ...[
              const SizedBox(height: 12),
              Text(
                isAtRisk
                    ? "Don't lose it! Workout now →"
                    : stats.trainedToday
                        ? 'Beast! Come back tomorrow.'
                        : 'Keep it going!',
                style: TextStyle(
                  fontSize: 14,
                  color: isAtRisk ? AppColors.white90 : AppColors.white60,
                  fontWeight: isAtRisk ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            if (stats.longestStreak > stats.currentStreak) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Personal Best: ${stats.longestStreak} days 🏆',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.white50,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isAtRisk) {
      return PulsingGlow(
        glowColor: AppColors.neonCrimson,
        minOpacity: 0.3,
        maxOpacity: 0.7,
        duration: const Duration(milliseconds: 1500),
        child: streakCard,
      );
    }

    return streakCard;
  }

  Widget _buildCircularStats(BuildContext context, WorkoutStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.white5,
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THIS WEEK',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.white50,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularStatRing(
                current: stats.workoutsThisWeek,
                target: 7,
                label: 'WORKOUTS',
                subtitle: '/ 7 days',
                color: AppColors.cyberLime,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Navigate to train tab
                  final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
                  if (navigator != null) {
                    (navigator as dynamic).changeTab(1);
                  }
                },
              ),
              CircularStatRing(
                current: stats.repsThisWeek,
                target: stats.repsThisWeek + 100,
                label: 'TOTAL REPS',
                color: AppColors.electricCyan,
                onTap: () {
                  HapticFeedback.mediumImpact();
                },
              ),
              CircularStatRing(
                current: (stats.repsThisWeek / 10).round(),
                target: 100,
                label: 'SETS',
                color: AppColors.neonCrimson,
                onTap: () {
                  HapticFeedback.mediumImpact();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToTrainCard(BuildContext context, WidgetRef ref, dynamic lockedWorkout) {
    return PulsingGlow(
      glowColor: AppColors.electricCyan,
      minOpacity: 0.2,
      maxOpacity: 0.5,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          // Navigate to train tab
          final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
          if (navigator != null) {
            (navigator as dynamic).changeTab(1);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: [
                AppColors.electricCyan.withOpacity(0.3),
                AppColors.electricCyan.withOpacity(0.1),
                Colors.black,
              ],
            ),
            border: Border.all(
              color: AppColors.electricCyan.withOpacity(0.6),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricCyan.withOpacity(0.3),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.electricCyan.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: AppColors.electricCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'READY TO TRAIN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.electricCyan,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text(
                lockedWorkout.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWorkoutStat(
                    Icons.fitness_center,
                    '${lockedWorkout.exercises.length}',
                    'exercises',
                  ),
                  const SizedBox(width: 20),
                  _buildWorkoutStat(
                    Icons.timer_outlined,
                    '~${lockedWorkout.estimatedMinutes}',
                    'minutes',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.electricCyan,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricCyan.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Text(
                  'START WORKOUT →',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.electricCyan, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.white50,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateWorkoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        // Navigate to workouts tab
        final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
        if (navigator != null) {
          (navigator as dynamic).changeTab(1);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cyberLime.withOpacity(0.2),
              AppColors.cyberLime.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: AppColors.cyberLime.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cyberLime,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.black,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Workout',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose exercises & start training',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.cyberLime,
              size: 20,
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
            fontSize: 13,
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
                label: 'Browse\nWorkouts',
                icon: Icons.list,
                color: AppColors.electricCyan,
                onTap: () {
                  final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
                  if (navigator != null) {
                    (navigator as dynamic).changeTab(1);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStartButton(
                context,
                label: 'My\nProgress',
                icon: Icons.analytics,
                color: AppColors.cyberLime,
                onTap: () {
                  // Show analytics modal or navigate
                  HapticFeedback.mediumImpact();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStartButton(
                context,
                label: 'History',
                icon: Icons.history,
                color: AppColors.neonCrimson,
                onTap: () {
                  HapticFeedback.mediumImpact();
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressCard(BuildContext context, WorkoutStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.white5,
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'WEEKLY PROGRESS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white50,
                  letterSpacing: 2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyberLime.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${((stats.workoutsThisWeek / 7) * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.cyberLime,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ViralProgressBar(
            progress: stats.workoutsThisWeek / 7,
            label: 'Workout Frequency',
            value: '${stats.workoutsThisWeek}/7 days',
            startColor: AppColors.cyberLime,
            endColor: AppColors.electricCyan,
          ),
          const SizedBox(height: 20),
          
          ViralProgressBar(
            progress: (stats.repsThisWeek / (stats.repsThisWeek + 100)).clamp(0.0, 1.0),
            label: 'Total Volume',
            value: '${stats.repsThisWeek} reps',
            startColor: AppColors.electricCyan,
            endColor: AppColors.neonCrimson,
          ),
          const SizedBox(height: 20),
          
          ViralProgressBar(
            progress: stats.currentStreak / (stats.currentStreak + 7).clamp(1.0, 365.0),
            label: 'Consistency',
            value: '${stats.currentStreak} day streak',
            startColor: AppColors.neonCrimson,
            endColor: AppColors.cyberLime,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, WorkoutStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ACHIEVEMENTS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.white50,
                letterSpacing: 2,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: const Text(
                'View All →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyberLime,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AchievementBadge(
                emoji: '🔥',
                title: 'First Streak',
                subtitle: '7 days',
                unlocked: stats.currentStreak >= 7,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AchievementBadge(
                emoji: '💪',
                title: 'Century',
                subtitle: '100 reps',
                unlocked: stats.totalLifetimeReps >= 100,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AchievementBadge(
                emoji: '⚡',
                title: 'Warrior',
                subtitle: '10 workouts',
                unlocked: stats.totalWorkouts >= 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendStats(BuildContext context, WorkoutStats stats) {
    final weekOverWeekChange = stats.repsLastWeek > 0
        ? ((stats.repsThisWeek - stats.repsLastWeek) / stats.repsLastWeek * 100).round()
        : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRENDS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.white50,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TrendStatCard(
                label: 'Total Workouts',
                value: '${stats.totalWorkouts}',
                trend: '${stats.workoutsThisWeek} this week',
                isUp: stats.workoutsThisWeek > 0,
                color: AppColors.cyberLime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TrendStatCard(
                label: 'Week Progress',
                value: weekOverWeekChange >= 0 ? '+$weekOverWeekChange%' : '$weekOverWeekChange%',
                trend: 'vs last week',
                isUp: weekOverWeekChange >= 0,
                color: weekOverWeekChange >= 0 ? AppColors.cyberLime : AppColors.neonCrimson,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
