import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/google_logo.dart';
import '../../navbloom/presentation/providers/forest_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedTargetMinutes = 120; // Default: 2 Hours
  bool _isConnectingGoogle = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthService>();
    setState(() => _isConnectingGoogle = true);

    try {
      final success = await auth.signInWithGoogle();
      if (!mounted) return;

      if (success && auth.currentUser != null) {
        if (_nameController.text.trim().isEmpty && auth.currentUser!.displayName.isNotEmpty) {
          setState(() {
            _nameController.text = auth.currentUser!.displayName;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected with ${auth.currentUser!.email} ✓'),
            backgroundColor: AppColors.safeGreen,
          ),
        );
      } else {
        // Fallback manual entry prompt if native sign-in is cancelled or requires web auth
        _showManualGoogleLinkDialog();
      }
    } finally {
      if (mounted) setState(() => _isConnectingGoogle = false);
    }
  }

  void _showManualGoogleLinkDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            GoogleLogo(size: 22),
            SizedBox(width: 10),
            Text('Link Google Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google email to sync your CBSE Class 10 study progress:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Google Email Address',
                hintText: 'student@gmail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip for now'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepForest),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                Navigator.pop(ctx);
                final auth = context.read<AuthService>();
                final name = _nameController.text.trim().isNotEmpty
                    ? _nameController.text.trim()
                    : 'Class 10 Scholar';
                await auth.linkGoogleAccount(displayName: name, email: email);
                if (mounted) setState(() {});
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final enteredName = _nameController.text.trim();
    final studentName = enteredName.isNotEmpty ? enteredName : 'Student 🌿';

    final auth = context.read<AuthService>();
    final forest = context.read<ForestProvider>();
    final localStorage = context.read<LocalStorageService>();

    // 1. Purge all dummy data to guarantee clean slate
    await DatabaseHelper.instance.purgeDummyDataAndStartFresh();
    await localStorage.clearSharedSpaceData();
    await localStorage.setCleanSlatePurged();

    // 2. Save fresh student profile
    final baseProfile = auth.currentUser ?? UserProfile.defaultProfile();
    final updatedProfile = baseProfile.copyWith(
      displayName: studentName,
      streakDays: 0,
      bestStreak: 0,
      totalXp: 0,
      coins: 0,
      dailyTargetMinutes: _selectedTargetMinutes,
      updatedAt: DateTime.now(),
    );

    await auth.updateProfile(updatedProfile);
    forest.updateUserProfile(updatedProfile);

    // 3. Save target minutes and mark first launch complete
    await localStorage.setDailyTargetMinutes(_selectedTargetMinutes);
    await localStorage.setFirstLaunchComplete();

    // 4. Reload clean forest & planner state
    await forest.loadForestData();

    if (!mounted) return;

    // 5. Navigate directly to sanctuary
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthService>();
    final isGoogleLinked = auth.isGoogleLinked;

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.cardSurface;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.borderSubtle;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Sanctuary Emblem
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.sageTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.sageLight, width: 2),
                  boxShadow: AppShadows.softCard,
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 44)),
                ),
              ),

              const SizedBox(height: 20),

              // Welcome Title
              Text(
                'Welcome to NavNest',
                style: AppTypography.displayMedium.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              Text(
                'Your personal CBSE Class 10 study sanctuary & focus companion.',
                style: AppTypography.bodyMedium.copyWith(
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // 1. Name Input Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.roundedXL,
                  border: Border.all(color: borderCol),
                  boxShadow: AppShadows.softCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, color: AppColors.sageGreen, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'What is your name?',
                          style: AppTypography.titleMedium.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'e.g. Aryan, Ananya',
                        hintStyle: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface : AppColors.warmCream.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.roundedM,
                          borderSide: BorderSide(color: borderCol),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.roundedM,
                          borderSide: BorderSide(color: borderCol),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.roundedM,
                          borderSide: const BorderSide(color: AppColors.sageGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Google Connect Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.roundedXL,
                  border: Border.all(color: borderCol),
                  boxShadow: AppShadows.softCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const GoogleLogo(size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Google Account Sync',
                          style: AppTypography.titleMedium.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isGoogleLinked
                                ? AppColors.safeGreen.withValues(alpha: 0.15)
                                : AppColors.warmCream,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isGoogleLinked ? 'Connected' : 'Optional',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isGoogleLinked ? AppColors.safeGreen : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Back up your 6 CBSE Class 10 subjects, study streak & NavBloom trees securely to Google Cloud.',
                      style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
                    ),
                    const SizedBox(height: 14),
                    if (isGoogleLinked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.safeGreen.withValues(alpha: 0.1),
                          borderRadius: AppRadius.roundedM,
                          border: Border.all(color: AppColors.safeGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.safeGreen, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${auth.currentUser?.email}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.safeGreen,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isConnectingGoogle ? null : _handleGoogleSignIn,
                          icon: _isConnectingGoogle
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const GoogleLogo(size: 18),
                          label: Text(
                            _isConnectingGoogle ? 'Connecting...' : 'Connect with Google',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderCol),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedM),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. Daily Focus Target Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.roundedXL,
                  border: Border.all(color: borderCol),
                  boxShadow: AppShadows.softCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.amberHoney, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Study Target',
                          style: AppTypography.titleMedium.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How much focused time do you want to achieve each day?',
                      style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTargetChip(60, '1 Hour', isDark),
                        _buildTargetChip(120, '2 Hours ⭐', isDark),
                        _buildTargetChip(180, '3 Hours', isDark),
                        _buildTargetChip(240, '4 Hours', isDark),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 4. Primary Enter Sanctuary Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _completeOnboarding,
                  icon: const Icon(Icons.spa_rounded),
                  label: const Text(
                    'Enter Sanctuary 🌿',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.deepForest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedL),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Official CBSE Class 10th Syllabus 2026-2027 Included',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetChip(int minutes, String label, bool isDark) {
    final isSelected = _selectedTargetMinutes == minutes;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.sageGreen,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedTargetMinutes = minutes);
      },
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedS),
    );
  }
}
