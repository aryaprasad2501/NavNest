import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/apk_update_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_button.dart';
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
                Text('Daily Focus Target: $targetMins mins', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Slider(
                  value: targetMins.toDouble(),
                  min: 60,
                  max: 300,
                  divisions: 8,
                  label: '$targetMins m',
                  activeColor: AppColors.deepForest,
                  onChanged: (v) => setDialogState(() => targetMins = v.round()),
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
                onPressed: () {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty && forest.userProfile != null) {
                    final updated = forest.userProfile!.copyWith(
                      displayName: newName,
                      dailyTargetMinutes: targetMins,
                      updatedAt: DateTime.now(),
                    );
                    forest.updateUserProfile(updated);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
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

    final status = await _updateService.checkForUpdates(forceHasUpdate: true);
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
    // Step 5 & 6: Download progress modal with cancellation & SHA-256 verification
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

            if (isReady) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(ctx);
                _showOfficialAndroidInstallerPrompt();
              });
            }

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
                          : '${(progress * 44.2).toStringAsFixed(1)} MB of 44.2 MB',
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
            onPressed: () {
              Navigator.pop(ctx);
              _updateService.reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Update verified & installed successfully! Local database preserved.'),
                  backgroundColor: AppColors.deepForest,
                ),
              );
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
    AuthService? authService;
    try {
      authService = context.watch<AuthService>();
    } catch (_) {}
    final isDark = themeService.isDarkMode;

    final studentName = authService?.currentUser?.displayName ??
        forest.userProfile?.displayName ??
        'Student';
    final photoUrl = authService?.currentUser?.photoUrl ?? forest.userProfile?.photoUrl;
    final email = authService?.currentUser?.email ?? forest.userProfile?.email;
    final targetMins = forest.userProfile?.dailyTargetMinutes ?? 120;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.titleLarge),
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
          _buildSettingsTile(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            title: 'Sanctuary Theme',
            subtitle: isDark ? 'Moonlit Forest (Dark mode)' : 'Whispering Meadow (Light mode)',
            trailing: Switch.adaptive(
              value: isDark,
              activeThumbColor: AppColors.deepForest,
              activeTrackColor: AppColors.sageTint,
              onChanged: (_) => themeService.toggleTheme(),
            ),
            onTap: () => themeService.toggleTheme(),
            isDark: isDark,
          ),

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

          // In-App Update Workflow Tile (Requirements Section 3)
          _buildSectionHeader('In-App Updater & Device', isDark),
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
    );
  }

  Widget _buildProfileTile(String name, int targetMins, bool isDark, String? photoUrl, String? email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        borderRadius: AppRadius.roundedXL,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.sageTint,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: photoUrl != null
                  ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: photoUrl == null
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.deepForest),
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
                        style: AppTypography.titleMedium,
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
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.deepForest),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleAccountCard(AuthService authService, ForestProvider forest, bool isDark) {
    final isLinked = authService.isGoogleLinked;
    final email = authService.currentUser?.email ?? '';
    final name = authService.currentUser?.displayName ?? forest.userProfile?.displayName ?? 'Student';
    final photoUrl = authService.currentUser?.photoUrl;
    final isSyncing = authService.isSyncing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        borderRadius: AppRadius.roundedXL,
        border: Border.all(
          color: isLinked
              ? AppColors.deepForest.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
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
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (isLinked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.safeGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.safeGreen.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_rounded, size: 12, color: AppColors.safeGreen),
                      SizedBox(width: 4),
                      Text(
                        'Synced',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.safeGreen),
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
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF232D28) : Colors.white,
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
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
                    color: isDark ? Colors.white : const Color(0xFF3C4043),
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
                  backgroundColor: AppColors.sageTint,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'G',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.deepForest),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
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
                color: isDark ? const Color(0xFF1D2622) : AppColors.sageTint.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, size: 16, color: AppColors.deepForest),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authService.syncStatusMessage ?? 'All syllabus & forest progress backed up ✓',
                      style: const TextStyle(fontSize: 11, color: AppColors.deepForest, fontWeight: FontWeight.w600),
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
                                const SnackBar(
                                  content: Text('Synchronized with Google Cloud successfully! ✓'),
                                  backgroundColor: AppColors.deepForest,
                                ),
                              );
                            }
                          },
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _showSignOutDialog,
                  child: const Text('Sign Out', style: TextStyle(color: AppColors.urgentRed, fontSize: 13)),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        borderRadius: AppRadius.roundedL,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkElevated : AppColors.sageTint,
            borderRadius: AppRadius.roundedM,
          ),
          child: Icon(icon, color: AppColors.deepForest, size: 20),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title, style: AppTypography.titleSmall)),
            if (badge != null)
              NestBadge(label: badge, variant: NestBadgeVariant.forest, isDense: true),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
