import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../models/user_model.dart';
import '../../models/goal_config.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';
import 'welcome_screen.dart';
import 'personal_info_screen.dart';
import 'goal_screen.dart';
import 'equipment_screen.dart';
import 'preferences_screen.dart';
import '../home_screen.dart';

class OnboardingMain extends ConsumerStatefulWidget {
  const OnboardingMain({super.key});

  @override
  ConsumerState<OnboardingMain> createState() => _OnboardingMainState();
}

class _OnboardingMainState extends ConsumerState<OnboardingMain> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // User data collected during onboarding
  String _name = '';
  int _age = 0;
  double _weight = 0.0;
  double _targetWeight = 0.0;
  GoalMode _goal = GoalMode.cut;
  EquipmentMode _equipment = EquipmentMode.bodyweight;
  String _experience = '';
  String _injuries = '';
  List<String> _preferredDays = [];
  String _dietary = '';

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final user = UserModel(
      name: _name,
      age: _age,
      weight: _weight,
      targetWeight: _targetWeight,
      goalMode: _goal,
      equipmentMode: _equipment,
      fitnessExperience: _experience,
      injuries: _injuries,
      preferredDays: _preferredDays,
      dietaryRestrictions: _dietary,
    );

    await ref.read(userProvider.notifier).updateUser(user);
    
    final storage = await ref.read(storageServiceProvider.future);
    await storage.setOnboardingComplete(true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            physics: const NeverScrollableScrollPhysics(),
            children: [
              WelcomeScreen(onNext: _nextPage),
              PersonalInfoScreen(
                onNext: _nextPage,
                onSave: (name, age, weight, target) {
                  _name = name;
                  _age = age;
                  _weight = weight;
                  _targetWeight = target;
                },
              ),
              GoalScreen(
                onNext: _nextPage,
                onSave: (goal) {
                  _goal = goal;
                },
              ),
              EquipmentScreen(
                onNext: _nextPage,
                onSave: (equipment) {
                  _equipment = equipment;
                },
              ),
              PreferencesScreen(
                onComplete: _completeOnboarding,
                onSave: (experience, injuries, days, dietary) {
                  _experience = experience;
                  _injuries = injuries;
                  _preferredDays = days;
                  _dietary = dietary;
                },
              ),
            ],
          ),
          if (_currentPage > 0)
            Positioned(
              top: 50,
              left: 16,
              child: SafeArea(
                child: IconButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 5,
                effect: const WormEffect(
                  dotWidth: 10,
                  dotHeight: 10,
                  activeDotColor: AppColors.amber400,
                  dotColor: AppColors.white20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

