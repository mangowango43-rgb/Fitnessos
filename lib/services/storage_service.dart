import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyUser = 'user';
  static const String _keyUnitsMetric = 'units_metric';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

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
}

