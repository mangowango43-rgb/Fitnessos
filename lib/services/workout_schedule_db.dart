import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/workout_schedule.dart';

/// Database service for workout scheduling
/// Persistent storage with NO LIMITS on schedule length
class WorkoutScheduleDB {
  static final WorkoutScheduleDB instance = WorkoutScheduleDB._init();
  static Database? _database;

  WorkoutScheduleDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workout_schedules.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workout_schedules (
        id TEXT PRIMARY KEY,
        workoutId TEXT NOT NULL,
        workoutName TEXT NOT NULL,
        scheduledDate TEXT NOT NULL,
        scheduledTime TEXT,
        hasAlarm INTEGER NOT NULL DEFAULT 0,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create index for faster date queries
    await db.execute('''
      CREATE INDEX idx_scheduled_date 
      ON workout_schedules(scheduledDate)
    ''');
  }

  /// Add or update a scheduled workout
  Future<void> saveSchedule(WorkoutSchedule schedule) async {
    final db = await database;
    await db.insert(
      'workout_schedules',
      schedule.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get schedule by ID
  Future<WorkoutSchedule?> getSchedule(String id) async {
    final db = await database;
    final results = await db.query(
      'workout_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return WorkoutSchedule.fromJson(results.first);
  }

  /// Get all schedules for a specific date
  Future<List<WorkoutSchedule>> getSchedulesForDate(DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    
    final results = await db.query(
      'workout_schedules',
      where: 'scheduledDate = ?',
      whereArgs: [dateStr],
      orderBy: 'scheduledTime ASC',
    );

    return results.map((json) => WorkoutSchedule.fromJson(json)).toList();
  }

  /// Get all schedules in a date range
  Future<List<WorkoutSchedule>> getSchedulesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day).toIso8601String();
    
    final results = await db.query(
      'workout_schedules',
      where: 'scheduledDate >= ? AND scheduledDate <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'scheduledDate ASC, scheduledTime ASC',
    );

    return results.map((json) => WorkoutSchedule.fromJson(json)).toList();
  }

  /// Get today's scheduled workouts
  Future<List<WorkoutSchedule>> getTodaysSchedules() async {
    return getSchedulesForDate(DateTime.now());
  }

  /// Get upcoming schedules (next 30 days)
  Future<List<WorkoutSchedule>> getUpcomingSchedules() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thirtyDaysLater = today.add(const Duration(days: 30));
    
    return getSchedulesInRange(today, thirtyDaysLater);
  }

  /// Get all schedules (NO LIMIT)
  Future<List<WorkoutSchedule>> getAllSchedules() async {
    final db = await database;
    final results = await db.query(
      'workout_schedules',
      orderBy: 'scheduledDate ASC, scheduledTime ASC',
    );

    return results.map((json) => WorkoutSchedule.fromJson(json)).toList();
  }

  /// Mark schedule as completed
  Future<void> markAsCompleted(String scheduleId) async {
    final db = await database;
    await db.update(
      'workout_schedules',
      {'isCompleted': 1},
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    final db = await database;
    await db.delete(
      'workout_schedules',
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  /// Delete all schedules
  Future<void> deleteAllSchedules() async {
    final db = await database;
    await db.delete('workout_schedules');
  }

  /// Get count of schedules
  Future<int> getScheduleCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM workout_schedules');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get count of pending (not completed) schedules
  Future<int> getPendingScheduleCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM workout_schedules WHERE isCompleted = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

