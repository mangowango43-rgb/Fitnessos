import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/workout_schedule.dart';

/// Workout Alarm Service - Based on FutureYou's proven AlarmService
class WorkoutAlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'workout_alarms';
  static const String _channelName = 'Workout Alarms';
  static const String _channelDescription =
      'Alarm notifications for workout reminders';

  // Track scheduled alarms in memory for debugging
  static final Map<int, Map<String, dynamic>> _scheduledAlarms = {};

  /// Initialize alarm service - MUST be called from main()
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ WorkoutAlarmService already initialized');
      return;
    }

    try {
      debugPrint('🔧 Initializing WorkoutAlarmService...');

      // Request permissions
      final notifStatus = await Permission.notification.request();
      debugPrint('📱 Notification permission: $notifStatus');

      final alarmStatus = await Permission.scheduleExactAlarm.request();
      debugPrint('⏰ Exact alarm permission: $alarmStatus');

      // Initialize notification plugin
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

      // Create notification channel with MAXIMUM PRIORITY and SOUND
      const workoutChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.createNotificationChannel(workoutChannel);
      debugPrint('✅ Notification channel created');

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

  /// Schedule alarm for a workout schedule using FutureYou's exact logic
  static Future<void> scheduleAlarm(WorkoutSchedule schedule) async {
    if (!schedule.hasAlarm) {
      debugPrint('⏰ scheduleAlarm skipped: hasAlarm=false for "${schedule.workoutName}"');
      return;
    }

    if (schedule.scheduledTime == null || schedule.scheduledTime!.isEmpty) {
      debugPrint('❌ scheduleAlarm FAILED: time is EMPTY for "${schedule.workoutName}"');
      return;
    }

    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔔 scheduleAlarm called for "${schedule.workoutName}"');
      debugPrint('   - time: ${schedule.scheduledTime}');
      debugPrint('   - hasAlarm: ${schedule.hasAlarm}');
      debugPrint('   - repeatDays: ${schedule.repeatDays}');
      debugPrint('   - scheduledDate: ${schedule.scheduledDate}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Cancel existing alarms so we don't duplicate notifications
      await cancelAlarm(schedule.id);

      int successCount = 0;
      int failCount = 0;

      final timeOfDay = schedule.timeOfDay;
      if (timeOfDay == null) {
        debugPrint('❌ Invalid time format: ${schedule.scheduledTime}');
        return;
      }

      // If repeatDays is empty, schedule for specific date only (one-time)
      if (schedule.repeatDays.isEmpty) {
        debugPrint('📅 Scheduling ONE-TIME alarm for ${schedule.scheduledDate}');
        final alarmId = _getAlarmId(schedule.id, 0);
        
        // Create exact datetime for the scheduled date and time
        final scheduledTime = tz.TZDateTime(
          tz.local,
          schedule.scheduledDate.year,
          schedule.scheduledDate.month,
          schedule.scheduledDate.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );

        // Only schedule if it's in the future
        if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
          try {
            await _notifications.zonedSchedule(
              alarmId,
              '💪 ${schedule.workoutName}',
              '${_getMotivationalQuote()}\n\nTap to start your workout',
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
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: schedule.id,
            );

            successCount++;
            debugPrint('   ✅ SUCCESS - scheduled for $scheduledTime');

            _scheduledAlarms[alarmId] = {
              'workoutName': schedule.workoutName,
              'scheduleId': schedule.id,
              'day': 0,
              'time': schedule.scheduledTime,
              'scheduledAt': scheduledTime.toIso8601String(),
            };
          } catch (e) {
            failCount++;
            debugPrint('   ❌ ERROR: $e');
          }
        } else {
          debugPrint('   ⚠️ Skipped: time is in the past ($scheduledTime)');
        }
      } else {
        // Schedule for each repeat day (weekly recurring)
        debugPrint('📅 Scheduling RECURRING alarms for days: ${schedule.repeatDays}');
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
              '${_getMotivationalQuote()}\n\nTap to start your workout',
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
  }

  /// Cancel all alarms
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    _scheduledAlarms.clear();
    debugPrint('🗑️ All workout alarms cancelled');
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

  /// Get motivational quote
  static String _getMotivationalQuote() {
    const quotes = [
      "Your future self is counting on you.",
      "Discipline beats motivation.",
      "Consistency builds strength.",
      "Every rep brings you closer.",
      "Transform your body, transform your life.",
      "Future You is watching — train now.",
      "Make yourself proud today.",
      "One workout closer to your goals.",
    ];
    final index = DateTime.now().minute % quotes.length;
    return quotes[index];
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

  /// Get pending notifications for debugging
  static Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    return await _notifications.pendingNotificationRequests();
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
}
