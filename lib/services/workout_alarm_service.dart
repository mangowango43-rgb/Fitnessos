import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/workout_schedule.dart';

/// Alarm service for workout notifications
/// Based on FutureYou's alarm system
class WorkoutAlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'workout_alarms';
  static const String _channelName = 'Workout Reminders';
  static const String _channelDescription = 'Notifications for scheduled workouts';

  /// Initialize alarm service
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

      // Create notification channel with MAX PRIORITY
      const channel = AndroidNotificationChannel(
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
      
      await androidPlugin?.createNotificationChannel(channel);
      debugPrint('✅ Notification channel created');

      _initialized = true;
      debugPrint('🎉 WorkoutAlarmService fully initialized!');
    } catch (e, stack) {
      debugPrint('❌ WorkoutAlarmService initialization failed: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Workout notification tapped: ${response.payload}');
    // TODO: Navigate to workout
  }

  /// Schedule alarm for a workout
  static Future<void> scheduleWorkoutAlarm(WorkoutSchedule schedule) async {
    if (!schedule.hasAlarm || schedule.scheduledTime == null) {
      debugPrint('⏰ scheduleWorkoutAlarm skipped: no alarm or time set');
      return;
    }

    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔔 Scheduling alarm for "${schedule.workoutName}"');
      debugPrint('   - Date: ${schedule.formattedDate}');
      debugPrint('   - Time: ${schedule.scheduledTime}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Cancel existing alarm if any
      await cancelWorkoutAlarm(schedule.id);

      // Parse time
      final timeParts = schedule.scheduledTime!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Create scheduled time
      final scheduledTime = tz.TZDateTime(
        tz.local,
        schedule.scheduledDate.year,
        schedule.scheduledDate.month,
        schedule.scheduledDate.day,
        hour,
        minute,
      );

      // Don't schedule if time is in the past
      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('⚠️ Scheduled time is in the past, skipping');
        return;
      }

      debugPrint('📅 Will fire at: $scheduledTime');

      // Get motivational quote (can't be called in const context)
      final motivationalText = '${_getMotivationalQuote()}\n\nTap to start your workout!';

      await _notifications.zonedSchedule(
        schedule.alarmId,
        '💪 ${schedule.workoutName}',
        motivationalText,
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
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(motivationalText),
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
        payload: schedule.workoutId,
      );

      debugPrint('✅ Alarm scheduled successfully!');
    } catch (e, stack) {
      debugPrint('❌ scheduleWorkoutAlarm error: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Cancel alarm for a workout
  static Future<void> cancelWorkoutAlarm(String scheduleId) async {
    try {
      final alarmId = WorkoutSchedule(
        id: scheduleId,
        workoutId: '',
        workoutName: '',
        scheduledDate: DateTime.now(),
        createdAt: DateTime.now(),
      ).alarmId;

      await _notifications.cancel(alarmId);
      debugPrint('✅ Cancelled alarm for schedule: $scheduleId');
    } catch (e) {
      debugPrint('❌ Failed to cancel alarm: $e');
    }
  }

  /// Cancel all alarms
  static Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ All workout alarms cancelled');
  }

  /// Get motivational quote for notifications
  static String _getMotivationalQuote() {
    const quotes = [
      "Time to get STRONGER! 💪",
      "Your body is listening. Let's go! 🔥",
      "Greatness awaits. START NOW! ⚡",
      "Transform your body. Transform your life! 🚀",
      "No excuses. Just results! 💯",
      "Beast mode: ACTIVATED! 🦾",
      "Crush your goals TODAY! 🎯",
      "Your future self will thank you! ⭐",
      "Limits? We don't know them! 🌟",
      "Sweat now. Shine later! ✨",
    ];
    final index = DateTime.now().minute % quotes.length;
    return quotes[index];
  }

  /// Check if service is initialized
  static bool isInitialized() {
    return _initialized;
  }

  /// Get pending alarms (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    return await _notifications.pendingNotificationRequests();
  }
}

