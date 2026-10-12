import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_button.dart';

class BlockedAppItem {
  final String id;
  final String name;
  final String packageName;
  final IconData icon;
  final Color iconColor;
  bool isBlocked;
  int dailyUsageMinutes;

  BlockedAppItem({
    required this.id,
    required this.name,
    required this.packageName,
    required this.icon,
    required this.iconColor,
    required this.isBlocked,
    this.dailyUsageMinutes = 0,
  });
}

class FocusScheduleItem {
  final String id;
  final String title;
  final String timeRange;
  final String days;
  bool isActive;

  FocusScheduleItem({
    required this.id,
    required this.title,
    required this.timeRange,
    required this.days,
    required this.isActive,
  });
}

class AppBlockerScreen extends StatefulWidget {
  const AppBlockerScreen({super.key});

  @override
  State<AppBlockerScreen> createState() => _AppBlockerScreenState();
}

class _AppBlockerScreenState extends State<AppBlockerScreen> {
  int _selectedTabIndex = 0; // 0: Focus Mode, 1: Schedule
  bool _isProtectionActive = true;
  bool _isStrictMode = true;
  int _distractionsShieldedToday = 7;

  final List<BlockedAppItem> _apps = [
    BlockedAppItem(
      id: 'app_insta',
      name: 'Instagram',
      packageName: 'com.instagram.android',
      icon: Icons.camera_alt_rounded,
      iconColor: const Color(0xFFE1306C),
      isBlocked: true,
      dailyUsageMinutes: 38,
    ),
    BlockedAppItem(
      id: 'app_yt',
      name: 'YouTube',
      packageName: 'com.google.android.youtube',
      icon: Icons.smart_display_rounded,
      iconColor: const Color(0xFFFF0000),
      isBlocked: true,
      dailyUsageMinutes: 45,
    ),
    BlockedAppItem(
      id: 'app_snap',
      name: 'Snapchat',
      packageName: 'com.snapchat.android',
      icon: Icons.face_retouching_natural_rounded,
      iconColor: const Color(0xFFFFB300),
      isBlocked: true,
      dailyUsageMinutes: 15,
    ),
    BlockedAppItem(
      id: 'app_games',
      name: 'BGMI / Gaming Apps',
      packageName: 'com.pubg.imobile',
      icon: Icons.sports_esports_rounded,
      iconColor: const Color(0xFF673AB7),
      isBlocked: true,
      dailyUsageMinutes: 20,
    ),
    BlockedAppItem(
      id: 'app_whatsapp',
      name: 'WhatsApp',
      packageName: 'com.whatsapp',
      icon: Icons.chat_rounded,
      iconColor: const Color(0xFF25D366),
      isBlocked: false,
      dailyUsageMinutes: 24,
    ),
    BlockedAppItem(
      id: 'app_chrome',
      name: 'Chrome Browser',
      packageName: 'com.android.chrome',
      icon: Icons.public_rounded,
      iconColor: const Color(0xFF4285F4),
      isBlocked: false,
      dailyUsageMinutes: 18,
    ),
  ];

  final List<FocusScheduleItem> _schedules = [
    FocusScheduleItem(
      id: 'sch_evening',
      title: 'CBSE 10th Evening Study Block',
      timeRange: '05:00 PM – 08:30 PM',
      days: 'Mon, Tue, Wed, Thu, Fri',
      isActive: true,
    ),
    FocusScheduleItem(
      id: 'sch_morning',
      title: 'Morning Science & Math Formulas',
      timeRange: '06:00 AM – 07:30 AM',
      days: 'Everyday',
      isActive: true,
    ),
    FocusScheduleItem(
      id: 'sch_weekend',
      title: 'Sunday Mock Test & Revision',
      timeRange: '10:00 AM – 01:00 PM',
      days: 'Sunday',
      isActive: false,
    ),
  ];

  void _showAddAppsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final extraApps = [
          BlockedAppItem(
            id: 'app_discord',
            name: 'Discord',
            packageName: 'com.discord',
            icon: Icons.headset_mic_rounded,
            iconColor: const Color(0xFF5865F2),
            isBlocked: false,
          ),
          BlockedAppItem(
            id: 'app_reddit',
            name: 'Reddit',
            packageName: 'com.reddit.frontpage',
            icon: Icons.bubble_chart_rounded,
            iconColor: const Color(0xFFFF4500),
            isBlocked: false,
          ),
          BlockedAppItem(
            id: 'app_netflix',
            name: 'Netflix',
            packageName: 'com.netflix.mediaclient',
            icon: Icons.movie_rounded,
            iconColor: const Color(0xFFE50914),
            isBlocked: false,
          ),
          BlockedAppItem(
            id: 'app_telegram',
            name: 'Telegram',
            packageName: 'org.telegram.messenger',
            icon: Icons.send_rounded,
            iconColor: const Color(0xFF0088CC),
            isBlocked: false,
          ),
        ];

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  Text('Add Apps to Blocklist', style: AppTypography.titleLarge),
                  const SizedBox(height: 4),
                  Text('Select apps to shield during focus sessions', style: AppTypography.bodySmall),
                  const SizedBox(height: 16),
                  ...extraApps.map((a) {
                    return CheckboxListTile(
                      value: a.isBlocked,
                      title: Text(a.name, style: AppTypography.labelLarge),
                      secondary: Icon(a.icon, color: a.iconColor),
                      onChanged: (val) {
                        setModalState(() => a.isBlocked = val ?? false);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  NestButton(
                    label: 'Add Selected Apps',
                    onPressed: () {
                      setState(() {
                        for (final a in extraApps) {
                          if (a.isBlocked && !_apps.any((x) => x.id == a.id)) {
                            _apps.add(a);
                          }
                        }
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Blocklist updated successfully!')),
                      );
                    },
                    isFullWidth: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTestBlockingShield() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.deepForestDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sageGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded, color: AppColors.sageGreen, size: 48),
            ),
            const SizedBox(height: 18),
            const Text(
              'Distraction Shield Active',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Instagram is paused right now.\nYou scheduled this time to prepare for CBSE Class 10 Board Exams.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Take a deep breath and return to study ✨',
                style: TextStyle(fontSize: 12, color: AppColors.amberWarm, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.safeGreen),
                onPressed: () {
                  setState(() => _distractionsShieldedToday++);
                  Navigator.pop(ctx);
                },
                child: const Text('Back to NavNest Focus'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDiagnostics() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.perm_device_information_rounded, color: AppColors.deepForest),
            SizedBox(width: 8),
            Text('Android & Vivo Setup'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Device: Vivo Y28 (Android 14 / FuntouchOS 14)',
                style: AppTypography.titleSmall.copyWith(color: AppColors.deepForest),
              ),
              const SizedBox(height: 12),
              _buildPermRow(
                '1. Usage Access Permission',
                'Granted ✓',
                'Allows NavNest to detect when a distracting app enters foreground.',
                true,
              ),
              const Divider(height: 16),
              _buildPermRow(
                '2. Display Over Other Apps',
                'Granted ✓',
                'Allows NavNest to show the mindful blocking shield when restricted apps are opened.',
                true,
              ),
              const Divider(height: 16),
              _buildPermRow(
                '3. FuntouchOS Autostart',
                'Action Required',
                'Vivo aggressively kills background processes. Go to Settings → Apps → Autostart → Enable NavNest.',
                false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening device permission settings...')),
              );
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermRow(String title, String status, String desc, bool isOk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: AppTypography.labelLarge)),
            NestBadge(
              label: status,
              variant: isOk ? NestBadgeVariant.safeGreen : NestBadgeVariant.amber,
              isDense: true,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(desc, style: AppTypography.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Text('App Blocker & Distraction Control', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Permission Diagnostics',
            onPressed: _showPermissionDiagnostics,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Segmented Tabs: [Focus Mode] [Schedule]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.warmCream,
                borderRadius: AppRadius.roundedFull,
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  _buildTab('Focus Mode', 0, isDark),
                  _buildTab('Schedules & Limits', 1, isDark),
                ],
              ),
            ),
          ),

          Expanded(
            child: _selectedTabIndex == 0
                ? _buildFocusModeTab(isDark)
                : _buildScheduleTab(isDark),
          ),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Test Shield'),
                    onPressed: _showTestBlockingShield,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedL),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: NestButton(
                    label: '+ Add Apps',
                    icon: Icons.add_rounded,
                    onPressed: _showAddAppsModal,
                    variant: NestButtonVariant.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeTab(bool isDark) {
    final blockedCount = _apps.where((a) => a.isBlocked).length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        // Protection Status Card
        _buildProtectionStatusCard(isDark),

        const SizedBox(height: AppSpacing.m),

        // Strict Mode Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.cardSurface,
            borderRadius: AppRadius.roundedL,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.amberSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_rounded, color: AppColors.amberHoney, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Strict Mode Active', style: AppTypography.titleSmall),
                    Text(
                      'Blocks uninstallation and exiting during live focus sessions.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isStrictMode,
                activeThumbColor: AppColors.deepForest,
                activeTrackColor: AppColors.sageTint,
                onChanged: (val) => setState(() => _isStrictMode = val),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.l),

        // Blocked Apps Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Blocked Apps ($blockedCount)', style: AppTypography.titleMedium),
            Text('Interceptions: $_distractionsShieldedToday', style: AppTypography.labelMedium.copyWith(color: AppColors.safeGreen)),
          ],
        ),
        const SizedBox(height: AppSpacing.m),

        // App Rows with Switches
        ..._apps.map((app) => _buildAppRow(app, isDark)),
      ],
    );
  }

  Widget _buildScheduleTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.cardSurface,
            borderRadius: AppRadius.roundedXL,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Daily App Limit', style: AppTypography.titleSmall),
                  const NestBadge(label: '45m / Day', variant: NestBadgeVariant.amber, isDense: true),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Overall daily recreation limit for all non-study apps combined.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.l),

        Text('Scheduled Focus Restrictions', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.m),

        ..._schedules.map((sch) => _buildScheduleRow(sch, isDark)),
      ],
    );
  }

  Widget _buildScheduleRow(FocusScheduleItem sch, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        borderRadius: AppRadius.roundedL,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.sageTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_rounded, color: AppColors.deepForest, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sch.title, style: AppTypography.titleSmall),
                const SizedBox(height: 2),
                Text('${sch.timeRange} • ${sch.days}', style: AppTypography.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: sch.isActive,
            activeThumbColor: AppColors.deepForest,
            activeTrackColor: AppColors.sageTint,
            onChanged: (val) => setState(() => sch.isActive = val),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, bool isDark) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.deepForest : Colors.transparent,
            borderRadius: AppRadius.roundedFull,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtectionStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        borderRadius: AppRadius.roundedXL,
        border: Border.all(
          color: _isProtectionActive ? AppColors.safeGreen.withValues(alpha: 0.5) : AppColors.borderSubtle,
          width: 1.2,
        ),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.safeGreenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.safeGreen, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distraction protection is active', style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${_apps.where((a) => a.isBlocked).length} apps blocked. Interceptions shielded: $_distractionsShieldedToday',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isProtectionActive,
            activeThumbColor: AppColors.deepForest,
            activeTrackColor: AppColors.sageTint,
            onChanged: (val) => setState(() => _isProtectionActive = val),
          ),
        ],
      ),
    );
  }

  Widget _buildAppRow(BlockedAppItem app, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        borderRadius: AppRadius.roundedM,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: app.iconColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.roundedS,
            ),
            child: Icon(app.icon, color: app.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name, style: AppTypography.labelLarge),
                Text(
                  app.isBlocked ? 'Blocked during study' : 'Usage: ${app.dailyUsageMinutes}m today',
                  style: TextStyle(
                    fontSize: 11,
                    color: app.isBlocked ? AppColors.safeGreen : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: app.isBlocked,
            activeThumbColor: AppColors.deepForest,
            activeTrackColor: AppColors.sageTint,
            onChanged: (val) => setState(() => app.isBlocked = val),
          ),
        ],
      ),
    );
  }
}
