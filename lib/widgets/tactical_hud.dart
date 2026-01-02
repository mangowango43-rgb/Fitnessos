import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// TACTICAL HUD - Military-style status display
class TacticalHUD extends StatelessWidget {
  final String status;
  final String? subStatus;
  final Color statusColor;
  final bool showPulse;

  const TacticalHUD({
    super.key,
    required this.status,
    this.subStatus,
    this.statusColor = AppColors.cyberLime,
    this.showPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: showPulse
            ? [
                BoxShadow(
                  color: statusColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status indicator dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Status text
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          if (subStatus != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                subStatus!,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.white60,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// REP COUNTER HUD - Tactical style
class RepCounterHUD extends StatelessWidget {
  final int currentReps;
  final int targetReps;
  final int currentSet;
  final int totalSets;

  const RepCounterHUD({
    super.key,
    required this.currentReps,
    required this.targetReps,
    required this.currentSet,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyberLime.withOpacity(0.6),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large rep count
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$currentReps',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyberLime,
                  height: 1,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(
                      color: AppColors.cyberLime.withOpacity(0.8),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
              Text(
                '/$targetReps',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white50,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Set indicator
          Text(
            'SET $currentSet/$totalSets',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.white60,
              letterSpacing: 1.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
