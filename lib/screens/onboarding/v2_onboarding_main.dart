import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart';
import '../../widgets/premium_animations.dart';
import '../home_screen.dart';

/// Elite high-converting onboarding flow
/// Following Cal AI style: Long setup = high commitment
class V2OnboardingMain extends ConsumerStatefulWidget {
  const V2OnboardingMain({super.key});

  @override
  ConsumerState<V2OnboardingMain> createState() => _V2OnboardingMainState();
}

class _V2OnboardingMainState extends ConsumerState<V2OnboardingMain> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 20;

  // Collected data throughout onboarding
  String? _selectedGoal;
  String? _experienceLevel;
  List<String> _selectedConstraints = [];
  int _daysPerWeek = 3;
  int _minutesPerSession = 30;
  List<String> _motivations = [];
  String? _accountability;
  String? _coachingStyle;
  Map<String, String> _schedule = {};
  bool _hasCreatedAccount = false;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      HapticFeedback.mediumImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            children: [
              _buildSocialProofScreen(),
              _buildQualifierScreen(),
              _buildIdentityScreen(),
              _buildCurrentStateScreen(),
              _buildConstraintsScreen(),
              _buildTimeCommitmentScreen(),
              _buildMotivationScreen(),
              _buildAccountabilityScreen(),
              _buildCoachingStyleScreen(),
              _buildScheduleScreen(),
              _buildCameraPermissionScreen(),
              _buildPhonePositionScreen(),
              _buildBodyCalibrationScreen(),
              _buildQuickTestScreen(),
              _buildResultsScreen(),
              _buildAccountCreationScreen(),
              _buildIdentityReinforcementScreen(),
              _buildCustomPlanScreen(),
              _buildPreWorkoutCountdownScreen(),
              _buildCompletionScreen(),
            ],
          ),

          // Progress bar at top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                    ),
                  if (_currentPage > 0) const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _totalPages,
                        backgroundColor: AppColors.white10,
                        valueColor: const AlwaysStoppedAnimation(AppColors.cyberLime),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PHASE 1: THE HOOK

  Widget _buildSocialProofScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Placeholder for video/animation
          SlideUpAnimation(
            delay: 100,
            child: Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cyberLime, width: 2),
                color: AppColors.white5,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline, size: 64, color: AppColors.cyberLime),
                    SizedBox(height: 16),
                    Text(
                      '[Demo Video Here]',
                      style: TextStyle(color: AppColors.white40, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          SlideUpAnimation(
            delay: 200,
            child: const Text(
              'Join 100,000+ Athletes',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          SlideUpAnimation(
            delay: 300,
            child: const Text(
              'Who never miss a workout',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.white60,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          // Testimonials
          _buildTestimonialRow('🔥 "365 day streak"', 'Mike'),
          const SizedBox(height: 12),
          _buildTestimonialRow('💪 "Form improved 40%"', 'Sarah'),
          const SizedBox(height: 12),
          _buildTestimonialRow('⚡ "Never felt stronger"', 'James'),
          const Spacer(),
          _buildPrimaryButton(
            text: 'Get Started',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 12),
          const Text(
            'Takes 5 minutes to personalize',
            style: TextStyle(color: AppColors.white40, fontSize: 14),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQualifierScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyberLime, width: 3),
            ),
            child: const Icon(Icons.fitness_center, color: AppColors.cyberLime, size: 40),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'FitnessOS is for people who are serious about results',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "We'll ask you some questions to build your perfect training plan.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.white60,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This takes about 5 minutes.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white40,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildPrimaryButton(
            text: "I'm Serious - Let's Go",
            onPressed: _nextPage,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skipToHome,
            child: const Text(
              'Not ready? Skip for now',
              style: TextStyle(color: AppColors.white40, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // PHASE 2: DEEP PERSONALIZATION

  Widget _buildIdentityScreen() {
    final goals = [
      {'id': 'lean', 'emoji': '📦', 'title': 'The Lean Machine', 'subtitle': 'Burn fat, build definition'},
      {'id': 'strength', 'emoji': '💪', 'title': 'The Strength Beast', 'subtitle': 'Pure power and muscle'},
      {'id': 'athletic', 'emoji': '🏃', 'title': 'The Athletic', 'subtitle': 'Functional fitness, agility'},
      {'id': 'balanced', 'emoji': '🧘', 'title': 'The Balanced', 'subtitle': 'Strength + flexibility + endurance'},
    ];

    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            'Who are you training\nto become?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final isSelected = _selectedGoal == goal['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildSelectableCard(
                    emoji: goal['emoji']!,
                    title: goal['title']!,
                    subtitle: goal['subtitle']!,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedGoal = goal['id']);
                    },
                  ),
                );
              },
            ),
          ),
          _buildPrimaryButton(
            text: 'Continue',
            onPressed: _selectedGoal != null ? _nextPage : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCurrentStateScreen() {
    final levels = ['Beginner', 'Intermediate', 'Advanced', 'Elite'];
    
    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            'Where are you\nstarting from?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: levels.map((level) {
                final isSelected = _experienceLevel == level;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: _buildLevelButton(
                    text: level,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _experienceLevel = level);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          _buildPrimaryButton(
            text: "That's Me",
            onPressed: _experienceLevel != null ? _nextPage : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildConstraintsScreen() {
    final constraints = [
      {'id': 'home', 'text': "I'm at home (no equipment)"},
      {'id': 'dumbbells', 'text': 'I have dumbbells/resistance bands'},
      {'id': 'gym', 'text': 'I have a gym membership'},
      {'id': 'injuries', 'text': 'I have injuries/limitations'},
    ];

    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            "What's your\nsituation?",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Select all that apply',
            style: TextStyle(color: AppColors.white60, fontSize: 16),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              itemCount: constraints.length,
              itemBuilder: (context, index) {
                final constraint = constraints[index];
                final isSelected = _selectedConstraints.contains(constraint['id']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCheckboxCard(
                    text: constraint['text']!,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedConstraints.remove(constraint['id']);
                        } else {
                          _selectedConstraints.add(constraint['id']!);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          _buildPrimaryButton(
            text: 'Continue',
            onPressed: _selectedConstraints.isNotEmpty ? _nextPage : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimeCommitmentScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            "Let's be honest\nabout time",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          const Text(
            'Days per week you can ACTUALLY commit',
            style: TextStyle(color: AppColors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDaySelector(),
          const SizedBox(height: 60),
          const Text(
            'Minutes per session',
            style: TextStyle(color: AppColors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildMinuteSelector(),
          const Spacer(),
          _buildPrimaryButton(
            text: 'Lock It In',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMotivationScreen() {
    final motivations = [
      'I want to look better',
      'I want to feel stronger',
      'Doctor told me to',
      "I'm tired of being inconsistent",
      'I want to prove something to myself',
      "I'm training for something specific",
    ];

    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            'Why are you\nreally here?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Select all that apply',
            style: TextStyle(color: AppColors.white60, fontSize: 16),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              itemCount: motivations.length,
              itemBuilder: (context, index) {
                final motivation = motivations[index];
                final isSelected = _motivations.contains(motivation);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCheckboxCard(
                    text: motivation,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _motivations.remove(motivation);
                        } else {
                          _motivations.add(motivation);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          _buildPrimaryButton(
            text: "That's My Why",
            onPressed: _motivations.isNotEmpty ? _nextPage : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAccountabilityScreen() {
    final options = [
      {'id': 'streaks', 'emoji': '🔥', 'title': 'Streaks', 'subtitle': "Don't break the chain"},
      {'id': 'achievements', 'emoji': '🏆', 'title': 'Achievements', 'subtitle': 'Unlock rewards'},
      {'id': 'progress', 'emoji': '📊', 'title': 'Progress', 'subtitle': 'See the numbers go up'},
      {'id': 'competition', 'emoji': '👥', 'title': 'Competition', 'subtitle': 'Beat my friends'},
    ];

    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            'What keeps you\naccountable?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = _accountability == option['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildSelectableCard(
                    emoji: option['emoji']!,
                    title: option['title']!,
                    subtitle: option['subtitle']!,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _accountability = option['id']);
                    },
                  ),
                );
              },
            ),
          ),
          _buildPrimaryButton(
            text: 'Continue',
            onPressed: _accountability != null ? _nextPage : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCoachingStyleScreen() {
    final styles = [
      {'id': 'sergeant', 'emoji': '🎖️', 'title': 'The Drill Sergeant', 'quote': "PUSH! Don't quit!"},
      {'id': 'hype', 'emoji': '🔥', 'title': 'The Hype Man', 'quote': "You're a BEAST!"},
      {'id': 'zen', 'emoji': '🧘', 'title': 'The Zen Master', 'quote': 'Breathe. Focus.'},
      {'id': 'science', 'emoji': '🔬', 'title': 'The Science Coach', 'quote': 'Good form. 87% depth.'},
    ];

    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            'Pick your coach\npersonality',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final style = styles[index];
                final isSelected = _coachingStyle == style['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildSelectableCard(
                    emoji: style['emoji']!,
                    title: style['title']!,
                    subtitle: style['quote']!,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _coachingStyle = style['id']);
                    },
                  ),
                );
              },
            ),
          ),
          _buildPrimaryButton(
            text: 'Select',
            onPressed: _coachingStyle != null ? _nextPage : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScheduleScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            'When do you\nwant to train?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            "We'll remind you. Don't let yourself down.",
            style: TextStyle(color: AppColors.white60, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.white20),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 64, color: AppColors.cyberLime),
                    SizedBox(height: 16),
                    Text(
                      '[Calendar Picker Here]',
                      style: TextStyle(color: AppColors.white40, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildPrimaryButton(
            text: 'Set My Schedule',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // PHASE 3: CAMERA SETUP

  Widget _buildCameraPermissionScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.electricCyan, width: 3),
              color: AppColors.electricCyan.withOpacity(0.1),
            ),
            child: const Icon(Icons.camera_alt, color: AppColors.electricCyan, size: 60),
          ),
          const SizedBox(height: 32),
          const Text(
            'Now for the\nmagic part...',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                _FeatureRow(icon: Icons.check_circle, text: 'Count your reps perfectly'),
                SizedBox(height: 16),
                _FeatureRow(icon: Icons.check_circle, text: 'Analyze your form in real-time'),
                SizedBox(height: 16),
                _FeatureRow(icon: Icons.check_circle, text: 'Give you PT-level coaching'),
              ],
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'We need camera access.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildPrimaryButton(
            text: 'Enable Camera',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "We NEVER record or save video.\nYour privacy is sacred.",
              style: TextStyle(color: AppColors.white40, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhonePositionScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            'How to set up\nyour phone',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.white20),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_android, size: 80, color: AppColors.cyberLime),
                    SizedBox(height: 24),
                    _SetupTip(number: '1', text: 'Prop phone against something stable'),
                    SizedBox(height: 16),
                    _SetupTip(number: '2', text: 'Portrait mode'),
                    SizedBox(height: 16),
                    _SetupTip(number: '3', text: 'Step back so full body is visible'),
                    SizedBox(height: 16),
                    _SetupTip(number: '4', text: 'Good lighting'),
                  ],
                ),
              ),
            ),
          ),
          _buildPrimaryButton(
            text: 'Got It',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBodyCalibrationScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Text(
            'Let me see you...',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            height: 400,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.electricCyan, width: 2),
              color: AppColors.white5,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera, size: 64, color: AppColors.electricCyan),
                  SizedBox(height: 16),
                  Text(
                    '[Camera Preview Here]',
                    style: TextStyle(color: AppColors.white40, fontSize: 14),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Do 3 poses to calibrate:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  _CalibrationStep(step: '1. Stand normally', done: true),
                  _CalibrationStep(step: '2. Reach arms up high', done: false),
                  _CalibrationStep(step: '3. Do a squat', done: false),
                ],
              ),
            ),
          ),
          const Spacer(),
          _buildPrimaryButton(
            text: 'Skip Calibration',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // PHASE 4: DEMO

  Widget _buildQuickTestScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Text(
            "Let's test this out",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            "Do 5 pushups.\nI'll count and coach you.",
            style: TextStyle(
              fontSize: 18,
              color: AppColors.white70,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            height: 400,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cyberLime, width: 2),
              color: AppColors.white5,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '[Camera + Tracking]',
                    style: TextStyle(color: AppColors.white40, fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Rep Count: 0/5',
                    style: TextStyle(
                      color: AppColors.cyberLime,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _buildPrimaryButton(
            text: 'Start Test',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            '🎉',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 24),
          const Text(
            'NICE!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.cyberLime,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'You just did 5 pushups with:',
            style: TextStyle(color: AppColors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildStatRow('⭐', '87% form score'),
          const SizedBox(height: 16),
          _buildStatRow('🔥', '3 perfect reps'),
          const SizedBox(height: 16),
          _buildStatRow('⚡', '2-combo streak'),
          const SizedBox(height: 60),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Imagine tracking every workout like this.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          _buildPrimaryButton(
            text: "I'm In - Let's Go",
            onPressed: _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // PHASE 5: ACCOUNT CREATION

  Widget _buildAccountCreationScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "We just spent 8 minutes building YOUR perfect plan",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Create a free account so you don't lose this.",
            style: TextStyle(color: AppColors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                _buildSocialButton(
                  icon: Icons.g_mobiledata,
                  text: 'Continue with Google',
                  color: Colors.white,
                  onPressed: () {
                    setState(() => _hasCreatedAccount = true);
                    _nextPage();
                  },
                ),
                const SizedBox(height: 16),
                _buildSocialButton(
                  icon: Icons.apple,
                  text: 'Continue with Apple',
                  color: Colors.white,
                  onPressed: () {
                    setState(() => _hasCreatedAccount = true);
                    _nextPage();
                  },
                ),
                const SizedBox(height: 16),
                _buildSocialButton(
                  icon: Icons.email_outlined,
                  text: 'Continue with Email',
                  color: AppColors.cyberLime,
                  onPressed: () {
                    setState(() => _hasCreatedAccount = true);
                    _nextPage();
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your data is private and never sold.',
              style: TextStyle(color: AppColors.white40, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _nextPage,
            child: const Text(
              'Skip for now',
              style: TextStyle(color: AppColors.white40, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildIdentityReinforcementScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyberLime, width: 4),
              color: AppColors.cyberLime.withOpacity(0.1),
            ),
            child: const Center(
              child: Text(
                '💪',
                style: TextStyle(fontSize: 64),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to\nFitnessOS',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            "You're not a beginner anymore.",
            style: TextStyle(
              fontSize: 18,
              color: AppColors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "You're a FitnessOS Athlete.",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.cyberLime,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  'Athlete #102,847',
                  style: TextStyle(
                    color: AppColors.cyberLime,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Started: Jan 4, 2026',
                  style: TextStyle(color: AppColors.white50, fontSize: 14),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildPrimaryButton(
            text: "Let's Train",
            onPressed: _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCustomPlanScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Text(
            'Your Custom Plan',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Based on everything you told me',
              style: TextStyle(color: AppColors.white60, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cyberLime, width: 2),
                borderRadius: BorderRadius.circular(24),
                color: AppColors.white5,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week 1-2: Foundation Phase',
                    style: TextStyle(
                      color: AppColors.cyberLime,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  _WorkoutDayRow(day: 'Mon', workout: 'Upper Body', duration: '20 min'),
                  SizedBox(height: 16),
                  _WorkoutDayRow(day: 'Wed', workout: 'Lower Body', duration: '20 min'),
                  SizedBox(height: 16),
                  _WorkoutDayRow(day: 'Fri', workout: 'Full Body', duration: '20 min'),
                  Spacer(),
                  Text(
                    'This will evolve as you progress.',
                    style: TextStyle(color: AppColors.white50, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildPrimaryButton(
            text: 'Start Week 1, Day 1',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPreWorkoutCountdownScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Text(
            'Get ready...',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            '5',
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.w900,
              color: AppColors.cyberLime,
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            'Starting your first workout...',
            style: TextStyle(color: AppColors.white60, fontSize: 16),
          ),
          const Spacer(),
          TextButton(
            onPressed: _nextPage,
            child: const Text(
              'Skip countdown',
              style: TextStyle(color: AppColors.white40),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return _OnboardingScreenTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Text(
            '🔥',
            style: TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 24),
          const Text(
            'Onboarding Complete!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.cyberLime,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "You're all set.\nLet's build something legendary.",
              style: TextStyle(
                fontSize: 18,
                color: AppColors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          _buildPrimaryButton(
            text: 'Go to Home',
            onPressed: _skipToHome,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // HELPER WIDGETS

  Widget _buildPrimaryButton({required String text, VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: onPressed != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onPressed();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed != null ? AppColors.cyberLime : AppColors.white20,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialRow(String text, String author) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            '- $author',
            style: const TextStyle(color: AppColors.white50, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableCard({
    required String emoji,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.cyberLime : AppColors.white20,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppColors.cyberLime.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.cyberLime, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.cyberLime : AppColors.white20,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppColors.cyberLime.withOpacity(0.1) : Colors.transparent,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? AppColors.cyberLime : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxCard({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.cyberLime : AppColors.white20,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.cyberLime.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.cyberLime : AppColors.white40,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
                color: isSelected ? AppColors.cyberLime : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (index) {
        final day = index + 1;
        final isSelected = day == _daysPerWeek;
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _daysPerWeek = day);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.cyberLime : AppColors.white10,
              border: Border.all(
                color: isSelected ? AppColors.cyberLime : AppColors.white20,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMinuteSelector() {
    final options = [15, 30, 45, 60];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((minutes) {
        final isSelected = minutes == _minutesPerSession;
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _minutesPerSession = minutes);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? AppColors.cyberLime : AppColors.white10,
              border: Border.all(
                color: isSelected ? AppColors.cyberLime : AppColors.white20,
                width: 2,
              ),
            ),
            child: Text(
              '$minutes min',
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatRow(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 48),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widgets

class _OnboardingScreenTemplate extends StatelessWidget {
  final Widget child;

  const _OnboardingScreenTemplate({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.cyberGradient,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                        MediaQuery.of(context).padding.top - 
                        MediaQuery.of(context).padding.bottom,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cyberLime, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _SetupTip extends StatelessWidget {
  final String number;
  final String text;

  const _SetupTip({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cyberLime, width: 2),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.cyberLime,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _CalibrationStep extends StatelessWidget {
  final String step;
  final bool done;

  const _CalibrationStep({required this.step, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            color: done ? AppColors.cyberLime : AppColors.white40,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            step,
            style: TextStyle(
              color: done ? AppColors.cyberLime : AppColors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutDayRow extends StatelessWidget {
  final String day;
  final String workout;
  final String duration;

  const _WorkoutDayRow({
    required this.day,
    required this.workout,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.cyberLime.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cyberLime),
          ),
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                color: AppColors.cyberLime,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workout,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                duration,
                style: const TextStyle(
                  color: AppColors.white50,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

