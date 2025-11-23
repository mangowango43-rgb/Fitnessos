import 'package:sqflite/sqflite.dart';
import '../models/workout_session_model.dart';
import '../models/meal_model.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/fitnessos.db';
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        durationMinutes INTEGER,
        status TEXT NOT NULL,
        exercises TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        time TEXT NOT NULL,
        items TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  // Workout Sessions
  Future<void> insertWorkoutSession(WorkoutSession session) async {
    final db = await database;
    await db.insert(
      'workout_sessions',
      {
        'id': session.id,
        'name': session.name,
        'date': session.date.toIso8601String(),
        'durationMinutes': session.durationMinutes,
        'status': session.status.name,
        'exercises': session.exercises.map((e) => e.toJson()).toList().toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WorkoutSession>> getRecentWorkoutSessions({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workout_sessions',
      orderBy: 'date DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return WorkoutSession.fromJson(maps[i]);
    });
  }

  // Meals
  Future<void> insertMeal(Meal meal) async {
    final db = await database;
    await db.insert(
      'meals',
      {
        'id': meal.id,
        'name': meal.name,
        'time': meal.time,
        'items': meal.items,
        'calories': meal.calories,
        'protein': meal.protein,
        'date': meal.date.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Meal>> getMealsForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'time ASC',
    );

    return List.generate(maps.length, (i) {
      return Meal.fromJson(maps[i]);
    });
  }

  Future<void> deleteMeal(String id) async {
    final db = await database;
    await db.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

