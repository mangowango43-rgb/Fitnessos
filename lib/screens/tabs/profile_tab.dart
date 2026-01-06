import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../utils/app_colors.dart';
import '../../providers/stats_provider.dart';
import '../../services/storage_service.dart';
import '../../services/workout_recording_service.dart';

/// =============================================================================
/// PROFILE TAB - USER STATS & WORKOUT RECORDINGS
/// =============================================================================
/// Beautiful profile with stats, achievements, and saved workout videos
/// =============================================================================

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  String _userName = 'Champion';
  List<WorkoutRecording> _recordings = [];
  bool _isLoadingRecordings = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecordings();
  }

  Future<void> _loadUserData() async {
    final name = await StorageService.getUserName();
    if (mounted) {
      setState(() {
        _userName = name ?? 'Champion';
      });
    }
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoadingRecordings = true);
    final recordings = await WorkoutRecordingService.getRecordings();
    if (mounted) {
      setState(() {
        _recordings = recordings;
        _isLoadingRecordings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(workoutStatsProvider);

    return SafeArea(
      child: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.electricCyan),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.neonCrimson, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Error loading profile',
                style: TextStyle(color: AppColors.white60, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(workoutStatsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricCyan,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            ref.invalidate(workoutStatsProvider);
            await _loadRecordings();
          },
          color: AppColors.electricCyan,
          backgroundColor: Colors.black,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ═══════════════════════════════════════════════
                // HEADER: User name + avatar
                // ═══════════════════════════════════════════════
                _buildHeader(),
                
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ═══════════════════════════════════════════════
                      // STATS GRID: Total workouts, reps, sets, streak
                      // ═══════════════════════════════════════════════
                      _buildStatsGrid(stats),
                      
                      const SizedBox(height: 32),
                      
                      // ═══════════════════════════════════════════════
                      // SECTION TITLE: Workout Recordings
                      // ═══════════════════════════════════════════════
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'WORKOUT RECORDINGS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '${_recordings.length} videos',
                            style: const TextStyle(
                              color: AppColors.white50,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // ═══════════════════════════════════════════════
                      // RECORDINGS GRID: 2x2 grid of saved workouts
                      // ═══════════════════════════════════════════════
                      _buildRecordingsGrid(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricCyan.withOpacity(0.15),
            AppColors.cyberLime.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.electricCyan, AppColors.cyberLime],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricCyan.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKELETAL-PT Athlete',
                  style: TextStyle(
                    color: AppColors.cyberLime.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          
          // Settings icon
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              // TODO: Navigate to settings
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.white50,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(WorkoutStats stats) {
    final statItems = [
      _StatItem(
        label: 'TOTAL WORKOUTS',
        value: stats.totalWorkouts.toString(),
        icon: Icons.fitness_center,
        color: AppColors.electricCyan,
      ),
      _StatItem(
        label: 'TOTAL REPS',
        value: stats.totalLifetimeReps.toString(),
        icon: Icons.repeat,
        color: AppColors.cyberLime,
      ),
      _StatItem(
        label: 'TRAINING TIME',
        value: stats.formattedTrainingTime,
        icon: Icons.timer,
        color: AppColors.neonPurple,
      ),
      _StatItem(
        label: 'CURRENT STREAK',
        value: '${stats.currentStreak}',
        icon: Icons.local_fire_department,
        color: AppColors.neonOrange,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: statItems.length,
      itemBuilder: (context, index) {
        final item = statItems[index];
        return _buildStatCard(item);
      },
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            item.color.withOpacity(0.15),
            item.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            item.icon,
            color: item.color,
            size: 28,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  color: AppColors.white50,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingsGrid() {
    if (_isLoadingRecordings) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.electricCyan),
          ),
        ),
      );
    }

    if (_recordings.isEmpty) {
      return _buildEmptyRecordings();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final recording = _recordings[index];
        return _buildRecordingCard(recording);
      },
    );
  }

  Widget _buildEmptyRecordings() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.white5,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: AppColors.white30,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No recordings yet',
            style: TextStyle(
              color: AppColors.white50,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Press the record button during a workout to save your session',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white40,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(WorkoutRecording recording) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        await _playRecording(recording);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white10),
          color: Colors.black,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: recording.thumbnailPath != null && File(recording.thumbnailPath!).existsSync()
                    ? Image.file(
                        File(recording.thumbnailPath!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.electricCyan.withOpacity(0.3),
                              AppColors.cyberLime.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recording.workoutName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(recording.recordedAt),
                    style: const TextStyle(
                      color: AppColors.white50,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: AppColors.cyberLime,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(recording.duration),
                        style: const TextStyle(
                          color: AppColors.cyberLime,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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

  Future<void> _playRecording(WorkoutRecording recording) async {
    // TODO: Implement video player
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          recording.workoutName,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Video player coming soon!\n\nRecorded: ${_formatDate(recording.recordedAt)}\nDuration: ${_formatDuration(recording.duration)}',
          style: const TextStyle(color: AppColors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.cyberLime)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await WorkoutRecordingService.deleteRecording(recording.id);
              await _loadRecordings();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.neonCrimson)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

