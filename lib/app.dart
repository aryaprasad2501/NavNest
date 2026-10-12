import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/nest_bottom_nav_bar.dart';
import 'features/focus/presentation/focus_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/navbloom/presentation/navbloom_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/planner/presentation/planner_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/shared_space/presentation/shared_space_screen.dart';
import 'features/syllabus/presentation/syllabus_screen.dart';

class NavNestApp extends StatelessWidget {
  const NavNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: true);
    final localStorage = Provider.of<LocalStorageService>(context, listen: false);

    return MaterialApp(
      title: 'NavNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      home: localStorage.isFirstLaunch
          ? const OnboardingScreen()
          : const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() => _currentIndex = index);
  }

  void _openFocusScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FocusScreen(
          onSessionComplete: () => setState(() => _currentIndex = 1),
        ),
      ),
    );
  }

  void _openSettingsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onOpenFocus: _openFocusScreen,
        onOpenPlanner: () => _navigateToIndex(2),
        onOpenSyllabus: () => _navigateToIndex(3),
        onOpenSettings: _openSettingsScreen,
      ),
      NavBloomScreen(
        onStartTimer: _openFocusScreen,
      ),
      PlannerScreen(
        onStartFocus: _openFocusScreen,
      ),
      const SyllabusScreen(),
      const SharedSpaceScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NestBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateToIndex,
      ),
    );
  }
}
