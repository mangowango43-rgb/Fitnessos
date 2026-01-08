import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

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

      // Request permissions
      final notifStatus = await Permission.notification.request();
      debugPrint('📱 Notification permission: $notifStatus');

      final alarmStatus = await Permission.scheduleExactAlarm.request();
      debugPrint('⏰ Exact alarm permission: $alarmStatus');

      // Initialize notification plugin with FitnessOS icon
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
      debugPrint('✅ Workout notification channel created');

      _initialized = true;
      debugPrint('🎉 WorkoutAlarmService fully initialized!');
    } catch (e, stack) {
      debugPrint('❌ WorkoutAlarmService initialization failed: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Workout notification tapped: ${response.payload}');
    // TODO: Navigate to train tab when notification is tapped
  }

  /// Schedule weekly alarms for a workout
  static Future<void> scheduleWorkoutAlarm({
    required String workoutId,
    required String workoutName,
    required TimeOfDay time,
    required List<int> repeatDays, // 0-6 (Sunday-Saturday)
  }) async {
    if (repeatDays.isEmpty) {
      debugPrint('⏰ scheduleWorkoutAlarm skipped: no repeat days for "$workoutName"');
      return;
    }

    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔔 scheduleWorkoutAlarm called for "$workoutName"');
      debugPrint('   - time: ${time.hour}:${time.minute}');
      debugPrint('   - repeatDays: $repeatDays');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Cancel existing alarms so we don't duplicate notifications
      await cancelWorkoutAlarm(workoutId);

      int successCount = 0;
      int failCount = 0;

      // Schedule for each repeat day
      for (final day in repeatDays) {
        final alarmId = _getAlarmId(workoutId, day);
        final scheduledTime = _getNextAlarmTime(day, time);

        debugPrint('📅 Scheduling alarm for ${_getDayName(day)}:');
        debugPrint('   - alarmId: $alarmId');
        debugPrint('   - time: ${time.hour}:${time.minute}');
        debugPrint('   - next occurrence: $scheduledTime');

        try {
          await _notifications.zonedSchedule(
            alarmId,
            '🔥 Workout Time: $workoutName',
            '${_getMotivationalQuote()}\n\nTap to start your workout!',
            scheduledTime,
            NotificationDetails(
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
                largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                styleInformation: const BigTextStyleInformation(
                  '',
                  contentTitle: '🔥 Workout Time',
                  summaryText: 'FitnessOS',
                ),
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentSound: true,
                presentBadge: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: workoutId,
          );

          successCount++;
          debugPrint('   ✅ SUCCESS for ${_getDayName(day)}');

          // Track this alarm
          _scheduledAlarms[alarmId] = {
            'workoutName': workoutName,
            'workoutId': workoutId,
            'day': day,
            'time': '${time.hour}:${time.minute}',
            'scheduledAt': scheduledTime.toIso8601String(),
          };
        } catch (e) {
          failCount++;
          debugPrint('   ❌ ERROR for ${_getDayName(day)}: $e');
        }
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📊 Alarm scheduling summary for "$workoutName":');
      debugPrint('   ✅ Success: $successCount');
      debugPrint('   ❌ Failed: $failCount');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stack) {
      debugPrint('❌ scheduleWorkoutAlarm error: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Schedule ONE-TIME alarm for a specific date and time (not recurring)
  static Future<void> scheduleOneTimeWorkoutAlarm({
    required String workoutId,
    required String workoutName,
    required DateTime scheduledDate,
    required TimeOfDay time,
  }) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔔 scheduleOneTimeWorkoutAlarm called for "$workoutName"');
      debugPrint('   - date: ${scheduledDate.year}-${scheduledDate.month}-${scheduledDate.day}');
      debugPrint('   - time: ${time.hour}:${time.minute}');
      
      final alarmId = workoutId.hashCode.abs() % 2147483647;
      
      // Create exact datetime for the alarm
      final scheduledDateTime = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        time.hour,
        time.minute,
      );
      
      debugPrint('   - scheduledDateTime: $scheduledDateTime');
      debugPrint('   - alarmId: $alarmId');
      
      // Only schedule if in the future
      if (scheduledDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('⏰ Skipped: scheduled time is in the past');
        return;
      }
      
      await _notifications.zonedSchedule(
        alarmId,
        '🔥 Workout Time: $workoutName',
        '${_getMotivationalQuote()}\n\nTap to start your workout!',
        scheduledDateTime,
        NotificationDetails(
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
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: const BigTextStyleInformation(
              '',
              contentTitle: '🔥 Workout Time',
              summaryText: 'FitnessOS',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: workoutId,
      );
      
      debugPrint('   ✅ SUCCESS: One-time alarm scheduled');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Track this alarm
      _scheduledAlarms[alarmId] = {
        'workoutName': workoutName,
        'workoutId': workoutId,
        'scheduledDate': scheduledDate.toIso8601String(),
        'time': '${time.hour}:${time.minute}',
        'scheduledAt': scheduledDateTime.toIso8601String(),
      };
    } catch (e, stack) {
      debugPrint('❌ scheduleOneTimeWorkoutAlarm error: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Cancel all alarms for a workout
  static Future<void> cancelWorkoutAlarm(String workoutId) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🗑️ CANCELLING ALARMS for workout: $workoutId');
    
    // Get pending notifications BEFORE cancellation
    final pendingBefore = await _notifications.pendingNotificationRequests();
    final workoutAlarmIds = <int>[];
    
    for (int day = 0; day < 7; day++) {
      final id = _getAlarmId(workoutId, day);
      workoutAlarmIds.add(id);
    }
    
    final relevantBefore = pendingBefore.where((n) => workoutAlarmIds.contains(n.id)).toList();
    debugPrint('📊 Found ${relevantBefore.length} pending alarms for this workout');
    
    // Cancel each alarm with error handling
    int successCount = 0;
    int failCount = 0;
    
    for (int day = 0; day < 7; day++) {
      final id = _getAlarmId(workoutId, day);
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
    final relevantAfter = pendingAfter.where((n) => workoutAlarmIds.contains(n.id)).toList();
    
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📊 Cancellation Summary for workout: $workoutId');
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
  static int _getAlarmId(String workoutId, int day) {
    return ((workoutId.hashCode.abs() % 900000) + 100000) * 10 + day;
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

  /// Get fitness-focused motivational quote
  static String _getMotivationalQuote() {
    const quotes = [
      "Time to destroy your workout!",
      "Your body is capable of amazing things.",
      "Champions train when others rest.",
      "Every rep counts. Let's go!",
      "Consistency builds legends.",
      "The only bad workout is the one that didn't happen.",
      "Push yourself. Nobody else will do it for you.",
      "Transform your body, transform your life.",
      "No excuses. Just results.",
      "Beast mode: ACTIVATED.",
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
      debugPrint('🧪 SCHEDULING TEST WORKOUT ALARM');
      debugPrint('   - Current time: ${tz.TZDateTime.now(tz.local)}');
      debugPrint('   - Test alarm time: $testTime');
      debugPrint('   - Alarm ID: $testId');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      await _notifications.zonedSchedule(
        testId,
        '🧪 TEST WORKOUT ALARM',
        'This is a 1-minute test alarm. If you see this, workout alarms work!',
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
        'workoutId': 'test',
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

  /// Get scheduled alarms for debugging
  static List<Map<String, dynamic>> getScheduledAlarms() {
    return _scheduledAlarms.entries.map((entry) {
      return {
        'id': entry.key,
        'workoutName': entry.value['workoutName'] ?? 'Unknown',
        'workoutId': entry.value['workoutId'] ?? 'Unknown',
        'day': entry.value['day'] ?? 0,
      };
    }).toList();
  }
}
