import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/v2_onboarding_main.dart';
import 'screens/auth/sign_in_screen.dart';
import 'services/workout_alarm_service.dart';
import 'models/workout_schedule.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive (like FutureYou)
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(WorkoutScheduleAdapter());
  
  // Open Hive boxes
  await Hive.openBox<WorkoutSchedule>('workout_schedules');
  
  // Initialize timezone database
  tz.initializeTimeZones();
  
  // Initialize workout alarm service
  await WorkoutAlarmService.initialize();
  
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
      // Start with onboarding for now (change to home once onboarding is seen)
      initialRoute: '/onboarding',
      routes: {
        '/': (context) => const HomeScreen(),
        '/onboarding': (context) => const V2OnboardingMain(),
        '/signin': (context) => const SignInScreen(),
      },
    );
  }
}
