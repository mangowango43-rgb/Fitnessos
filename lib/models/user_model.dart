import 'goal_config.dart';

class UserModel {
  final String name;
  final int age;
  final double weight;
  final double targetWeight;
  final GoalMode goalMode;
  final EquipmentMode equipmentMode;
  final String fitnessExperience;
  final String injuries;
  final List<String> preferredDays;
  final String dietaryRestrictions;
  
  // Stats
  final int dayStreak;
  final int compliance;
  final int readiness;
  final List<int> weekPattern;
  final double trainingHours;
  final double netflixHours;

  const UserModel({
    required this.name,
    required this.age,
    required this.weight,
    required this.targetWeight,
    required this.goalMode,
    required this.equipmentMode,
    this.fitnessExperience = '',
    this.injuries = '',
    this.preferredDays = const [],
    this.dietaryRestrictions = '',
    this.dayStreak = 1,
    this.compliance = 67,
    this.readiness = 74,
    this.weekPattern = const [85, 78, 92, 65, 70, 45, 67],
    this.trainingHours = 0,
    this.netflixHours = 2.4,
  });

  UserModel copyWith({
    String? name,
    int? age,
    double? weight,
    double? targetWeight,
    GoalMode? goalMode,
    EquipmentMode? equipmentMode,
    String? fitnessExperience,
    String? injuries,
    List<String>? preferredDays,
    String? dietaryRestrictions,
    int? dayStreak,
    int? compliance,
    int? readiness,
    List<int>? weekPattern,
    double? trainingHours,
    double? netflixHours,
  }) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      goalMode: goalMode ?? this.goalMode,
      equipmentMode: equipmentMode ?? this.equipmentMode,
      fitnessExperience: fitnessExperience ?? this.fitnessExperience,
      injuries: injuries ?? this.injuries,
      preferredDays: preferredDays ?? this.preferredDays,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      dayStreak: dayStreak ?? this.dayStreak,
      compliance: compliance ?? this.compliance,
      readiness: readiness ?? this.readiness,
      weekPattern: weekPattern ?? this.weekPattern,
      trainingHours: trainingHours ?? this.trainingHours,
      netflixHours: netflixHours ?? this.netflixHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'weight': weight,
      'targetWeight': targetWeight,
      'goalMode': goalMode.name,
      'equipmentMode': equipmentMode.name,
      'fitnessExperience': fitnessExperience,
      'injuries': injuries,
      'preferredDays': preferredDays,
      'dietaryRestrictions': dietaryRestrictions,
      'dayStreak': dayStreak,
      'compliance': compliance,
      'readiness': readiness,
      'weekPattern': weekPattern,
      'trainingHours': trainingHours,
      'netflixHours': netflixHours,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      age: json['age'],
      weight: json['weight'],
      targetWeight: json['targetWeight'],
      goalMode: GoalMode.values.firstWhere((e) => e.name == json['goalMode']),
      equipmentMode:
          EquipmentMode.values.firstWhere((e) => e.name == json['equipmentMode']),
      fitnessExperience: json['fitnessExperience'] ?? '',
      injuries: json['injuries'] ?? '',
      preferredDays: List<String>.from(json['preferredDays'] ?? []),
      dietaryRestrictions: json['dietaryRestrictions'] ?? '',
      dayStreak: json['dayStreak'] ?? 1,
      compliance: json['compliance'] ?? 67,
      readiness: json['readiness'] ?? 74,
      weekPattern: List<int>.from(json['weekPattern'] ?? [85, 78, 92, 65, 70, 45, 67]),
      trainingHours: json['trainingHours'] ?? 0,
      netflixHours: json['netflixHours'] ?? 2.4,
    );
  }
}

