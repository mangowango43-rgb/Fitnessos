import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/bio_rings.dart';
import '../../providers/workout_provider.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockedWorkout = ref.watch(lockedWorkoutProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, left: 20, right: 20, top: 16),
      child: Column(
        children: [
          // Locked Workout Card (if exists)
          if (lockedWorkout != null) ...[
            _buildLockedWorkoutCard(context, ref, lockedWorkout),
            const SizedBox(height: 24),
          ],

          // Bio-feedback Rings
          const BioRings(
            formScore: 94,
            streak: 12,
            moveProgress: 0.94,
          ),
          const SizedBox(height: 48),

          // Quick Stats Grid
          _buildStatsGrid(),
          const SizedBox(height: 32),

          // Battle Logs
          _buildBattleLogs(),
        ],
      ),
    );
  }

  Widget _buildLockedWorkoutCard(BuildContext context, WidgetRef ref, dynamic lockedWorkout) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            AppColors.cyberLime.withOpacity(0.2),
            AppColors.cyberLime.withOpacity(0.1),
            Colors.black.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyberLime.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: AppColors.cyberLime.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with lock icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cyberLime.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: AppColors.cyberLime,
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
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.cyberLime,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            
            // Exercise list (compact)
            ...lockedWorkout.exercises.take(3).map((ex) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cyberLime.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ex.name} • ${ex.sets}x${ex.reps}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
            if (lockedWorkout.exercises.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  '+${lockedWorkout.exercises.length - 3} more',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.white50,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            
            // Buttons row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      DefaultTabController.of(context).animateTo(2);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cyberLime,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyberLime.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Text(
                        'START WORKOUT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    // Navigate to workouts tab to edit/change workout
                    DefaultTabController.of(context).animateTo(1);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.white20,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: AppColors.white70,
                      size: 18,
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

  Widget _buildWorkoutBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.white20,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.white70,
        ),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            AppColors.cyberLime.withOpacity(0.2),
            AppColors.electricCyan.withOpacity(0.15),
            Colors.black.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyberLime.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.cyberLime.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: AppColors.cyberLime.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Grid pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: _GridPatternPainter(),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MISSION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white50,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TOTAL CHEST\nDESTRUCTION',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.cyberLime,
                    height: 1.1,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: AppColors.cyberLime,
                        blurRadius: 30,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Stats badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge('4 exercises'),
                    _buildBadge('12 sets'),
                    _buildBadge('~45 min'),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GlowButton(
                        text: '⚡ IGNITE ⚡',
                        onPressed: () {},
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.white5,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.white20,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
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
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.black40,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white10,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.white60,
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('💪', '24', 'WORKOUTS')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('✅', '89%', 'PERFECT FORM')),
      ],
    );
  }

  Widget _buildStatCard(String icon, String value, String label) {
    return GlassmorphismCardStrong(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.cyberLime,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.white50,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BATTLE LOGS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.white50,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        _buildBattleLogCard('CHEST ANNIHILATION', 'Dec 26, 4:30 PM', 5, 92),
        const SizedBox(height: 12),
        _buildBattleLogCard('LEG DESTROYER', 'Dec 25, 5:15 PM', 7, 88),
        const SizedBox(height: 12),
        _buildBattleLogCard('BACK ASSAULT', 'Dec 24, 4:45 PM', 6, 95),
      ],
    );
  }

  Widget _buildBattleLogCard(String title, String date, int exercises, int score) {
    final isHighScore = score > 90;
    return GlassmorphismCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.white50,
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'FORM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: score / 100,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isHighScore ? AppColors.cyberLime : const Color(0xFFFFB800),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          if (isHighScore)
                            BoxShadow(
                              color: AppColors.cyberLime.withOpacity(0.5),
                              blurRadius: 15,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isHighScore ? AppColors.cyberLime : const Color(0xFFFFB800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 60.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPatternPainter oldDelegate) => false;
}
