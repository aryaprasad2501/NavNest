import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/demo_mode_service.dart';
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

  void _openFocusScreen({
    String? subject,
    String? chapter,
    String? subtopic,
    String? linkedTaskId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FocusScreen(
          onSessionComplete: () => setState(() => _currentIndex = 1),
          initialSubject: subject,
          initialChapter: chapter,
          initialSubtopic: subtopic,
          linkedTaskId: linkedTaskId,
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
        onOpenNavBloom: () => _navigateToIndex(1),
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

    final demoService = context.watch<DemoModeService>();

    return Scaffold(
      body: Column(
        children: [
          if (demoService.isDemoMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFD97706),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Icon(Icons.science_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'DEMO MODE ACTIVE • 30 Sample Trees & Syllabus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await demoService.exitDemoMode(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Restored to your genuine personal data.'),
                              backgroundColor: Color(0xFF2E7D32),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Text(
                          'Exit Demo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: SmoothTabSwitchView(
              currentIndex: _currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NestBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateToIndex,
      ),
    );
  }
}

/// Animated tab transition container that preserves state for all tabs (like IndexedStack)
/// while delivering silky-smooth cross-fade and directional slide transitions between tabs.
class SmoothTabSwitchView extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const SmoothTabSwitchView({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  State<SmoothTabSwitchView> createState() => _SmoothTabSwitchViewState();
}

class _SmoothTabSwitchViewState extends State<SmoothTabSwitchView> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
        value: i == widget.currentIndex ? 1.0 : 0.0,
      ),
    );
    _fadeAnimations = _controllers.map((c) => CurvedAnimation(
      parent: c,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    )).toList();
    _slideAnimations = _controllers.map((c) => Tween<Offset>(
      begin: const Offset(0.0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: c,
      curve: Curves.easeOutCubic,
    ))).toList();
  }

  @override
  void didUpdateWidget(covariant SmoothTabSwitchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final oldIdx = oldWidget.currentIndex;
      final newIdx = widget.currentIndex;
      final direction = newIdx > oldIdx ? 1.0 : -1.0;
      _slideAnimations[newIdx] = Tween<Offset>(
        begin: Offset(direction * 0.035, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controllers[newIdx],
        curve: Curves.easeOutCubic,
      ));
      _controllers[oldIdx].reverse();
      _controllers[newIdx].forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (index) {
        final isCurrent = index == widget.currentIndex;
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            final val = _controllers[index].value;
            final isOffstage = val == 0.0 && !isCurrent;
            return Offstage(
              offstage: isOffstage,
              child: TickerMode(
                enabled: !isOffstage,
                child: IgnorePointer(
                  ignoring: !isCurrent,
                  child: FadeTransition(
                    opacity: _fadeAnimations[index],
                    child: SlideTransition(
                      position: _slideAnimations[index],
                      child: widget.children[index],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
