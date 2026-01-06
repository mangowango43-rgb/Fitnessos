import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

/// Service for managing workout video recordings
class WorkoutRecordingService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'workout_recordings.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recordings (
            id TEXT PRIMARY KEY,
            workoutName TEXT NOT NULL,
            videoPath TEXT NOT NULL,
            thumbnailPath TEXT,
            duration INTEGER NOT NULL,
            recordedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Save a new workout recording
  static Future<void> saveRecording({
    required String workoutName,
    required String videoPath,
    String? thumbnailPath,
    required Duration duration,
  }) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('recordings', {
      'id': id,
      'workoutName': workoutName,
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'duration': duration.inSeconds,
      'recordedAt': DateTime.now().toIso8601String(),
    });

    debugPrint('✅ Saved recording: $workoutName ($id)');
  }

  /// Get all recordings
  static Future<List<WorkoutRecording>> getRecordings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recordings',
      orderBy: 'recordedAt DESC',
    );

    return maps.map((map) => WorkoutRecording.fromMap(map)).toList();
  }

  /// Delete a recording
  static Future<void> deleteRecording(String id) async {
    final db = await database;
    
    // Get recording to delete files
    final recording = await db.query(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (recording.isNotEmpty) {
      final videoPath = recording.first['videoPath'] as String;
      final thumbnailPath = recording.first['thumbnailPath'] as String?;

      // Delete video file
      final videoFile = File(videoPath);
      if (await videoFile.exists()) {
        await videoFile.delete();
      }

      // Delete thumbnail file
      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }
    }

    // Delete from database
    await db.delete(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
    );

    debugPrint('🗑️ Deleted recording: $id');
  }

  /// Get recordings directory
  static Future<Directory> getRecordingsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/workout_recordings');
    
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    
    return recordingsDir;
  }
}

/// Model for a workout recording
class WorkoutRecording {
  final String id;
  final String workoutName;
  final String videoPath;
  final String? thumbnailPath;
  final Duration duration;
  final DateTime recordedAt;

  WorkoutRecording({
    required this.id,
    required this.workoutName,
    required this.videoPath,
    this.thumbnailPath,
    required this.duration,
    required this.recordedAt,
  });

  factory WorkoutRecording.fromMap(Map<String, dynamic> map) {
    return WorkoutRecording(
      id: map['id'] as String,
      workoutName: map['workoutName'] as String,
      videoPath: map['videoPath'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      duration: Duration(seconds: map['duration'] as int),
      recordedAt: DateTime.parse(map['recordedAt'] as String),
    );
  }
}

