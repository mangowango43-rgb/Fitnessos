import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart';
import '../../providers/stats_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/workout_schedule_provider.dart';
import '../../models/workout_schedule.dart';
import '../../models/workout_models.dart';
import '../../services/storage_service.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/schedule_workout_modal.dart';
import '../../widgets/workout_library_modal.dart';
import '../../widgets/workout_date_strip.dart';
import '../home_screen.dart' show TabNavigator;
import '../tabs/settings_tab.dart';

/// =============================================================================
/// HOME TAB - STUNNING PROFESSIONAL FITNESS UI
/// =============================================================================
/// Inspired by FutureYou's glassmorphism design
/// Clean, minimal, powerful
/// =============================================================================

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  DateTime _selectedDate = DateTime.now();

  Future<Map<String, dynamic>?> _getWorkoutAlarm() async {
    final storage = await StorageService.getInstance();
    return storage.getWorkoutAlarm(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(workoutStatsProvider);
    final committedWorkout = ref.watch(committedWorkoutProvider);

    // Get stats - use previous value while loading to prevent grey flash
    final stats = statsAsync.valueOrNull ?? WorkoutStats.empty();
    final isLoading = statsAsync.isLoading;
    final hasError = statsAsync.hasError;

    return SafeArea(
      child: hasError
          ? Center(
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
                        color: AppColors.electricCyan,
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
            )
          : RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                ref.invalidate(workoutStatsProvider);
              },
              color: AppColors.electricCyan,
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  // Main content - always show even while loading
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ═══════════════════════════════════════════════
                        // HEADER: Logo + App Name + Streak + Settings
                        // ═══════════════════════════════════════════════
                        _buildHeader(context, stats),

                        const SizedBox(height: 16),

                        // ═══════════════════════════════════════════════
                        // DATE STRIP: Horizontal scrollable week view
                        // ═══════════════════════════════════════════════
                        _buildDateStrip(),

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // ═══════════════════════════════════════════════
                              // HERO WORKOUT CARD: Today's scheduled workout
                              // ═══════════════════════════════════════════════
                              _buildHeroWorkoutCard(context, ref, committedWorkout),

                              const SizedBox(height: 20),

                              // ═══════════════════════════════════════════════
                              // DATE STRIP: Workout scheduling
                              // ═══════════════════════════════════════════════
                              WorkoutDateStrip(
                                selectedDate: _selectedDate,
                                onDateSelected: (date) {
                                  setState(() => _selectedDate = date);
                                },
                                accentColor: AppColors.cyberLime,
                              ),

                              const SizedBox(height: 20),

                              // ═══════════════════════════════════════════════
                              // STAT CARDS: 2x2 grid (Workouts, Reps, Sets, Streak)
                              // ═══════════════════════════════════════════════
                              _buildStatCardsGrid(stats),

                              const SizedBox(height: 20),

                              // ═══════════════════════════════════════════════
                              // QUICK ACTIONS: Browse Workouts + Create Custom
                              // ═══════════════════════════════════════════════
                              _buildQuickActionsRow(context),

                              const SizedBox(height: 77), // Pushed down by 1.5cm (~57px) from original 20

                              // ═══════════════════════════════════════════════
                              // RECOVERY STATUS: Muscle group readiness
                              // ═══════════════════════════════════════════════
                              _buildRecoveryStatusCard(stats),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Optional: Show subtle loading indicator at top while refreshing
                  if (isLoading)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(AppColors.electricCyan.withOpacity(0.5)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER COMPONENT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context, WorkoutStats stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Logo + App Name
          Row(
            children: [
              // Logo (BIGGER)
              Image.asset(
                'assets/images/logo/playstore_icon.png',
                width: 48,
                height: 48,
              ),
              const SizedBox(width: 8),
              // App Name (LIME GREEN)
              const Text(
                'Skelatal--PT',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyberLime,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          
          // Right: Streak Badge + Settings Icon (MORE SPACING)
          Row(
            children: [
              // Streak Badge (NO RED BORDER)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showStreakAchievements(context, stats);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.white20,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '${stats.currentStreak}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Settings Icon
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Navigate to settings screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsTab(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.white20,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE STRIP COMPONENT (Smaller, like FutureYou)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDateStrip() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: 3 - index));
          final isSelected = date.day == _selectedDate.day &&
                             date.month == _selectedDate.month &&
                             date.year == _selectedDate.year;
          final isToday = date.day == DateTime.now().day &&
                         date.month == DateTime.now().month &&
                         date.year == DateTime.now().year;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              HapticFeedback.selectionClick();
            },
            onLongPress: () async {
              HapticFeedback.heavyImpact();
              await _openScheduleWorkoutFlow(date);
            },
            child: Container(
              width: 50,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.cyberLime.withOpacity(0.15)
                    : AppColors.white5,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.cyberLime
                      : AppColors.white10,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7],
                    style: TextStyle(
                      color: isSelected ? AppColors.cyberLime : AppColors.white50,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? AppColors.cyberLime : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.cyberLime : AppColors.white50,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO WORKOUT CARD (Glassmorphism design inspired by FutureYou)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroWorkoutCard(BuildContext context, WidgetRef ref, dynamic committedWorkout) {
    if (committedWorkout == null) {
      return _buildNoWorkoutCard(context);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricCyan.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0ea5e9),
                    Color(0xFF06b6d4),
                    Color(0xFF0891b2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Glass Overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
            
            // Animated Particles
            ..._buildParticles(),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Workout Name + Streak
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    committedWorkout.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                // Show alarm indicator if alarm is set
                                FutureBuilder<Map<String, dynamic>?>(
                                  future: _getWorkoutAlarm(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data != null) {
                                      final alarmData = snapshot.data!;
                                      final hour = alarmData['hour'] as int;
                                      final minute = alarmData['minute'] as int;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.cyberLime.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.cyberLime,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.alarm,
                                              color: AppColors.cyberLime,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                color: AppColors.cyberLime,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${committedWorkout.exercises.length} exercises • ${committedWorkout.totalSets} total sets',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Workout Streak Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '3', // TODO: Get workout-specific streak
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Workout Details Cards (removed GIFs, added info cards)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.fitness_center,
                                color: Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${committedWorkout.exercises.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'EXERCISES',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.format_list_numbered,
                                color: Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${committedWorkout.totalSets}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'SETS',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: AppColors.neonCrimson,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${committedWorkout.estimatedCalories}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'CALORIES',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons: ALARM + START + EDIT
                  Row(
                    children: [
                      // ALARM Button - Opens schedule modal
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          // Show schedule modal
                          final result = await showModalBottomSheet<Map<String, dynamic>>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ScheduleWorkoutModal(
                              selectedDate: _selectedDate,
                            ),
                          );
                          
                          if (result != null && mounted) {
                            // Schedule the alarm for the current workout
                            if (committedWorkout != null && result['time'] != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Alarm set for ${(result['time'] as TimeOfDay).format(context)}! ⏰'
                                  ),
                                  backgroundColor: AppColors.cyberLime,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.alarm,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // START WORKOUT Button (Big)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
                            if (navigator != null) {
                              (navigator as dynamic).changeTab(1); // Train tab
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.electricCyan,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.electricCyan.withOpacity(0.5),
                                  blurRadius: 16,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'START WORKOUT',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // EDIT Button - Opens workout library
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          // Show workout library to choose different workout
                          await _openWorkoutLibrary();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWorkoutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyberLime.withOpacity(0.2),
            AppColors.cyberLime.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.cyberLime.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.add_circle_outline,
            color: AppColors.cyberLime,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Workout Scheduled',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create or select a workout to get started',
            style: TextStyle(
              color: AppColors.white60,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
              if (navigator != null) {
                (navigator as dynamic).changeTab(2); // Workouts tab
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cyberLime,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Browse Workouts',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(6, (index) {
      return Positioned(
        left: (index * 37) % 100 + 10,
        top: (index * 53) % 100 + 10,
        child: Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: Colors.white54,
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAT CARDS GRID (2x2: Workouts, Reps, Sets, Streak)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatCardsGrid(WorkoutStats stats) {
    return Column(
      children: [
        // Row 1: Workouts + Reps
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'WORKOUTS',
                value: '${stats.workoutsThisWeek}',
                subtitle: '/ 5 this week',
                icon: Icons.fitness_center,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'REPS',
                value: '${stats.repsThisWeek}',
                subtitle: 'total reps',
                icon: Icons.all_inclusive,
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Sets + Streak
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'SETS',
                value: '${(stats.repsThisWeek / 10).round()}',
                subtitle: 'total sets',
                icon: Icons.stacked_bar_chart,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'STREAK',
                value: '${stats.currentStreak}',
                subtitle: 'days',
                icon: Icons.local_fire_department,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                showFlame: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    bool showFlame = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              showFlame ? Icons.local_fire_department : icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          // Value
          AnimatedCounter(
            target: int.tryParse(value) ?? 0,
            duration: const Duration(milliseconds: 1000),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            label,
            style: TextStyle(
              color: AppColors.white50,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.white40,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS ROW (Browse Workouts + Create Custom)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context: context,
            label: 'Browse\nWorkouts',
            icon: Icons.search,
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () {
              final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
              if (navigator != null) {
                (navigator as dynamic).changeTab(2); // Workouts tab
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            context: context,
            label: 'Create\nCustom',
            icon: Icons.add_circle_outline,
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () {
              final navigator = context.findAncestorWidgetOfExactType<TabNavigator>();
              if (navigator != null) {
                (navigator as dynamic).changeTab(2); // Workouts tab
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Gradient gradient,
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
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECOVERY STATUS CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRecoveryStatusCard(WorkoutStats stats) {
    final recoveryData = [
      {'muscle': '💪 CHEST', 'percent': 0.9, 'status': 'READY', 'color': AppColors.cyberLime},
      {'muscle': '🦵 LEGS', 'percent': 0.45, 'status': '36H LEFT', 'color': AppColors.neonCrimson},
      {'muscle': '🔙 BACK', 'percent': 1.0, 'status': 'OPTIMAL', 'color': AppColors.cyberLime},
      {'muscle': '💪 SHOULDERS', 'percent': 0.8, 'status': 'READY', 'color': AppColors.cyberLime},
      {'muscle': '💪 ARMS', 'percent': 0.75, 'status': 'READY', 'color': AppColors.electricCyan},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECOVERY STATUS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Icon(
                Icons.medical_services_outlined,
                color: AppColors.white50,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recoveryData.map((data) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['muscle'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      data['status'] as String,
                      style: TextStyle(
                        color: data['color'] as Color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: data['percent'] as double,
                    minHeight: 8,
                    backgroundColor: AppColors.white10,
                    valueColor: AlwaysStoppedAnimation(data['color'] as Color),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHEDULING METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Open workout library to swap hero workout
  Future<void> _openWorkoutLibrary() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WorkoutLibraryModal(),
    );

    if (selected != null && mounted) {
      // Create workout preset from selected data
      final preset = WorkoutPreset(
        id: selected['id'] as String,
        name: selected['name'] as String,
        category: 'gym',
        subcategory: selected['type'] as String? ?? 'gym',
        exercises: [], // Will be populated from workout data
        isCircuit: false,
        duration: selected['duration'] as String?,
      );
      
      await ref
          .read(committedWorkoutProvider.notifier)
          .commitWorkout(preset);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout Committed! ✅ "${selected['name']}"'),
            backgroundColor: AppColors.cyberLime,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  /// Open schedule workout flow (date long-press)
  Future<void> _openScheduleWorkoutFlow(DateTime date) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleWorkoutModal(selectedDate: date),
    );

    if (result == null || !mounted) return;

    // User set time/alarm, now show workout library
    final selectedWorkout = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WorkoutLibraryModal(),
    );

    if (selectedWorkout != null && mounted) {
      final timeData = result['time'] as TimeOfDay?;
      final hasAlarm = result['hasAlarm'] as bool;

      // Create schedule
      final schedule = WorkoutSchedule(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        workoutId: selectedWorkout['id'] as String,
        workoutName: selectedWorkout['name'] as String,
        scheduledDate: DateTime(date.year, date.month, date.day),
        scheduledTime: timeData != null 
            ? '${timeData.hour.toString().padLeft(2, '0')}:${timeData.minute.toString().padLeft(2, '0')}'
            : null,
        hasAlarm: hasAlarm,
        createdAt: DateTime.now(),
      );

      // Save schedule
      await ref.read(workoutSchedulesProvider.notifier).saveSchedule(schedule);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasAlarm 
                  ? '✅ ${selectedWorkout['name']} scheduled with alarm!'
                  : '✅ ${selectedWorkout['name']} scheduled!',
            ),
            backgroundColor: AppColors.cyberLime,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // WORKOUT ALARM PICKER
  // ═══════════════════════════════════════════════════════════════════════════
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STREAK ACHIEVEMENTS MODAL
  // ═══════════════════════════════════════════════════════════════════════════
  void _showStreakAchievements(BuildContext context, WorkoutStats stats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.cyberBlack,
              AppColors.cyberBlack.withOpacity(0.95),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          border: Border.all(
            color: AppColors.electricCyan.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFFD60A)],
                        ).createShader(bounds),
                        child: const Text(
                          'STREAK ACHIEVEMENTS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Streak: ${stats.currentStreak} days',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Achievements Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: _streakAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = _streakAchievements[index];
                  final isUnlocked = stats.currentStreak >= (achievement['days'] as int);

                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: _buildAchievementCard(achievement, isUnlocked),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAchievementCard(Map<String, dynamic> achievement, bool isUnlocked) {
    return Container(
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (achievement['color'] as Color).withOpacity(0.3),
                  (achievement['color'] as Color).withOpacity(0.1),
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.white5,
                  AppColors.white10,
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? (achievement['color'] as Color).withOpacity(0.5)
              : AppColors.white20,
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: (achievement['color'] as Color).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            duration: const Duration(seconds: 2),
            tween: Tween<double>(begin: 0, end: isUnlocked ? 1 : 0.5),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.9 + (0.1 * value),
                child: Text(
                  achievement['emoji'] as String,
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.3),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${achievement['days']} DAYS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isUnlocked ? Colors.white : AppColors.white40,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              achievement['title'] as String,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? AppColors.white90 : AppColors.white30,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 20+ Streak Achievements
  static final List<Map<String, dynamic>> _streakAchievements = [
    {'days': 1, 'emoji': '⚡', 'title': 'First Step', 'color': Color(0xFF00D9FF)},
    {'days': 3, 'emoji': '🔥', 'title': 'Getting Hot', 'color': Color(0xFFFF6B35)},
    {'days': 5, 'emoji': '💪', 'title': 'Strong Start', 'color': Color(0xFF4ECDC4)},
    {'days': 7, 'emoji': '🌟', 'title': 'Week Warrior', 'color': Color(0xFFFFD60A)},
    {'days': 10, 'emoji': '🚀', 'title': 'Momentum', 'color': Color(0xFF00D9FF)},
    {'days': 14, 'emoji': '🏆', 'title': 'Two Weeks', 'color': Color(0xFFB7FF00)},
    {'days': 21, 'emoji': '💎', 'title': 'Habit Former', 'color': Color(0xFF00D9FF)},
    {'days': 30, 'emoji': '👑', 'title': 'Monthly King', 'color': Color(0xFFFFD60A)},
    {'days': 50, 'emoji': '🔱', 'title': 'Unstoppable', 'color': Color(0xFF4ECDC4)},
    {'days': 75, 'emoji': '⚔️', 'title': 'Warrior', 'color': Color(0xFFFF6B35)},
    {'days': 100, 'emoji': '🎯', 'title': 'Centurion', 'color': Color(0xFFB7FF00)},
    {'days': 125, 'emoji': '🌪️', 'title': 'Tornado', 'color': Color(0xFF00D9FF)},
    {'days': 150, 'emoji': '⚡', 'title': 'Lightning', 'color': Color(0xFFFFD60A)},
    {'days': 180, 'emoji': '🦾', 'title': 'Half Year', 'color': Color(0xFF4ECDC4)},
    {'days': 200, 'emoji': '🔮', 'title': 'Legendary', 'color': Color(0xFFFF6B35)},
    {'days': 250, 'emoji': '🌋', 'title': 'Volcanic', 'color': Color(0xFFB7FF00)},
    {'days': 300, 'emoji': '🦁', 'title': 'Lion Heart', 'color': Color(0xFFFFD60A)},
    {'days': 365, 'emoji': '👽', 'title': 'Year Beast', 'color': Color(0xFF00D9FF)},
    {'days': 500, 'emoji': '🌌', 'title': 'Galactic', 'color': Color(0xFF4ECDC4)},
    {'days': 750, 'emoji': '🏛️', 'title': 'Titan', 'color': Color(0xFFFF6B35)},
    {'days': 1000, 'emoji': '🌠', 'title': 'Immortal', 'color': Color(0xFFB7FF00)},
    {'days': 1500, 'emoji': '⭐', 'title': 'Transcendent', 'color': Color(0xFFFFD60A)},
  ];
}


