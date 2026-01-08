import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/workout_models.dart';

class StorageService {
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyUser = 'user';
  static const String _keyUserName = 'user_name';
  static const String _keyUnitsMetric = 'units_metric';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyLockedWorkout = 'locked_workout';
  static const String _keyScheduledWorkouts = 'scheduled_workouts';
  static const String _keyWorkoutAlarms = 'workout_alarms';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Onboarding
  bool get hasCompletedOnboarding =>
      _prefs.getBool(_keyOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_keyOnboardingComplete, value);
  }

  // User data
  UserModel? getUser() {
    final jsonString = _prefs.getString(_keyUser);
    if (jsonString == null) return null;
    return UserModel.fromJson(jsonDecode(jsonString));
  }

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<void> clearUser() async {
    await _prefs.remove(_keyUser);
    await _prefs.remove(_keyOnboardingComplete);
  }

  // Settings
  bool get unitsMetric => _prefs.getBool(_keyUnitsMetric) ?? false;

  Future<void> setUnitsMetric(bool value) async {
    await _prefs.setBool(_keyUnitsMetric, value);
  }

  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_keyNotificationsEnabled, value);
  }

  // Locked Workout
  LockedWorkout? getLockedWorkout() {
    final jsonString = _prefs.getString(_keyLockedWorkout);
    if (jsonString == null) return null;
    try {
      return LockedWorkout.fromJson(jsonDecode(jsonString));
    } catch (e) {
      print('Error loading locked workout: $e');
      return null;
    }
  }

  Future<void> saveLockedWorkout(LockedWorkout workout) async {
    await _prefs.setString(_keyLockedWorkout, jsonEncode(workout.toJson()));
  }

  Future<void> clearLockedWorkout() async {
    await _prefs.remove(_keyLockedWorkout);
  }

  // User Name (static methods for easy access)
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  // Scheduled Workouts
  Future<void> scheduleWorkout(
    DateTime date,
    LockedWorkout workout,
    TimeOfDay? alarmTime,
    List<int> repeatDays,
  ) async {
    final scheduledWorkouts = getAllScheduledWorkouts();
    final dateKey = _dateToKey(date);
    
    scheduledWorkouts[dateKey] = workout;
    
    // Save workouts
    final workoutsJson = scheduledWorkouts.map(
      (key, value) => MapEntry(key, jsonEncode(value.toJson())),
    );
    await _prefs.setString(_keyScheduledWorkouts, jsonEncode(workoutsJson));
    
    // Save alarm info if provided
    if (alarmTime != null && repeatDays.isNotEmpty) {
      final alarmInfo = {
        'workoutId': workout.id,
        'hour': alarmTime.hour,
        'minute': alarmTime.minute,
        'repeatDays': repeatDays,
      };
      await _prefs.setString('alarm_$dateKey', jsonEncode(alarmInfo));
    }
  }

  LockedWorkout? getScheduledWorkout(DateTime date) {
    final dateKey = _dateToKey(date);
    final scheduledWorkouts = getAllScheduledWorkouts();
    return scheduledWorkouts[dateKey];
  }

  Map<String, LockedWorkout> getAllScheduledWorkouts() {
    final jsonString = _prefs.getString(_keyScheduledWorkouts);
    if (jsonString == null) return {};
    
    try {
      final Map<String, dynamic> workoutsJson = jsonDecode(jsonString);
      return workoutsJson.map((key, value) {
        return MapEntry(
          key,
          LockedWorkout.fromJson(jsonDecode(value)),
        );
      });
    } catch (e) {
      print('Error loading scheduled workouts: $e');
      return {};
    }
  }

  Future<void> cancelScheduledWorkout(DateTime date) async {
    final dateKey = _dateToKey(date);
    final scheduledWorkouts = getAllScheduledWorkouts();
    scheduledWorkouts.remove(dateKey);
    
    final workoutsJson = scheduledWorkouts.map(
      (key, value) => MapEntry(key, jsonEncode(value.toJson())),
    );
    await _prefs.setString(_keyScheduledWorkouts, jsonEncode(workoutsJson));
    await _prefs.remove('alarm_$dateKey');
  }

  Map<String, dynamic>? getWorkoutAlarm(DateTime date) {
    final dateKey = _dateToKey(date);
    final jsonString = _prefs.getString('alarm_$dateKey');
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error loading alarm info: $e');
      return null;
    }
  }

  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

