import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_button.dart';
import '../../focus/presentation/providers/focus_session_provider.dart';
import '../models/installed_app_model.dart';
import 'providers/app_blocker_provider.dart';
import 'widgets/distraction_shield_dialog.dart';

class AppBlockerScreen extends StatefulWidget {
  const AppBlockerScreen({super.key});

  @override
  State<AppBlockerScreen> createState() => _AppBlockerScreenState();
}

class _AppBlockerScreenState extends State<AppBlockerScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blocker = Provider.of<AppBlockerProvider>(context, listen: false);
      blocker.refreshAccessibilityStatus();
      if (blocker.installedApps.isEmpty) {
        blocker.loadInstalledApps();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = NavThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blocker = context.watch<AppBlockerProvider>();
    final focus = context.watch<FocusSessionProvider>();

    final isFocusRunning = focus.isRunning;

    // Filter apps based on search and category
    final filteredApps = blocker.installedApps.where((app) {
      final matchesSearch = _searchQuery.isEmpty ||
          app.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Blocked') return app.isBlocked;
      return app.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        title: Text('App Blocker & Shield', style: AppTypography.titleLarge.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: colors.primary),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.primary),
            tooltip: 'Refresh Apps & Status',
            onPressed: () {
              blocker.refreshAccessibilityStatus();
              blocker.loadInstalledApps();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Accessibility Service Onboarding / Status Card
            _buildAccessibilityStatusCard(context, blocker, colors, isDark),

            const SizedBox(height: 20),

            // 2. Shield Stats & Focus Connection Banner
            _buildShieldStatsCard(blocker, isFocusRunning, colors, isDark),

            const SizedBox(height: 20),

            // 3. Blocker Control Switches (Protection Active & Strict Mode)
            _buildProtectionSwitchesCard(blocker, colors, isDark),

            const SizedBox(height: 24),

            // 4. App List Header & Quick Setup Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Restricted Applications', style: AppTypography.titleMedium.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${blocker.blockedPackages.length} apps currently restricted',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    blocker.blockPackages(AppBlockerProvider.defaultPopularDistractions);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Shielded top social & gaming distractions!'),
                        backgroundColor: AppColors.deepForest,
                      ),
                    );
                  },
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text('Block Top 6'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 5. Search Bar
            TextField(
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search installed apps...',
                hintStyle: TextStyle(color: colors.textMuted),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: colors.textMuted),
                filled: true,
                fillColor: colors.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.roundedL,
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.roundedL,
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.roundedL,
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),

            const SizedBox(height: 12),

            // 6. Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  'Blocked',
                  'Social & Chat',
                  'Media & Streaming',
                  'Gaming',
                  'Browsers',
                ].map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      selectedColor: colors.primary,
                      backgroundColor: colors.surfaceCard,
                      side: BorderSide(color: isSel ? colors.primary : colors.borderSubtle),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? Colors.white : colors.textPrimary,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 7. Installed App Items List
            if (blocker.isLoadingApps) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.deepForest),
                ),
              ),
            ] else if (filteredApps.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No apps found matching your query.',
                    style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredApps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final app = filteredApps[idx];
                  return _buildAppItemCard(app, blocker, colors, isDark);
                },
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilityStatusCard(BuildContext context, AppBlockerProvider blocker, NavThemeColors colors, bool isDark) {
    final isEnabled = blocker.isAccessibilityEnabled;

    if (isEnabled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.safeGreen.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: AppRadius.roundedL,
          border: Border.all(color: AppColors.safeGreen, width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.safeGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Study Shield Active 🛡️',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.safeGreen),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Accessibility service connected. Distracting apps will be blocked during focus.',
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () {
                DistractionShieldDialog.show(context, 'com.instagram.android');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.safeGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text('Test Shield', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      );
    }

    // Onboarding card when Accessibility is NOT yet enabled
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.amberHoney.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: AppRadius.roundedL,
        border: Border.all(color: AppColors.amberHoney, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.amberHoney,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accessibility Setup Required',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.amberHoney),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Android requires this to detect distracting apps during study.',
                      style: TextStyle(fontSize: 12, color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Privacy Assurance Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.canvas,
              borderRadius: AppRadius.roundedM,
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zero Data Collection: NavNest never reads passwords, personal messages, or screen text. Only window changes during study sessions are monitored.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Setup Instructions
          Text(
            'How to enable (3 easy steps):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          _buildSetupStep(colors, isDark, '1', 'Tap "Enable Study Shield" below — Settings will open'),
          const SizedBox(height: 4),
          _buildSetupStep(colors, isDark, '2', 'Find "NavNest Study Shield" and tap it'),
          const SizedBox(height: 4),
          _buildSetupStep(colors, isDark, '3', 'Toggle ON and tap "Allow" when Android asks'),

          const SizedBox(height: 10),

          // Android 13+ warning
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: AppRadius.roundedM,
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Android 13+ only: If the toggle is greyed out, go back → App Info for NavNest → tap ⋮ (3-dot menu) → "Allow restricted settings" → return here.',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: NestButton(
                  label: 'Enable Study Shield',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => blocker.openAccessibilitySettings(),
                  variant: NestButtonVariant.primary,
                  isFullWidth: true,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  blocker.refreshAccessibilityStatus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checking permission status…'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: Icon(Icons.refresh_rounded, size: 16, color: colors.primary),
                label: Text('Re-check', style: TextStyle(fontSize: 12, color: colors.textPrimary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.borderSubtle),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStep(NavThemeColors colors, bool isDark, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.amberHoney,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: colors.textMuted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShieldStatsCard(AppBlockerProvider blocker, bool isFocusRunning, NavThemeColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.roundedL,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            '${blocker.distractionsShieldedToday}',
            'Distractions Shielded',
            Icons.shield_outlined,
            AppColors.safeGreen,
            colors,
            isDark,
          ),
          Container(
            height: 36,
            width: 1,
            color: colors.borderSubtle,
          ),
          _buildStatColumn(
            isFocusRunning ? 'ACTIVE' : 'IDLE',
            'Focus Timer State',
            isFocusRunning ? Icons.timer_rounded : Icons.timer_outlined,
            isFocusRunning ? colors.primary : colors.textMuted,
            colors,
            isDark,
          ),
          Container(
            height: 36,
            width: 1,
            color: colors.borderSubtle,
          ),
          _buildStatColumn(
            blocker.isStrictMode ? 'STRICT' : 'STANDARD',
            'Enforcement',
            Icons.lock_outline_rounded,
            AppColors.amberHoney,
            colors,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, IconData icon, Color color, NavThemeColors colors, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildProtectionSwitchesCard(AppBlockerProvider blocker, NavThemeColors colors, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.roundedL,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: blocker.isProtectionActive,
            activeTrackColor: colors.primary,
            title: Text('Shield Distractions During Focus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
            subtitle: Text(
              'Enforces app blocking whenever a study timer is running.',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
            onChanged: (val) => blocker.toggleProtection(val),
          ),
          Divider(height: 1, color: colors.borderSubtle),
          SwitchListTile(
            value: blocker.isStrictMode,
            activeTrackColor: colors.primary,
            title: Text('Strict Focus Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
            subtitle: Text(
              'Prevents bypassing or snoozing shield until your study block completes.',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
            onChanged: (val) => blocker.toggleStrictMode(val),
          ),
        ],
      ),
    );
  }

  Widget _buildAppItemCard(InstalledAppModel app, AppBlockerProvider blocker, NavThemeColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.roundedM,
        border: Border.all(
          color: app.isBlocked
              ? colors.primary.withValues(alpha: 0.5)
              : colors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.canvas,
              shape: BoxShape.circle,
            ),
            child: Text(app.iconEmoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${app.category} • ${app.packageName}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: app.isBlocked,
            activeTrackColor: colors.primary,
            onChanged: (_) => blocker.toggleAppBlock(app.packageName),
          ),
        ],
      ),
    );
  }
}
