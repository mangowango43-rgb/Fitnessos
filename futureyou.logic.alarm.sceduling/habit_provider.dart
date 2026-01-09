import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'habit_engine.dart';
import 'local_storage.dart';

final habitEngineProvider = ChangeNotifierProvider<HabitEngine>((ref) {
  final engine = HabitEngine(LocalStorageService());
  // Auto-load habits when provider is created
  engine.loadHabits();
  return engine;
});
