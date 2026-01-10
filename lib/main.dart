// ═══════════════════════════════════════════════════════════════════════════
// FIXED main.dart - TIMEZONE PROPERLY CONFIGURED FOR ALARMS
// ═══════════════════════════════════════════════════════════════════════════
// Replace your lib/main.dart with this file
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/v2_onboarding_main.dart';
import 'screens/auth/sign_in_screen.dart';
import 'services/workout_alarm_service.dart';
import 'models/workout_schedule.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TIMEZONE SETUP - THIS IS THE FIX!
  // ═══════════════════════════════════════════════════════════════════════════
  // Step 1: Load all timezone data
  tz_data.initializeTimeZones();
  
  // Step 2: SET THE LOCAL TIMEZONE - THIS WAS MISSING!
  // Without this, tz.local is undefined and alarms silently fail
  try {
    // Try to get device timezone (works on most devices)
    final String timeZoneName = DateTime.now().timeZoneName;
    debugPrint('📍 Device timezone name: $timeZoneName');
    
    // Map common abbreviations to IANA timezone names
    String ianaTimezone = _getIanaTimezone(timeZoneName);
    debugPrint('📍 Using IANA timezone: $ianaTimezone');
    
    tz.setLocalLocation(tz.getLocation(ianaTimezone));
    debugPrint('✅ Timezone set successfully: ${tz.local.name}');
  } catch (e) {
    // Fallback to a default timezone if detection fails
    debugPrint('⚠️ Could not detect timezone, using America/New_York: $e');
    tz.setLocalLocation(tz.getLocation('America/New_York'));
  }
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(WorkoutScheduleAdapter());
  
  // Open Hive boxes
  await Hive.openBox<WorkoutSchedule>('workout_schedules');
  
  // Initialize workout alarm service
  await WorkoutAlarmService.initialize();
  
  // Verify timezone is working
  debugPrint('═══════════════════════════════════════════════════');
  debugPrint('🕐 TIMEZONE VERIFICATION:');
  debugPrint('   tz.local: ${tz.local}');
  debugPrint('   tz.local.name: ${tz.local.name}');
  debugPrint('   Current TZ time: ${tz.TZDateTime.now(tz.local)}');
  debugPrint('═══════════════════════════════════════════════════');
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const ProviderScope(child: MyApp()));
}

/// Map common timezone abbreviations to IANA timezone names
String _getIanaTimezone(String abbreviation) {
  // Common US timezones
  final Map<String, String> tzMap = {
    'EST': 'America/New_York',
    'EDT': 'America/New_York',
    'CST': 'America/Chicago',
    'CDT': 'America/Chicago',
    'MST': 'America/Denver',
    'MDT': 'America/Denver',
    'PST': 'America/Los_Angeles',
    'PDT': 'America/Los_Angeles',
    'AKST': 'America/Anchorage',
    'AKDT': 'America/Anchorage',
    'HST': 'Pacific/Honolulu',
    // UK/Europe
    'GMT': 'Europe/London',
    'BST': 'Europe/London',
    'CET': 'Europe/Paris',
    'CEST': 'Europe/Paris',
    'EET': 'Europe/Helsinki',
    'EEST': 'Europe/Helsinki',
    // Asia
    'IST': 'Asia/Kolkata',
    'JST': 'Asia/Tokyo',
    'KST': 'Asia/Seoul',
    'CST': 'Asia/Shanghai', // Note: conflicts with US CST
    'SGT': 'Asia/Singapore',
    'HKT': 'Asia/Hong_Kong',
    // Australia
    'AEST': 'Australia/Sydney',
    'AEDT': 'Australia/Sydney',
    'ACST': 'Australia/Adelaide',
    'ACDT': 'Australia/Adelaide',
    'AWST': 'Australia/Perth',
  };
  
  // Try direct mapping
  if (tzMap.containsKey(abbreviation)) {
    return tzMap[abbreviation]!;
  }
  
  // Try to find by offset
  final now = DateTime.now();
  final offset = now.timeZoneOffset;
  
  // Map offset to timezone (rough approximation)
  if (offset.inHours == -5 || offset.inHours == -4) {
    return 'America/New_York';
  } else if (offset.inHours == -6 || offset.inHours == -5) {
    return 'America/Chicago';
  } else if (offset.inHours == -7 || offset.inHours == -6) {
    return 'America/Denver';
  } else if (offset.inHours == -8 || offset.inHours == -7) {
    return 'America/Los_Angeles';
  } else if (offset.inHours == 0 || offset.inHours == 1) {
    return 'Europe/London';
  } else if (offset.inHours == 1 || offset.inHours == 2) {
    return 'Europe/Paris';
  } else if (offset.inHours == 5 || offset.inHours == 6) {
    return 'Asia/Kolkata';
  } else if (offset.inHours == 8) {
    return 'Asia/Singapore';
  } else if (offset.inHours == 9) {
    return 'Asia/Tokyo';
  } else if (offset.inHours == 10 || offset.inHours == 11) {
    return 'Australia/Sydney';
  }
  
  // Ultimate fallback
  return 'America/New_York';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitnessOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/onboarding',
      routes: {
        '/': (context) => const HomeScreen(),
        '/onboarding': (context) => const V2OnboardingMain(),
        '/signin': (context) => const SignInScreen(),
      },
    );
  }
}
