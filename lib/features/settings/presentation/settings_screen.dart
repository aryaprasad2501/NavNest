import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/apk_update_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/demo_mode_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../core/widgets/nest_ambient_background.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_button.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/widgets/nest_progress_bar.dart';
import '../../distraction_control/presentation/app_blocker_screen.dart';
import '../../navbloom/presentation/providers/forest_provider.dart';
import '../../syllabus/presentation/providers/syllabus_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApkUpdateService _updateService = ApkUpdateService();

  void _openAppBlocker() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AppBlockerScreen()),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthService>();
    final forest = context.read<ForestProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Connecting to Google Services...'),
          ],
        ),
        duration: Duration(milliseconds: 1500),
      ),
    );

    final success = await auth.signInWithGoogle();
    if (!mounted) return;

    if (success && auth.currentUser != null) {
      forest.updateUserProfile(auth.currentUser!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signed in as ${auth.currentUser!.displayName} (${auth.currentUser!.email}) ✓'),
          backgroundColor: AppColors.deepForest,
        ),
      );
    } else {
      _showGoogleAccountPickerSheet();
    }
  }

  void _showGoogleAccountPickerSheet() {
    final auth = context.read<AuthService>();
    final forest = context.read<ForestProvider>();
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        final cardBg = isDark ? AppColors.darkSurface : Colors.white;
        final textCol = isDark ? AppColors.darkTextPrimary : Colors.black87;
        final mutedCol = isDark ? AppColors.darkTextMuted : Colors.black54;

        if (auth.currentUser?.displayName.isNotEmpty == true) {
          nameController.text = auth.currentUser!.displayName;
        }

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const GoogleLogo(size: 26),
                  const SizedBox(width: 12),
                  Text(
                    'Connect Google Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Synchronize your 6 CBSE Class 10 subjects, study streak, and NavBloom sanctuary with Google Cloud.',
                style: TextStyle(fontSize: 13, color: mutedCol, height: 1.3),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: textCol),
                decoration: const InputDecoration(
                  labelText: 'Student Full Name',
                  hintText: 'e.g. Aryan Sharma',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textCol),
                decoration: const InputDecoration(
                  labelText: 'Google Email Address',
                  hintText: 'student@gmail.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepForest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Connect & Sync with Google'),
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final name = nameController.text.trim();
                    if (email.isNotEmpty && email.contains('@')) {
                      Navigator.pop(sheetCtx);
                      await auth.linkGoogleAccount(
                        displayName: name.isNotEmpty ? name : 'CBSE Student',
                        email: email,
                      );
                      if (auth.currentUser != null) {
                        forest.updateUserProfile(auth.currentUser!);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Linked Google account: $email ✓'),
                            backgroundColor: AppColors.deepForest,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }


  void _showSignOutDialog() {
    final auth = context.read<AuthService>();
    final forest = context.read<ForestProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out of Google?'),
        content: const Text(
          'Your local study records, planner, and NavBloom forest will remain safe on this phone. Automatic cloud synchronization will be paused until you sign in again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (auth.currentUser != null) {
                forest.updateUserProfile(auth.currentUser!);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out of Google account.')),
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final forest = context.read<ForestProvider>();
    final auth = context.read<AuthService>();
    final nameController = TextEditingController(
      text: auth.currentUser?.displayName ?? forest.userProfile?.displayName ?? 'Student',
    );
    int targetMins = forest.userProfile?.dailyTargetMinutes ?? 120;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Study Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: AppRadius.roundedM),
                    hintText: 'Your Name',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Daily Focus Target: ${targetMins ~/ 60}h ${targetMins % 60 > 0 ? "${targetMins % 60}m" : ""} ($targetMins mins)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: targetMins.clamp(15, 960).toDouble(),
                  min: 15,
                  max: 960,
                  divisions: 63,
                  label: '${targetMins ~/ 60}h ${targetMins % 60}m',
                  activeColor: AppColors.deepForest,
                  onChanged: (v) => setDialogState(() => targetMins = (v / 15).round() * 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Preparing for CBSE Class 10 Board Exams 2027',
                  style: TextStyle(fontSize: 11, color: AppColors.sageGreen, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.deepForest),
                onPressed: () async {
                  final newName = nameController.text.trim();
                  final localStorage = context.read<LocalStorageService>();
                  final messenger = ScaffoldMessenger.of(context);
                  if (newName.isNotEmpty && forest.userProfile != null) {
                    final updated = forest.userProfile!.copyWith(
                      displayName: newName,
                      dailyTargetMinutes: targetMins,
                      updatedAt: DateTime.now(),
                    );
                    await forest.updateUserProfile(updated);
                    await localStorage.setDailyTargetMinutes(targetMins);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Profile preferences saved!')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showVivoGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.phone_android_rounded, color: AppColors.deepForest),
            SizedBox(width: 8),
            Text('Vivo Y28 Guide'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Optimizing NavNest for FuntouchOS 14:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 10),
            Text('1. Go to Settings → Battery → Background power consumption management.'),
            SizedBox(height: 4),
            Text('2. Select NavNest → Allow high background power usage.'),
            SizedBox(height: 4),
            Text('3. Enable Autostart in iManager / Settings → Apps.'),
            SizedBox(height: 10),
            Text(
              'This ensures your focus timer alarms and break chimes are never silenced.',
              style: TextStyle(fontSize: 12, color: AppColors.sageGreen),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _confirmEnterDemoMode() {
    final demoService = Provider.of<DemoModeService>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.science_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Explore Demo Mode?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'This will load a complete, pre-populated demonstration state across NavNest:\n\n'
              '• 30 NavBloom trees across all 5 growth stages\n'
              '• Realistic CBSE Class 10 Board 2027 progress\n'
              '• Study sessions, stats, streaks & planner tasks\n'
              '• Sample partner in Shared Space ("Rohan ⚡")\n'
              '• App Blocker demonstration\n\n'
              'Your genuine data is 100% isolated and safe in your private database. You can return to your real records anytime.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            onPressed: () async {
              Navigator.pop(ctx);
              await demoService.enterDemoMode(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo mode activated: Exploring sample grove & records.'),
                    backgroundColor: Color(0xFFD97706),
                  ),
                );
              }
            },
            child: const Text('Explore Demo Data'),
          ),
        ],
      ),
    );
  }

  void _confirmExitDemoMode() {
    final demoService = Provider.of<DemoModeService>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.assignment_return_rounded, color: AppColors.safeGreen),
            SizedBox(width: 8),
            Text('Exit Demo Mode?'),
          ],
        ),
        content: const Text(
          'This will return you to your genuine personal study records, trees, and progress.\n\nAll demo records will be unloaded immediately.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay in Demo'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.safeGreen),
            onPressed: () async {
              Navigator.pop(ctx);
              await demoService.exitDemoMode(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restored to your genuine personal data.'),
                    backgroundColor: AppColors.safeGreen,
                  ),
                );
              }
            },
            child: const Text('Exit Demo & Return to My Data'),
          ),
        ],
      ),
    );
  }

  void _confirmResetMyData() {
    final demoService = Provider.of<DemoModeService>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.urgentRed),
            SizedBox(width: 8),
            Text('Reset My Data?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '⚠️ WARNING: Permanent Destructive Action\n\n'
              'This will completely reset all your personal records:\n'
              '• Deletes all your planted trees\n'
              '• Clears completed study sessions & history\n'
              '• Resets syllabus progress to NOT STARTED\n'
              '• Clears planner tasks\n'
              '• Resets streak, XP and coins to 0\n\n'
              'This action CANNOT be undone.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await demoService.resetProductionData(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your account and forest have been reset to a clean slate.'),
                    backgroundColor: AppColors.urgentRed,
                  ),
                );
              }
            },
            child: const Text('Reset All My Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCheckForUpdatesFlow() async {
    // 1. Show checking indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(color: AppColors.deepForest),
            SizedBox(width: 20),
            Text('Checking for updates...'),
          ],
        ),
      ),
    );

    final status = await _updateService.checkForUpdates(forceHasUpdate: false);
    if (!mounted) return;
    Navigator.pop(context); // Dismiss checking indicator

    if (status == UpdateStatus.updateAvailable && _updateService.latestRelease != null) {
      final release = _updateService.latestRelease!;

      // Step 4: Show Update Available Modal (Requirements Section 3)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXL),
          title: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.sageTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_rounded, color: AppColors.deepForest, size: 36),
                ),
                const SizedBox(height: 12),
                Text('Update Available!', style: AppTypography.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'NavNest v${release.version} (${release.sizeFormatted})',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.sageGreen),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Release Notes:',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...release.releaseNotes.split('\n').map((line) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(line, style: AppTypography.bodySmall),
                  )),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Later'),
                  ),
                ),
                Expanded(
                  child: NestButton(
                    label: 'Update Now',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showDownloadingModal();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Up to Date'),
          content: const Text("You're using the latest version of NavNest (v1.0.0)."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  void _showDownloadingModal() {
    bool hasHandedOff = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: _updateService,
          builder: (dialogCtx, _) {
            final progress = _updateService.downloadProgress;
            final isVerifying = _updateService.status == UpdateStatus.verifyingChecksum;
            final isReady = _updateService.status == UpdateStatus.readyToInstall;
            final hasError = _updateService.status == UpdateStatus.error;

            if (isReady && !hasHandedOff) {
              hasHandedOff = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(ctx)) {
                  Navigator.pop(ctx);
                }
                _showOfficialAndroidInstallerPrompt();
              });
            }

            if (hasError) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXL),
                title: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.urgentRed.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.error_outline_rounded, color: AppColors.urgentRed, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text('Update Check Failed', style: AppTypography.titleMedium),
                    ],
                  ),
                ),
                content: Text(
                  _updateService.errorMessage ?? 'An error occurred during update verification.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                actions: [
                  Center(
                    child: TextButton(
                      onPressed: () {
                        _updateService.reset();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }

            final totalSize = _updateService.latestRelease?.sizeBytes ?? 63160503;
            final totalMb = (totalSize / (1024 * 1024)).toStringAsFixed(1);
            final downloadedMb = (progress * (totalSize / (1024 * 1024))).toStringAsFixed(1);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXL),
              title: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: AppColors.sageTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isVerifying ? Icons.verified_user_rounded : Icons.cloud_download_rounded,
                        color: AppColors.deepForest,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isVerifying ? 'Verifying Integrity' : 'Downloading Update',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVerifying
                          ? 'Checking SHA-256 Checksum...'
                          : '$downloadedMb MB of $totalMb MB',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    isVerifying ? 'Verifying' : '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.deepForest),
                  ),
                  const SizedBox(height: 8),
                  NestProgressBar(progress: isVerifying ? 1.0 : progress, height: 8),
                  const SizedBox(height: 12),
                  Text(
                    isVerifying
                        ? 'Cryptographic checksum verified ✓'
                        : 'Please keep NavNest open while downloading.',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () {
                      _updateService.cancelDownload();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Cancel Download', style: TextStyle(color: AppColors.urgentRed)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    _updateService.startDownload();
  }

  void _showOfficialAndroidInstallerPrompt() {
    // Step 8 & 9: Official Android System Package Installer Prompt
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.sageTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.park_rounded, color: AppColors.deepForest, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Package Installer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Do you want to install an update to NavNest?\n\nYour existing syllabus progress, planner tasks, study history, and forest progress will remain intact.',
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Android Package Manager: REQUEST_INSTALL_PACKAGES granted ✓',
              style: TextStyle(fontSize: 11, color: AppColors.safeGreen, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
            onPressed: () async {
              Navigator.pop(ctx);
              final launched = await _updateService.installDownloadedApk();
              _updateService.reset();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(launched
                        ? 'Launching Android Package Installer...'
                        : 'Update package verified. Android Package Installer requested.'),
                    backgroundColor: AppColors.deepForest,
                  ),
                );
              }
            },
            child: const Text('INSTALL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: true);
    final forest = context.watch<ForestProvider>();
    final demoService = context.watch<DemoModeService>();
    AuthService? authService;
    try {
      authService = context.watch<AuthService>();
    } catch (_) {}
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final studentName = authService?.currentUser?.displayName ??
        forest.userProfile?.displayName ??
        'Student';
    final photoUrl = authService?.currentUser?.photoUrl ?? forest.userProfile?.photoUrl;
    final email = authService?.currentUser?.email ?? forest.userProfile?.email;
    final targetMins = forest.userProfile?.dailyTargetMinutes ?? 120;

    final colors = NavThemeColors.of(context);

    return NestAmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: colors.primary),
          title: Text('Settings', style: AppTypography.titleLarge.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        children: [
          // User Profile Card
          _buildProfileTile(studentName, targetMins, isDark, photoUrl, email),

          const SizedBox(height: AppSpacing.m),

          // Google Account & Cloud Sync Card
          if (authService != null) ...[
            _buildGoogleAccountCard(authService, forest, isDark),
            const SizedBox(height: AppSpacing.l),
          ],

          // Settings Section: General & Features
          _buildSectionHeader('Preferences & Tools', isDark),
          _buildSettingsTile(
            icon: Icons.shield_outlined,
            title: 'Distraction Control & App Blocker',
            subtitle: 'Manage blocked apps, strict mode & limits',
            onTap: _openAppBlocker,
            isDark: isDark,
          ),
          _buildSettingsTile(
            icon: Icons.timer_outlined,
            title: 'Study Target & Profile',
            subtitle: 'Target: $targetMins mins/day • CBSE 10th 2027',
            onTap: _showEditProfileDialog,
            isDark: isDark,
          ),
          _buildThemeSelectorCard(themeService, isDark),

          const SizedBox(height: AppSpacing.l),

          // Settings Section: Curriculum & Database
          _buildSectionHeader('Curriculum & Database', isDark),
          _buildSettingsTile(
            icon: Icons.menu_book_rounded,
            title: 'CBSE Class 10 Syllabus (2027)',
            subtitle: 'Reload or reset all 6 official subjects',
            badge: 'Official',
            onTap: () {
              final provider = Provider.of<SyllabusProvider>(context, listen: false);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reload CBSE Class 10 Syllabus?'),
                  content: const Text(
                    'This will reload the official CBSE Class 10 Board Exam 2027 curriculum across all 6 subjects (Maths, Science, SST, English, Hindi, and IT 402). Continue?',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    NestButton(
                      label: 'Reload (2027)',
                      onPressed: () async {
                        Navigator.pop(context);
                        await provider.reloadOfficialClass10Syllabus();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('CBSE Class 10 (2027) Syllabus reloaded!')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.l),

          // Settings & Diagnostics (Requirements Part B & C)
          _buildSectionHeader('Settings & Diagnostics', isDark),
          if (!demoService.isDemoMode) ...[
            _buildSettingsTile(
              icon: Icons.science_outlined,
              title: 'Explore Demo Data',
              subtitle: 'Load sample grove, 30+ trees, syllabus progress & stats',
              badge: 'Opt-in Demo',
              iconColor: const Color(0xFFD97706),
              titleColor: const Color(0xFFD97706),
              onTap: _confirmEnterDemoMode,
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.delete_forever_rounded,
              title: 'Reset My Data',
              subtitle: 'Wipe personal study records to return to empty clean slate',
              iconColor: AppColors.urgentRed,
              titleColor: AppColors.urgentRed,
              onTap: _confirmResetMyData,
              isDark: isDark,
            ),
          ] else ...[
            _buildSettingsTile(
              icon: Icons.assignment_return_rounded,
              title: 'Exit Demo & Return to My Data',
              subtitle: 'Restores your genuine personal records. Demo data is discarded',
              badge: 'Active Demo',
              iconColor: AppColors.safeGreen,
              titleColor: AppColors.safeGreen,
              onTap: _confirmExitDemoMode,
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.restart_alt_rounded,
              title: 'Reset Demo Data',
              subtitle: 'Reset sample grove back to default demonstration state',
              onTap: () async {
                await demoService.enterDemoMode(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo sample grove reset.')),
                  );
                }
              },
              isDark: isDark,
            ),
          ],
          _buildSettingsTile(
            icon: Icons.system_update_rounded,
            title: 'Check for Updates',
            subtitle: 'NavNest v1.0.0 (Release APK)',
            badge: 'In-App Update',
            onTap: _showCheckForUpdatesFlow,
            isDark: isDark,
          ),
          _buildSettingsTile(
            icon: Icons.phone_android_rounded,
            title: 'Vivo Y28 Optimization Guide',
            subtitle: 'FuntouchOS battery whitelist instructions',
            onTap: _showVivoGuide,
            isDark: isDark,
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    ),
  );
  }

  Widget _buildProfileTile(String name, int targetMins, bool isDark, String? photoUrl, String? email) {
    final colors = NavThemeColors(isDark: isDark);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.roundedXL,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderSubtle, width: 2),
              image: photoUrl != null
                  ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: photoUrl == null
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.primary),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTypography.titleMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('🌸'),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email?.isNotEmpty == true
                      ? '$email • CBSE 2027'
                      : 'CBSE Class 10th Board 2027 • $targetMins m target',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: colors.primary),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleAccountCard(AuthService authService, ForestProvider forest, bool isDark) {
    final colors = NavThemeColors(isDark: isDark);
    final isLinked = authService.isGoogleLinked;
    final email = authService.currentUser?.email ?? '';
    final name = authService.currentUser?.displayName ?? forest.userProfile?.displayName ?? 'Student';
    final photoUrl = authService.currentUser?.photoUrl;
    final isSyncing = authService.isSyncing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.roundedXL,
        border: Border.all(
          color: isLinked
              ? colors.primary.withValues(alpha: 0.35)
              : colors.borderSubtle,
          width: isLinked ? 1.5 : 1,
        ),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GoogleLogo(size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Google Account & Cloud Backup',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (isLinked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: colors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Synced',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.success),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isLinked) ...[
            Text(
              'Link your Google account to automatically back up your CBSE 2027 syllabus progress, study sessions, and NavBloom sanctuary to Google Cloud.',
              style: AppTypography.bodySmall.copyWith(
                color: colors.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: colors.surfaceElevated,
                  side: BorderSide(color: colors.borderSubtle),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  shadowColor: Colors.black12,
                ),
                icon: const GoogleLogo(size: 20),
                label: Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                onPressed: _handleGoogleSignIn,
              ),
            ),
          ] else ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary.withValues(alpha: 0.15),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'G',
                          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_done_outlined, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authService.syncStatusMessage ?? 'All syllabus & forest progress backed up ✓',
                      style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NestButton(
                    label: isSyncing ? 'Syncing...' : 'Sync to Cloud Now',
                    icon: Icons.sync_rounded,
                    onPressed: isSyncing
                        ? null
                        : () async {
                            final success = await authService.syncDataWithCloud();
                            if (mounted && success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Synchronized with Google Cloud successfully! ✓'),
                                  backgroundColor: colors.primary,
                                ),
                              );
                            }
                          },
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _showSignOutDialog,
                  child: Text('Sign Out', style: TextStyle(color: colors.error, fontSize: 13)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Widget? trailing,
    required VoidCallback onTap,
    required bool isDark,
    Color? titleColor,
    Color? iconColor,
  }) {
    final colors = NavThemeColors(isDark: isDark);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.roundedL,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor != null
                ? iconColor.withValues(alpha: 0.12)
                : colors.canvas,
            borderRadius: AppRadius.roundedM,
          ),
          child: Icon(
            icon,
            color: iconColor ?? colors.primary,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: titleColor ?? colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge != null)
              NestBadge(label: badge, variant: NestBadgeVariant.forest, isDense: true),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: colors.textMuted,
          ),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: colors.textMuted),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeSelectorCard(ThemeService themeService, bool isDark) {
    final preference = themeService.preference;
    final colors = NavThemeColors(isDark: isDark);

    String statusText;
    switch (preference) {
      case NavThemePreference.solar:
        statusText = 'Follow the day (Auto Dawn ☀️ & Midnight 🌙 after evening)';
        break;
      case NavThemePreference.system:
        statusText = 'Follow Android system (Matches device ⚙️)';
        break;
      case NavThemePreference.dawn:
        statusText = 'Dawn (Morning Nature ☀️ forced)';
        break;
      case NavThemePreference.midnight:
        statusText = 'Midnight (Moonlit Nature 🌙 forced)';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.roundedL,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showThemeSettingsModal(context, themeService, colors),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.canvas,
                    borderRadius: AppRadius.roundedM,
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sanctuary Theme',
                            style: AppTypography.titleSmall.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.tune_rounded, size: 16, color: colors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Schedule',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                _buildThemeSegmentOption(
                  label: 'Auto Day',
                  icon: Icons.auto_awesome_rounded,
                  isSelected: preference == NavThemePreference.solar,
                  onTap: () => themeService.setPreference(NavThemePreference.solar),
                  colors: colors,
                ),
                _buildThemeSegmentOption(
                  label: 'Dawn',
                  icon: Icons.wb_sunny_rounded,
                  isSelected: preference == NavThemePreference.dawn,
                  onTap: () => themeService.setPreference(NavThemePreference.dawn),
                  colors: colors,
                ),
                _buildThemeSegmentOption(
                  label: 'Midnight',
                  icon: Icons.nightlight_round,
                  isSelected: preference == NavThemePreference.midnight,
                  onTap: () => themeService.setPreference(NavThemePreference.midnight),
                  colors: colors,
                ),
                _buildThemeSegmentOption(
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: preference == NavThemePreference.system,
                  onTap: () => themeService.setPreference(NavThemePreference.system),
                  colors: colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSettingsModal(BuildContext context, ThemeService themeService, NavThemeColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final preference = themeService.preference;
            final useCustom = themeService.useCustomSchedule;
            final dayHour = themeService.dayStartHour;
            final nightHour = themeService.nightStartHour;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Theme Settings',
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: colors.textMuted),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Option 1: Follow the day
                  _buildThemeOptionTile(
                    title: 'Follow the day',
                    subtitle: 'Automatically switch based on sunrise & sunset\n(Dawn in daytime, Midnight after 6:00 PM evening)',
                    icon: Icons.wb_twilight_rounded,
                    isSelected: preference == NavThemePreference.solar,
                    onTap: () async {
                      await themeService.setPreference(NavThemePreference.solar);
                      setModalState(() {});
                    },
                    colors: colors,
                  ),
                  const SizedBox(height: 10),

                  // Option 2: Follow Android system
                  _buildThemeOptionTile(
                    title: 'Follow Android system',
                    subtitle: "Use your phone's Light/Dark operating system setting",
                    icon: Icons.android_rounded,
                    isSelected: preference == NavThemePreference.system,
                    onTap: () async {
                      await themeService.setPreference(NavThemePreference.system);
                      setModalState(() {});
                    },
                    colors: colors,
                  ),
                  const SizedBox(height: 10),

                  // Option 3: Choose manually
                  _buildThemeOptionTile(
                    title: 'Choose manually',
                    subtitle: 'Stay fixed in Dawn (Morning) or Midnight (Moonlit)',
                    icon: Icons.touch_app_rounded,
                    isSelected: preference == NavThemePreference.dawn || preference == NavThemePreference.midnight,
                    onTap: () async {
                      await themeService.setPreference(themeService.isDarkMode ? NavThemePreference.midnight : NavThemePreference.dawn);
                      setModalState(() {});
                    },
                    colors: colors,
                  ),

                  if (preference == NavThemePreference.dawn || preference == NavThemePreference.midnight) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Dawn ☀️'),
                            selected: preference == NavThemePreference.dawn,
                            onSelected: (_) async {
                              await themeService.setPreference(NavThemePreference.dawn);
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Midnight 🌙'),
                            selected: preference == NavThemePreference.midnight,
                            onSelected: (_) async {
                              await themeService.setPreference(NavThemePreference.midnight);
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Custom Day/Night Schedule Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom day/night schedule',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Use custom start times instead of location defaults',
                              style: TextStyle(fontSize: 12, color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: useCustom,
                        activeTrackColor: colors.primary,
                        onChanged: (val) async {
                          await themeService.setSchedule(
                            useCustom: val,
                            dayHour: dayHour,
                            nightHour: nightHour,
                          );
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),

                  if (useCustom) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Day starts at', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                                    Text('${dayHour % 12 == 0 ? 12 : dayHour % 12}:00 ${dayHour >= 12 ? 'PM' : 'AM'}', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                  ],
                                ),
                                DropdownButton<int>(
                                  value: dayHour,
                                  underline: const SizedBox.shrink(),
                                  dropdownColor: colors.surfaceElevated,
                                  items: [5, 6, 7, 8].map((h) => DropdownMenuItem(value: h, child: Text('$h:00 AM'))).toList(),
                                  onChanged: (val) async {
                                    if (val != null) {
                                      await themeService.setSchedule(useCustom: true, dayHour: val, nightHour: nightHour);
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Night starts at', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                                    Text('${nightHour % 12 == 0 ? 12 : nightHour % 12}:00 ${nightHour >= 12 ? 'PM' : 'AM'}', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                  ],
                                ),
                                DropdownButton<int>(
                                  value: nightHour,
                                  underline: const SizedBox.shrink(),
                                  dropdownColor: colors.surfaceElevated,
                                  items: [17, 18, 19, 20, 21].map((h) => DropdownMenuItem(value: h, child: Text('${h - 12}:00 PM'))).toList(),
                                  onChanged: (val) async {
                                    if (val != null) {
                                      await themeService.setSchedule(useCustom: true, dayHour: dayHour, nightHour: val);
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required NavThemeColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryContainer.withValues(alpha: 0.3) : colors.canvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? colors.primary : colors.textMuted, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? colors.primary : colors.textMuted.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSegmentOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required NavThemeColors colors,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? (colors.isDark ? colors.canvas : Colors.white)
                    : colors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (colors.isDark ? colors.canvas : Colors.white)
                      : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
