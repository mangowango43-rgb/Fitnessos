import 'package:flutter/material.dart';

enum GoalMode {
  cut,
  recomp,
  bulk,
  strength,
  athletic,
}

class GoalConfig {
  final String label;
  final String short;
  final String description;
  final double projectionDelta; // lbs over 6 weeks
  final Color color;

  const GoalConfig({
    required this.label,
    required this.short,
    required this.description,
    required this.projectionDelta,
    required this.color,
  });

  static final Map<GoalMode, GoalConfig> configs = {
    GoalMode.cut: const GoalConfig(
      label: 'Cut — Fat Loss Priority',
      short: 'Cut',
      description:
          'Calorie deficit, high protein, keep strength while dropping fat.',
      projectionDelta: -4.2,
      color: Color(0xFF6EE7B7), // emerald-300
    ),
    GoalMode.recomp: const GoalConfig(
      label: 'Recomp — Lean Rebuild',
      short: 'Recomp',
      description:
          'Small deficit or maintenance, higher protein, improve look without big scale changes.',
      projectionDelta: -1.8,
      color: Color(0xFF7DD3FC), // sky-300
    ),
    GoalMode.bulk: const GoalConfig(
      label: 'Bulk — Muscle Gain',
      short: 'Bulk',
      description:
          'Controlled surplus, heavy training, accept some fluff to build muscle.',
      projectionDelta: 3.0,
      color: Color(0xFFFCD34D), // amber-300
    ),
    GoalMode.strength: const GoalConfig(
      label: 'Strength — Performance First',
      short: 'Strength',
      description:
          'Nervous system, bar speed, performance. Body changes are a side effect.',
      projectionDelta: 0.5,
      color: Color(0xFFA5B4FC), // indigo-300
    ),
    GoalMode.athletic: const GoalConfig(
      label: 'Athletic — Move Like An Athlete',
      short: 'Athletic',
      description:
          'Power, speed, conditioning. You move better, joints feel better, look follows.',
      projectionDelta: -1.0,
      color: Color(0xFFFDA4AF), // rose-300
    ),
  };

  static GoalConfig get(GoalMode mode) {
    return configs[mode]!;
  }
}

enum EquipmentMode {
  bodyweight,
  dumbbells,
  gym,
}

class EquipmentConfig {
  final String label;
  final String description;

  const EquipmentConfig({
    required this.label,
    required this.description,
  });

  static final Map<EquipmentMode, EquipmentConfig> configs = {
    EquipmentMode.bodyweight: const EquipmentConfig(
      label: 'Bodyweight',
      description: 'No equipment. Floor, doorframe, maybe a chair.',
    ),
    EquipmentMode.dumbbells: const EquipmentConfig(
      label: 'Dumbbells',
      description: 'One pair or a small set of dumbbells.',
    ),
    EquipmentMode.gym: const EquipmentConfig(
      label: 'Full gym',
      description: 'Barbells, cables, machines, everything.',
    ),
  };

  static EquipmentConfig get(EquipmentMode mode) {
    return configs[mode]!;
  }
}

