import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/cyber_grid_background.dart';
import 'tabs/home_tab.dart';
import 'tabs/train_tab.dart';
import 'tabs/workouts_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  
  const HomeScreen({super.key, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final ValueNotifier<bool> _hideBottomNav = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  void dispose() {
    _hideBottomNav.dispose();
    super.dispose();
  }

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<_TabInfo> _tabInfo = const [
    _TabInfo(icon: Icons.home, label: 'HOME'),
    _TabInfo(icon: Icons.videocam, label: 'TRAIN'),
    _TabInfo(icon: Icons.fitness_center, label: 'WORKOUTS'),
    _TabInfo(icon: Icons.person, label: 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    // Create tabs dynamically so they rebuild with provider changes
    final tabs = [
      const HomeTab(),
      TrainTab(onWorkoutStateChanged: (isActive) {
        _hideBottomNav.value = isActive;
      }),
      const WorkoutsTab(),
      const ProfileTab(),
    ];

    return CyberGridBackground(
      child: TabNavigator(
        changeTab: changeTab,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: tabs[_currentIndex],
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: _hideBottomNav,
            builder: (context, hideNav, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: hideNav ? 0 : null,
                child: hideNav 
                    ? const SizedBox.shrink()
                    : child,
              );
            },
            child: Container(
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
                        behavior: HitTestBehavior.opaque, // Makes entire area touchable!
                        onTap: () {
                          changeTab(index);
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

// InheritedWidget to allow child widgets to change tabs
class TabNavigator extends InheritedWidget {
  final Function(int) changeTab;

  const TabNavigator({
    required this.changeTab,
    required super.child,
  });

  static TabNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabNavigator>();
  }

  @override
  bool updateShouldNotify(TabNavigator old) => changeTab != old.changeTab;
}

