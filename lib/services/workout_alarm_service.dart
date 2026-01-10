import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/workout_schedule.dart';

/// EXACT COPY of FutureYou AlarmService, adapted for WorkoutSchedule
class WorkoutAlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'workout_alarms';
  static const String _channelName = 'Workout Alarms';
  static const String _channelDescription =
      'Alarm notifications for workout reminders';

  // Track scheduled alarms in memory
  static final Map<int, Map<String, dynamic>> _scheduledAlarms = {};

  /// Initialize alarm service - MUST be called from main()
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ WorkoutAlarmService already initialized');
      return;
    }

    try {
      debugPrint('🔧 Initializing WorkoutAlarmService...');

      // Initialize notification plugin FIRST
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      debugPrint('✅ Notification plugin initialized');

      // Get Android plugin for platform-specific setup
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Request notification permission (Android 13+)
        final notifGranted = await androidPlugin.requestNotificationsPermission();
        debugPrint('📱 Notification permission granted: $notifGranted');
        
        // Request exact alarm permission (Android 12+)
        final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
        debugPrint('⏰ Exact alarm permission granted: $alarmGranted');
        
        // Create notification channel with MAXIMUM PRIORITY
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        );
        debugPrint('✅ Notification channel created');
      } else {
        debugPrint('⚠️ Android plugin not available (iOS or web?)');
      }

      _initialized = true;
      debugPrint('🎉 WorkoutAlarmService fully initialized!');
    } catch (e, stack) {
      debugPrint('❌ WorkoutAlarmService initialization failed: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
  }

  /// Schedule weekly alarms for a workout using local notifications only
  /// Uses EXACT logic from FutureYou
  static Future<void> scheduleAlarm(WorkoutSchedule schedule) async {
    debugPrint('═══════════════════════════════════════════════════════════════════');
    debugPrint('🔔 scheduleAlarm() CALLED');
    debugPrint('═══════════════════════════════════════════════════════════════════');
    
    if (!schedule.hasAlarm) {
      debugPrint('⏰ scheduleAlarm skipped: hasAlarm=false for "${schedule.workoutName}"');
      return;
    }

    if (schedule.scheduledTime == null || schedule.scheduledTime!.isEmpty) {
      debugPrint('❌ scheduleAlarm FAILED: time is EMPTY for "${schedule.workoutName}"');
      return;
    }

    if (schedule.repeatDays.isEmpty) {
      debugPrint('❌ scheduleAlarm FAILED: repeatDays is EMPTY for "${schedule.workoutName}"');
      debugPrint('   This is the bug! repeatDays must contain at least one day.');
      return;
    }

    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔔 scheduleAlarm called for "${schedule.workoutName}"');
      debugPrint('   - time: ${schedule.scheduledTime}');
      debugPrint('   - hasAlarm: ${schedule.hasAlarm}');
      debugPrint('   - repeatDays: ${schedule.repeatDays}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Cancel existing alarms so we don't duplicate notifications
      await cancelAlarm(schedule.id);

      int successCount = 0;
      int failCount = 0;

      // Check timeOfDay is valid before scheduling
      final timeOfDay = schedule.timeOfDay;
      if (timeOfDay == null) {
        debugPrint('❌ Failed to parse time from: ${schedule.scheduledTime}');
        return;
      }

      // Schedule for each repeat day
      for (final day in schedule.repeatDays) {
        final alarmId = _getAlarmId(schedule.id, day);
        final scheduledTime = _getNextAlarmTime(day, timeOfDay);

        debugPrint('📅 Scheduling alarm for ${_getDayName(day)}:');
        debugPrint('   - alarmId: $alarmId');
        debugPrint('   - time: ${schedule.scheduledTime}');
        debugPrint('   - next occurrence: $scheduledTime');

        try {
          await _notifications.zonedSchedule(
            alarmId,
            '💪 ${schedule.workoutName}',
            'Time to train! 🔥\n\nTap to start your workout',
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                channelDescription: _channelDescription,
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                enableLights: true,
                fullScreenIntent: true,
                ongoing: false,
                autoCancel: true,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentSound: true,
                presentBadge: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: schedule.id,
          );

          successCount++;
          debugPrint('   ✅ SUCCESS for ${_getDayName(day)}');

          // Track this alarm for debugging
          _scheduledAlarms[alarmId] = {
            'workoutName': schedule.workoutName,
            'scheduleId': schedule.id,
            'day': day,
            'time': schedule.scheduledTime,
            'scheduledAt': scheduledTime.toIso8601String(),
          };
        } catch (e) {
          failCount++;
          debugPrint('   ❌ ERROR for ${_getDayName(day)}: $e');
        }
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📊 Alarm scheduling summary for "${schedule.workoutName}":');
      debugPrint('   ✅ Success: $successCount');
      debugPrint('   ❌ Failed: $failCount');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stack) {
      debugPrint('❌ scheduleAlarm error: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Cancel all alarms for a schedule
  static Future<void> cancelAlarm(String scheduleId) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🗑️ CANCELLING ALARMS for schedule: $scheduleId');
    
    // Get pending notifications BEFORE cancellation
    final pendingBefore = await _notifications.pendingNotificationRequests();
    final scheduleAlarmIds = <int>[];
    
    for (int day = 0; day < 7; day++) {
      final id = _getAlarmId(scheduleId, day);
      scheduleAlarmIds.add(id);
    }
    
    final relevantBefore = pendingBefore.where((n) => scheduleAlarmIds.contains(n.id)).toList();
    debugPrint('📊 Found ${relevantBefore.length} pending alarms for this schedule');
    
    // Cancel each alarm with error handling
    int successCount = 0;
    int failCount = 0;
    
    for (int day = 0; day < 7; day++) {
      final id = _getAlarmId(scheduleId, day);
      try {
        await _notifications.cancel(id);
        _scheduledAlarms.remove(id);
        successCount++;
        debugPrint('   ✅ Cancelled alarm ID $id (${_getDayName(day)})');
      } catch (e) {
        failCount++;
        debugPrint('   ❌ Failed to cancel alarm ID $id (${_getDayName(day)}): $e');
      }
    }
    
    // Verify cancellation at OS level
    final pendingAfter = await _notifications.pendingNotificationRequests();
    final relevantAfter = pendingAfter.where((n) => scheduleAlarmIds.contains(n.id)).toList();
    
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📊 Cancellation Summary for schedule: $scheduleId');
    debugPrint('   ✅ Successfully cancelled: $successCount');
    debugPrint('   ❌ Failed to cancel: $failCount');
    debugPrint('   📋 Pending BEFORE: ${relevantBefore.length}');
    debugPrint('   📋 Pending AFTER: ${relevantAfter.length}');
    debugPrint('   ${relevantAfter.isEmpty ? "✅ All alarms verified cancelled!" : "⚠️ WARNING: ${relevantAfter.length} alarms still pending!"}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Throw error if verification failed
    if (relevantAfter.isNotEmpty) {
      throw Exception('Failed to cancel all alarms: ${relevantAfter.length} still pending');
    }
  }

  /// Cancel all alarms
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    _scheduledAlarms.clear();
    debugPrint('🗑️ All alarms cancelled');
  }

  /// Get next alarm time (tz-aware) for a given day and time
  static tz.TZDateTime _getNextAlarmTime(int weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    final targetWeekday = weekday == 0 ? DateTime.sunday : weekday;

    while (scheduled.weekday != targetWeekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Generate unique alarm ID
  static int _getAlarmId(String scheduleId, int day) {
    return ((scheduleId.hashCode.abs() % 900000) + 100000) * 10 + day;
  }

  /// Get day name for logging
  static String _getDayName(int day) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[day];
  }

  /// Schedule a test alarm (fires in 1 minute)
  static Future<void> scheduleTestAlarm() async {
    try {
      final testTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
      const testId = 999999;

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🧪 SCHEDULING TEST ALARM');
      debugPrint('   - Current time: ${tz.TZDateTime.now(tz.local)}');
      debugPrint('   - Test alarm time: $testTime');
      debugPrint('   - Alarm ID: $testId');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      await _notifications.zonedSchedule(
        testId,
        '🧪 TEST ALARM',
        'This is a 1-minute test alarm. If you see this, alarms work!',
        testTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('✅ Test alarm scheduled successfully!');
      debugPrint('⏰ Should fire at: $testTime');

      // Track test alarm
      _scheduledAlarms[testId] = {
        'workoutName': '🧪 TEST ALARM',
        'scheduleId': 'test',
        'day': 0,
        'time': '${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}',
        'scheduledAt': testTime.toIso8601String(),
      };
    } catch (e, stack) {
      debugPrint('❌ Test alarm error: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Check if service is initialized
  static bool isInitialized() {
    return _initialized;
  }

  /// Verify that a specific schedule's alarms are fully cancelled
  static Future<bool> verifyAlarmCancelled(String scheduleId) async {
    final scheduleAlarmIds = <int>[];
    for (int day = 0; day < 7; day++) {
      scheduleAlarmIds.add(_getAlarmId(scheduleId, day));
    }
    
    final pending = await _notifications.pendingNotificationRequests();
    final stillPending = pending.where((n) => scheduleAlarmIds.contains(n.id)).toList();
    
    if (stillPending.isNotEmpty) {
      debugPrint('⚠️ verifyAlarmCancelled FAILED for $scheduleId: ${stillPending.length} alarms still pending');
      for (final alarm in stillPending) {
        debugPrint('   - Pending alarm ID: ${alarm.id}');
      }
      return false;
    }
    
    debugPrint('✅ verifyAlarmCancelled SUCCESS for $scheduleId: All alarms cleared');
    return true;
  }

  /// Expose scheduled alarms for debugging
  static List<Map<String, dynamic>> getScheduledAlarms() {
    return _scheduledAlarms.entries.map((entry) {
      return {
        'id': entry.key,
        'workoutName': entry.value['workoutName'] ?? 'Unknown',
        'scheduleId': entry.value['scheduleId'] ?? 'Unknown',
        'day': entry.value['day'] ?? 0,
      };
    }).toList();
  }

  /// Get ALL pending notification requests from the OS
  static Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📋 PENDING NOTIFICATIONS FROM OS:');
    debugPrint('   Total count: ${pending.length}');
    for (final notif in pending) {
      debugPrint('   - ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    return pending.map((notif) => {
      'id': notif.id,
      'title': notif.title,
      'body': notif.body,
      'payload': notif.payload,
    }).toList();
  }
}
