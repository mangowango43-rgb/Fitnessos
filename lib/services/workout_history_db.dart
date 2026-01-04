import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import '../models/workout_session_model.dart';
import '../models/exercise_model.dart';

/// Database service for storing workout history
/// NO MOCK DATA - All data comes from real completed workouts
class WorkoutHistoryDB {
  static final WorkoutHistoryDB instance = WorkoutHistoryDB._init();
  static Database? _database;

  WorkoutHistoryDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workout_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final fullPath = path_helper.join(dbPath, filePath);

    return await openDatabase(
      fullPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Workout sessions table
    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        duration_minutes INTEGER,
        status TEXT NOT NULL,
        total_reps INTEGER DEFAULT 0,
        avg_form_score REAL DEFAULT 0.0,
        perfect_reps INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Exercise sets table (detailed rep data)
    await db.execute('''
      CREATE TABLE exercise_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        reps_completed INTEGER NOT NULL,
        reps_target INTEGER NOT NULL,
        form_score REAL DEFAULT 0.0,
        perfect_reps INTEGER DEFAULT 0,
        good_reps INTEGER DEFAULT 0,
        missed_reps INTEGER DEFAULT 0,
        max_combo INTEGER DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES workout_sessions (id)
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_session_date ON workout_sessions(date DESC)');
    await db.execute('CREATE INDEX idx_set_session ON exercise_sets(session_id)');
  }

  /// Save a completed workout session
  Future<void> saveWorkoutSession({
    required String id,
    required String name,
    required DateTime date,
    required int durationMinutes,
    required int totalReps,
    required double avgFormScore,
    required int perfectReps,
    required List<Map<String, dynamic>> sets,
  }) async {
    final db = await database;

    // Save session
    await db.insert(
      'workout_sessions',
      {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'duration_minutes': durationMinutes,
        'status': 'complete',
        'total_reps': totalReps,
        'avg_form_score': avgFormScore,
        'perfect_reps': perfectReps,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save exercise sets
    for (final set in sets) {
      await db.insert('exercise_sets', {
        'session_id': id,
        'exercise_name': set['exercise_name'],
        'set_number': set['set_number'],
        'reps_completed': set['reps_completed'],
        'reps_target': set['reps_target'],
        'form_score': set['form_score'] ?? 0.0,
        'perfect_reps': set['perfect_reps'] ?? 0,
        'good_reps': set['good_reps'] ?? 0,
        'missed_reps': set['missed_reps'] ?? 0,
        'max_combo': set['max_combo'] ?? 0,
      });
    }
  }

  /// Get total workouts completed
  Future<int> getTotalWorkouts() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM workout_sessions WHERE status = ?',
      ['complete'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get current streak (consecutive days with workouts)
  Future<int> getCurrentStreak() async {
    final db = await database;
    
    // Get all workout dates ordered by date descending
    final result = await db.query(
      'workout_sessions',
      columns: ['date'],
      where: 'status = ?',
      whereArgs: ['complete'],
      orderBy: 'date DESC',
    );

    if (result.isEmpty) return 0;

    int streak = 0;
    DateTime? lastDate;
    final today = DateTime.now();

    for (var row in result) {
      final date = DateTime.parse(row['date'] as String);
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      if (lastDate == null) {
        // First workout - check if it's today or yesterday
        final todayOnly = DateTime(today.year, today.month, today.day);
        final diff = todayOnly.difference(dateOnly).inDays;
        
        if (diff > 1) {
          // Streak is broken (workout was more than 1 day ago)
          return 0;
        }
        streak = 1;
        lastDate = dateOnly;
      } else {
        // Check if consecutive day
        final diff = lastDate.difference(dateOnly).inDays;
        if (diff == 1) {
          streak++;
          lastDate = dateOnly;
        } else {
          // Streak broken
          break;
        }
      }
    }

    return streak;
  }

  /// Get longest streak ever
  Future<int> getLongestStreak() async {
    final db = await database;
    
    final result = await db.query(
      'workout_sessions',
      columns: ['date'],
      where: 'status = ?',
      whereArgs: ['complete'],
      orderBy: 'date ASC',
    );

    if (result.isEmpty) return 0;

    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (var row in result) {
      final date = DateTime.parse(row['date'] as String);
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final diff = dateOnly.difference(lastDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
          currentStreak = 1;
        }
      }
      
      lastDate = dateOnly;
    }

    return currentStreak > longestStreak ? currentStreak : longestStreak;
  }

  /// Get total reps this week
  Future<int> getTotalRepsThisWeek() async {
    final db = await database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(total_reps) as total FROM workout_sessions WHERE date >= ? AND status = ?',
      [weekStartStr, 'complete'],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total reps last week
  Future<int> getTotalRepsLastWeek() async {
    final db = await database;
    final now = DateTime.now();
    final lastWeekEnd = now.subtract(Duration(days: now.weekday));
    final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
    
    final startStr = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day).toIso8601String();
    final endStr = DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(total_reps) as total FROM workout_sessions WHERE date >= ? AND date < ? AND status = ?',
      [startStr, endStr, 'complete'],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get workouts completed this week
  Future<int> getWorkoutsThisWeek() async {
    final db = await database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM workout_sessions WHERE date >= ? AND status = ?',
      [weekStartStr, 'complete'],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total training time (all time)
  Future<int> getTotalTrainingMinutes() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(duration_minutes) as total FROM workout_sessions WHERE status = ?',
      ['complete'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total lifetime reps
  Future<int> getTotalLifetimeReps() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total_reps) as total FROM workout_sessions WHERE status = ?',
      ['complete'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get average form score (last 10 workouts)
  Future<double> getAverageFormScore() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(avg_form_score) as avg FROM (SELECT avg_form_score FROM workout_sessions WHERE status = ? ORDER BY date DESC LIMIT 10)',
      ['complete'],
    );
    return (result.first['avg'] as double?) ?? 0.0;
  }

  /// Get last workout date
  Future<DateTime?> getLastWorkoutDate() async {
    final db = await database;
    final result = await db.query(
      'workout_sessions',
      columns: ['date'],
      where: 'status = ?',
      whereArgs: ['complete'],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return DateTime.parse(result.first['date'] as String);
  }

  /// Get recent workout sessions (for history list)
  Future<List<Map<String, dynamic>>> getRecentWorkouts({int limit = 10}) async {
    final db = await database;
    return await db.query(
      'workout_sessions',
      where: 'status = ?',
      whereArgs: ['complete'],
      orderBy: 'date DESC',
      limit: limit,
    );
  }

  /// Close database
  Future close() async {
    final db = await database;
    db.close();
  }
}

