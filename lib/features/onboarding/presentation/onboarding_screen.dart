import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../navbloom/presentation/providers/forest_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final bool startWithSplash;
  const OnboardingScreen({super.key, this.startWithSplash = true});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showingSplash = true;

  final TextEditingController _nameController = TextEditingController(text: 'Arya');
  int _selectedTargetMinutes = 120; // Default: 2 Hours

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _showingSplash = widget.startWithSplash;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_showingSplash) {
      Timer(const Duration(milliseconds: 2200), () {
        if (mounted) {
          setState(() => _showingSplash = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final enteredName = _nameController.text.trim();
    final studentName = enteredName.isNotEmpty ? enteredName : 'Arya 🌿';

    final auth = context.read<AuthService>();
    final forest = context.read<ForestProvider>();
    final localStorage = context.read<LocalStorageService>();

    // 1. Mark clean slate flag
    if (!localStorage.isCleanSlatePurged) {
      await localStorage.setCleanSlatePurged();
    }

    // 2. Save fresh student profile with clean slate (0 XP, 0 coins, 0 streak)
    final baseProfile = auth.currentUser ?? UserProfile.defaultProfile();
    final updatedProfile = baseProfile.copyWith(
      displayName: studentName,
      streakDays: baseProfile.streakDays,
      bestStreak: baseProfile.bestStreak,
      totalXp: baseProfile.totalXp,
      coins: baseProfile.coins,
      dailyTargetMinutes: _selectedTargetMinutes,
      updatedAt: DateTime.now(),
    );

    await auth.updateProfile(updatedProfile);
    forest.updateUserProfile(updatedProfile);

    // 3. Mark first launch complete
    await localStorage.setDailyTargetMinutes(_selectedTargetMinutes);
    await localStorage.setFirstLaunchComplete();

    // 4. Reload forest
    await forest.loadForestData();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showingSplash) {
      return _buildSplashScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.darkCanvas,
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF143022),
                    Color(0xFF09140D),
                  ],
                ),
              ),
            ),
          ),

          // PageView Carousel
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildSlide(
                  emblem: '🏮',
                  title: 'Welcome to\nNavNest',
                  subtitle: 'Your study journey, now\nmore beautiful.',
                  illustrationWidget: _buildLanternPathIllustration(),
                ),
                _buildSlide(
                  emblem: '🌱',
                  title: 'Focus & Grow',
                  subtitle: 'Study with focus\nand grow your forest.',
                  illustrationWidget: _buildFocusGrowIllustration(),
                ),
                _buildSlide(
                  emblem: '📖',
                  title: 'Plan, Track, Achieve',
                  subtitle: 'Syllabus, tasks, exams\nand more.',
                  illustrationWidget: _buildPlanAchieveIllustration(),
                ),
                _buildSetupSlide(),
              ],
            ),
          ),

          // Bottom Control Area (Dots + Next/Get Started)
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pagination Dots
                Row(
                  children: List.generate(4, (index) {
                    final isActive = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.sageLight : AppColors.darkBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // Button: Next or Get Started
                if (_currentPage < 3)
                  FilledButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amberWarm,
                      foregroundColor: AppColors.deepForestDark,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedFull),
                    ),
                    child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  )
                else
                  FilledButton(
                    onPressed: _completeOnboarding,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amberWarm,
                      foregroundColor: AppColors.deepForestDark,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedFull),
                    ),
                    child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      body: Stack(
        children: [
          // Background ambient radial glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0),
                  radius: 0.9,
                  colors: [
                    Color(0xFF133323),
                    Color(0xFF060F09),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.safeGreen.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1B3D2B),
                          border: Border.all(color: AppColors.sageLight, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.safeGreen.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Text('🌱', style: TextStyle(fontSize: 48)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'NavNest',
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.ivoryCanvas,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Study Today, A Better Tomorrow',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 0.8,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required String emblem,
    required String title,
    required String subtitle,
    required Widget illustrationWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Center(child: illustrationWidget)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.darkTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSetupSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSpaceForTwoIllustration(),
            const SizedBox(height: 16),
            Text(
              'A Space for Two',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.darkTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share, support and grow together.',
              style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Profile Setup Container
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: AppRadius.roundedL,
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Scholar Name',
                    style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.darkSurface,
                      hintText: 'Enter name (e.g. Arya)',
                      hintStyle: TextStyle(color: AppColors.darkTextMuted),
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.sageLight, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Daily Focus Target',
                    style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [60, 120, 180, 240].map((mins) {
                      final isSel = _selectedTargetMinutes == mins;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTargetMinutes = mins),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.forestEmerald : AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSel ? AppColors.sageGreen : AppColors.darkBorder),
                          ),
                          child: Text(
                            '${mins ~/ 60}h',
                            style: TextStyle(
                              color: isSel ? Colors.white : AppColors.darkTextSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildLanternPathIllustration() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.darkSurface,
        border: Border.all(color: AppColors.darkBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.amberWarm.withValues(alpha: 0.2),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏮', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amberWarm.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Golden Pathway',
                style: TextStyle(color: AppColors.amberWarm, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusGrowIllustration() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.darkSurface,
        border: Border.all(color: AppColors.darkBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.sageGreen.withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 68)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.safeGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Living Grove',
                style: TextStyle(color: AppColors.safeGreen, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanAchieveIllustration() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.darkSurface,
        border: Border.all(color: AppColors.darkBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.skyBlue.withValues(alpha: 0.2),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.skyBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'CBSE Class 10 Roadmap',
                style: TextStyle(color: AppColors.skyBlue, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceForTwoIllustration() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.darkSurface,
        border: Border.all(color: AppColors.cherryPink.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.cherryPink.withValues(alpha: 0.25),
            blurRadius: 20,
          ),
        ],
      ),
      child: const Center(
        child: Text('🐱❤️🐱', style: TextStyle(fontSize: 40)),
      ),
    );
  }
}
