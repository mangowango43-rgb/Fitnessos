class Meal {
  final String id;
  final String name;
  final String time;
  final String items;
  final int calories;
  final int protein;
  final DateTime date;

  const Meal({
    required this.id,
    required this.name,
    required this.time,
    required this.items,
    required this.calories,
    required this.protein,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'items': items,
      'calories': calories,
      'protein': protein,
      'date': date.toIso8601String(),
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      name: json['name'],
      time: json['time'],
      items: json['items'],
      calories: json['calories'],
      protein: json['protein'],
      date: DateTime.parse(json['date']),
    );
  }
}

class NutritionDay {
  final DateTime date;
  final int targetCalories;
  final int targetProtein;
  final int todayCalories;
  final int protein;
  final int carbs;
  final int fats;
  final List<Meal> meals;

  const NutritionDay({
    required this.date,
    required this.targetCalories,
    required this.targetProtein,
    required this.todayCalories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.meals,
  });

  double get calorieRatio => todayCalories / targetCalories;
  double get proteinRatio => protein / targetProtein;
}

