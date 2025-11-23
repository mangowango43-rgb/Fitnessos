import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_model.dart';
import 'user_provider.dart';
import '../models/goal_config.dart';

final nutritionDayProvider = StateProvider<NutritionDay>((ref) {
  final user = ref.watch(userProvider);
  
  // Mock meals
  final meals = [
    Meal(
      id: '1',
      name: 'Breakfast',
      time: '7:30',
      items: 'Eggs, toast, coffee',
      calories: 420,
      protein: 32,
      date: DateTime.now(),
    ),
    Meal(
      id: '2',
      name: 'Lunch',
      time: '12:45',
      items: 'Chicken salad, rice',
      calories: 680,
      protein: 48,
      date: DateTime.now(),
    ),
    Meal(
      id: '3',
      name: 'Snack',
      time: '3:20',
      items: 'Protein shake',
      calories: 240,
      protein: 38,
      date: DateTime.now(),
    ),
  ];

  final todayCalories = meals.fold(0, (sum, meal) => sum + meal.calories);
  final protein = meals.fold(0, (sum, meal) => sum + meal.protein);

  return NutritionDay(
    date: DateTime.now(),
    targetCalories: 2100,
    targetProtein: 180,
    todayCalories: todayCalories,
    protein: protein,
    carbs: 186,
    fats: 62,
    meals: meals,
  );
});

final fuelAnalysisProvider = Provider<Map<String, String>>((ref) {
  final nutrition = ref.watch(nutritionDayProvider);
  final user = ref.watch(userProvider);
  
  if (user == null) {
    return {
      'label': 'No Data',
      'mood': 'Complete onboarding to see insights',
      'risk': '',
    };
  }

  final calorieRatio = nutrition.calorieRatio;
  final proteinRatio = nutrition.proteinRatio;
  final goalMode = user.goalMode;

  String label = '';
  String mood = '';
  String risk = '';

  if (goalMode == GoalMode.bulk) {
    if (calorieRatio < 0.95) {
      label = 'Underfed Bulk';
      mood = 'You chose muscle gain, but you are still closer to a deficit.';
      risk = 'Low chance of building the size you want at this intake.';
    } else if (proteinRatio < 0.8) {
      label = 'Soft Bulk';
      mood = 'Calories are there, but protein is lagging behind.';
      risk = 'More fat gain than muscle if this repeats.';
    } else {
      label = 'Prime Gain Window';
      mood = 'Calories and protein are aligned with muscle gain.';
      risk = 'Watch weekends — easy to overshoot beyond "clean bulk."';
    }
  } else if (goalMode == GoalMode.cut || goalMode == GoalMode.recomp) {
    if (calorieRatio < 0.8 && proteinRatio >= 0.8) {
      label = 'Clean Deficit';
      mood = 'You are eating below target but protecting muscle with protein.';
      risk = 'Low binge risk if you don\'t let hunger pile up late at night.';
    } else if (calorieRatio > 1.05 && proteinRatio < 0.7) {
      label = 'Soft Binge Pattern';
      mood = 'Calories are drifting up while protein stays low.';
      risk = 'High chance of weekend spiral and water weight rebound.';
    } else if (calorieRatio > 1.05) {
      label = 'Overfeed Drift';
      mood = 'Small surpluses stacking on top of each other.';
      risk = 'The cut slows quietly here, then "suddenly" stalls.';
    } else {
      label = 'On Track';
      mood = 'Calories are controlled and directionally sound.';
      risk = 'Moderate — evenings and weekends still decide the outcome.';
    }
  } else {
    // STRENGTH / ATHLETIC
    if (proteinRatio < 0.8) {
      label = 'Under-fuelled Performance';
      mood = 'You\'re asking your nervous system for more than your protein supports.';
      risk = 'Plateaus, joint aches, and fatigue will show up first, then missed sessions.';
    } else if (calorieRatio < 0.85) {
      label = 'Light but Sharp';
      mood = 'You\'re a bit under on calories, but protein is holding the line.';
      risk = 'Performance okay short term, but long blocks like this need deloads.';
    } else {
      label = 'Performance Fuelled';
      mood = 'Enough intake for your goal if sleep and stress don\'t fall apart.';
      risk = 'Main risk is lifestyle creep — late nights, skipped warm-ups, rushed sessions.';
    }
  }

  return {
    'label': label,
    'mood': mood,
    'risk': risk,
  };
});

