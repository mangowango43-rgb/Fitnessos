import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/cyber_grid_background.dart';
import 'tabs/home_tab.dart';
import 'tabs/train_tab.dart';
import 'tabs/workouts_tab.dart';
import 'tabs/you_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    TrainTab(),
    WorkoutsTab(),
    YouTab(),
  ];

  final List<_TabInfo> _tabInfo = const [
    _TabInfo(icon: Icons.fitness_center, label: 'HOME'),
    _TabInfo(icon: Icons.videocam, label: 'TRAIN'),
    _TabInfo(icon: Icons.trending_up, label: 'WORKOUTS'),
    _TabInfo(icon: Icons.person, label: 'YOU'),
  ];

  @override
  Widget build(BuildContext context) {
    return CyberGridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _tabs[_currentIndex],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            border: const Border(
              top: BorderSide(color: AppColors.white10, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabInfo.length, (index) {
                  final tab = _tabInfo[index];
                  final isActive = _currentIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              transform: Matrix4.identity()
                                ..scale(isActive ? 1.1 : 1.0),
                              child: Icon(
                                tab.icon,
                                color: isActive
                                    ? AppColors.cyberLime
                                    : AppColors.white40,
                                size: 24,
                                shadows: isActive
                                    ? [
                                        Shadow(
                                          color: AppColors.cyberLime,
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tab.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: isActive
                                    ? AppColors.cyberLime
                                    : AppColors.white40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabInfo {
  final IconData icon;
  final String label;

  const _TabInfo({
    required this.icon,
    required this.label,
  });
}

