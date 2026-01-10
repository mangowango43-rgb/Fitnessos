// ═══════════════════════════════════════════════════════════════════════════
// FIXED main.dart - TIMEZONE PROPERLY CONFIGURED FOR ALARMS (FutureYou Method)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/v2_onboarding_main.dart';
import 'screens/auth/sign_in_screen.dart';
import 'services/workout_alarm_service.dart';
import 'models/workout_schedule.dart';

/// Initialize timezone using FutureYou's proven method
Future<void> _initTimezone() async {
  try {
    tzdata.initializeTimeZones();
    final String localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));
    debugPrint('✅ Timezone initialized: $localTz');
  } catch (e) {
    debugPrint('⚠️ Timezone fallback to UTC: $e');
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TIMEZONE SETUP - USING FUTUREYOU'S PROVEN METHOD!
  // ═══════════════════════════════════════════════════════════════════════════
  await _initTimezone();
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(WorkoutScheduleAdapter());
  
  // Open Hive boxes
  await Hive.openBox<WorkoutSchedule>('workout_schedules');
  
  // Initialize workout alarm service (must come AFTER timezone init)
  await WorkoutAlarmService.initialize();
  debugPrint('✅ WorkoutAlarmService initialized');
  
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
