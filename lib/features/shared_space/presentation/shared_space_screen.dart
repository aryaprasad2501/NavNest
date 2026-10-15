import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_button.dart';
import '../../../core/widgets/nest_card.dart';
import '../../navbloom/presentation/providers/forest_provider.dart';
import 'providers/shared_space_provider.dart';

class SharedSpaceScreen extends StatefulWidget {
  const SharedSpaceScreen({super.key});

  @override
  State<SharedSpaceScreen> createState() => _SharedSpaceScreenState();
}

class _SharedSpaceScreenState extends State<SharedSpaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SharedSpaceProvider>().initialize();
      }
    });
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite code $code copied to clipboard!'),
        backgroundColor: AppColors.deepForest,
      ),
    );
  }

  Future<void> _generateNewInviteCode() async {
    final shared = context.read<SharedSpaceProvider>();
    final code = await shared.generateInviteCode();
    if (mounted && code != null) {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated new secure invite code $code (copied)! Valid for 48h.'),
          backgroundColor: AppColors.deepForest,
        ),
      );
    }
  }

  void _sendCheer(String emoji, String message) async {
    final shared = context.read<SharedSpaceProvider>();
    final success = await shared.sendCheer(emoji, message);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sent cheer to ${shared.partnerName}: $emoji $message'),
            backgroundColor: AppColors.deepForest,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send cheer. Please check internet connection.'),
            backgroundColor: AppColors.urgentRed,
          ),
        );
      }
    }
  }

  void _showJoinSpaceDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Private Shared Space'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your study partner\'s invite code (e.g. NEST-7X9K2M):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. NEST-8492KM',
                border: OutlineInputBorder(borderRadius: AppRadius.roundedM),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Partner\'s Name (optional nickname):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Study Partner 🌿',
                border: OutlineInputBorder(borderRadius: AppRadius.roundedM),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              final name = nameController.text.trim().isNotEmpty
                  ? nameController.text.trim()
                  : 'Study Partner 🌿';
              Navigator.pop(ctx);

              final shared = context.read<SharedSpaceProvider>();
              final success = await shared.joinSpace(code, partnerNameOverride: name);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Connected with ${shared.partnerName} in Private Shared Space!'),
                      backgroundColor: AppColors.deepForest,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(shared.errorMessage ?? 'Failed to connect. Please verify code.'),
                      backgroundColor: AppColors.urgentRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveSpace() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Shared Space?'),
        content: const Text(
          'Are you sure you want to leave this accountability space? Your own personal study trees and XP will remain completely safe on your device.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
            onPressed: () async {
              Navigator.pop(ctx);
              final shared = context.read<SharedSpaceProvider>();
              await shared.leaveSpace();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Disconnected from shared space.')),
                );
              }
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = NavThemeColors.of(context);
    final sharedProvider = context.watch<SharedSpaceProvider>();
    final authService = context.watch<AuthService>();
    final forest = context.watch<ForestProvider>();

    final isPaired = sharedProvider.isPaired;
    final myFocusMins = forest.totalFocusMinutes;
    final combinedFocusMins = myFocusMins + (isPaired ? sharedProvider.partnerFocusMinutesToday : 0);
    final myTreesCount = forest.totalTreesCount;
    final combinedTreesCount = myTreesCount + (isPaired ? sharedProvider.partnerTreesCountToday : 0);

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        iconTheme: IconThemeData(color: colors.primary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Private Shared Space', style: AppTypography.titleLarge.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w800)),
            Text('1-to-1 accountability with your study partner', style: AppTypography.bodySmall.copyWith(color: colors.textMuted)),
          ],
        ),
        actions: [
          if (isPaired)
            IconButton(
              icon: Icon(Icons.link_off_rounded, color: colors.textMuted),
              tooltip: 'Disconnect Space',
              onPressed: _confirmLeaveSpace,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cloud Sync & Auth Banner
            if (!authService.isAuthenticated)
              _buildAuthPromptBanner(authService, isDark),

            if (sharedProvider.isLoading)
              const LinearProgressIndicator(color: AppColors.deepForest),

            const SizedBox(height: 8),

            if (isPaired) ...[
              // 1. Enchanted Whispering Meadow Sanctuary Hero Banner
              _buildEnchantedSanctuaryHero(sharedProvider, isDark),

              const SizedBox(height: AppSpacing.l),

              // 2. 4 Quick-Action Cards: Shared Forest, Love Notes, Challenges, Timeline
              _buildFourActionCards(context, isDark, sharedProvider, forest),

              const SizedBox(height: AppSpacing.l),

              // Partner Status Card
              _buildPartnerStatusCard(sharedProvider, isDark),

              const SizedBox(height: AppSpacing.l),

              // Combined Metrics Card
              _buildCombinedMetricsCard(
                combinedFocusMins,
                combinedTreesCount,
                myTreesCount,
                sharedProvider.partnerName,
                isDark,
              ),

              const SizedBox(height: AppSpacing.l),

              // Shared Forest Grove Preview
              _buildSharedGroveCard(forest, sharedProvider, isDark),

              const SizedBox(height: AppSpacing.l),

              // Pre-written Cheer Messages
              _buildEncouragementCheerCard(sharedProvider, isDark),

              const SizedBox(height: AppSpacing.l),

              // Privacy & Security Guarantee
              _buildPrivacyNoticeCard(isDark),
            ] else ...[
              // Unpaired State / Join Space
              _buildUnpairedCard(sharedProvider, isDark),

              const SizedBox(height: AppSpacing.l),

              // How It Works
              _buildHowItWorksCard(isDark),

              const SizedBox(height: AppSpacing.l),

              // Privacy & Security Guarantee
              _buildPrivacyNoticeCard(isDark),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthPromptBanner(AuthService authService, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberWarm.withValues(alpha: 0.14),
        borderRadius: AppRadius.roundedM,
        border: Border.all(color: AppColors.amberWarm.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_sync_rounded, color: AppColors.amberHoney, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cloud Sync Available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Sign in to enable real cross-device partner pairing and secure cloud backups.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => authService.signInWithGoogle(),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            child: const Text('Sign In', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerStatusCard(SharedSpaceProvider shared, bool isDark) {
    final partnerName = shared.partnerName;
    final initial = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'P';
    final isFocusing = shared.isPartnerFocusing;

    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.sageTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.sageBorder, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.deepForest),
                  ),
                ),
              ),
              if (isFocusing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.forestEmerald,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
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
                        partnerName,
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    NestBadge(
                      label: isFocusing ? 'Focusing 🟢' : 'Connected',
                      variant: isFocusing ? NestBadgeVariant.safeGreen : NestBadgeVariant.neutral,
                      isDense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isFocusing
                      ? 'Studying now: ${shared.partnerTopic}'
                      : 'Today: ${shared.partnerFocusMinutesToday} mins • ${shared.partnerTreesCountToday} trees',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: isDark ? AppColors.sageLight : AppColors.deepForest),
            onPressed: () => _copyInviteCode(shared.inviteCode),
            tooltip: 'Copy Invite Code',
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedMetricsCard(
    int combinedFocusMins,
    int combinedTrees,
    int myTrees,
    String partnerName,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.cardSurface,
              borderRadius: AppRadius.roundedL,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
              boxShadow: AppShadows.softCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Combined Focus', style: AppTypography.labelSmall),
                const SizedBox(height: 4),
                Text('$combinedFocusMins mins', style: AppTypography.titleLarge.copyWith(color: isDark ? AppColors.forestEmerald : AppColors.deepForest)),
                const SizedBox(height: 2),
                Text('Today • Both students', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.cardSurface,
              borderRadius: AppRadius.roundedL,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
              boxShadow: AppShadows.softCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shared Grove', style: AppTypography.labelSmall),
                const SizedBox(height: 4),
                Text('$combinedTrees Trees', style: AppTypography.titleLarge.copyWith(color: AppColors.sageGreen)),
                const SizedBox(height: 2),
                Text('$myTrees You • ${combinedTrees - myTrees} $partnerName', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedGroveCard(ForestProvider forest, SharedSpaceProvider shared, bool isDark) {
    final trees = forest.trees;
    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.elevatedSurface,
      border: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.sageBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shared Grove Sanctuary', style: AppTypography.titleMedium),
                  Text('Both your study trees growing side by side', style: AppTypography.bodySmall),
                ],
              ),
              const NestBadge(label: 'Private 1-on-1', variant: NestBadgeVariant.neutral),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Container(
            height: 94,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.warmCream,
              borderRadius: AppRadius.roundedM,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
            ),
            child: trees.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Your shared grove is ready! Start a focus session to grow your first joint tree.',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: trees.take(4).map((t) {
                      return _buildGroveTree('You', Icons.park_rounded, AppColors.deepForest, t.species.displayName);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroveTree(String owner, IconData icon, Color color, String name) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(name, style: AppTypography.labelSmall.copyWith(fontSize: 10)),
        Text(owner, style: AppTypography.labelSmall.copyWith(fontSize: 8, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildEncouragementCheerCard(SharedSpaceProvider shared, bool isDark) {
    final cheers = shared.cheers;
    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Send Pre-written Cheer', style: AppTypography.titleMedium),
              NestBadge(label: '${cheers.length} sent', variant: NestBadgeVariant.amber, isDense: true),
            ],
          ),
          const SizedBox(height: 4),
          Text('Distraction-free encouragement without social media rabbit holes', style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCheerChip('🌱', 'Keep growing!', isDark),
              _buildCheerChip('⭐', 'Proud of you!', isDark),
              _buildCheerChip('🔥', 'CBSE 10th Board ready!', isDark),
              _buildCheerChip('☕', 'Remember to take a break', isDark),
              _buildCheerChip('🏆', 'Let\'s score 95%+!', isDark),
            ],
          ),
          if (cheers.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text('Recent Cheers', style: AppTypography.labelSmall),
            const SizedBox(height: 6),
            ...cheers.take(3).map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    children: [
                      Text(c.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        '${c.senderName}: "${c.message}"',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildCheerChip(String emoji, String message, bool isDark) {
    return InkWell(
      onTap: () => _sendCheer(emoji, message),
      borderRadius: AppRadius.roundedS,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.warmCream,
          borderRadius: AppRadius.roundedS,
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(message, style: AppTypography.labelMedium.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpairedCard(SharedSpaceProvider shared, bool isDark) {
    final code = shared.inviteCode;

    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sageGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, size: 44, color: AppColors.sageGreen),
          ),
          const SizedBox(height: 16),
          Text('Private 1-to-1 Shared Space', style: AppTypography.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Pair with one trusted study partner to share focus accountability, grow a joint forest grove, and stay motivated together for CBSE Class 10.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Invite code box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.warmCream,
              borderRadius: AppRadius.roundedM,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR INVITE CODE', style: AppTypography.labelSmall.copyWith(fontSize: 10, letterSpacing: 0.8)),
                      const SizedBox(height: 2),
                      Text(
                        code.isNotEmpty ? code : 'NEST-2027-CBSE',
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.forestEmerald : AppColors.deepForest,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: isDark ? AppColors.sageLight : AppColors.deepForest, size: 20),
                  onPressed: _generateNewInviteCode,
                  tooltip: 'Generate New Code',
                ),
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: isDark ? AppColors.sageLight : AppColors.deepForest, size: 20),
                  onPressed: () => _copyInviteCode(code),
                  tooltip: 'Copy Code',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          NestButton(
            label: 'Share Invite Code',
            icon: Icons.share_rounded,
            onPressed: () => _copyInviteCode(code),
            variant: NestButtonVariant.primary,
            isFullWidth: true,
          ),
          const SizedBox(height: 10),
          NestButton(
            label: 'Join Partner with Code',
            icon: Icons.login_rounded,
            onPressed: _showJoinSpaceDialog,
            variant: NestButtonVariant.secondary,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(bool isDark) {
    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How 1-to-1 Accountability Works', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text('Designed for pure study focus without social media distractions', style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.m),
          _buildHowItWorksItem(
            icon: Icons.park_rounded,
            iconColor: isDark ? AppColors.forestEmerald : AppColors.deepForest,
            title: 'Joint Forest Sanctuary',
            subtitle: 'Every time either of you completes a focus session, your trees grow together in a shared grove.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildHowItWorksItem(
            icon: Icons.timer_outlined,
            iconColor: AppColors.sageGreen,
            title: 'Live Focus Indicator',
            subtitle: 'See when your partner is studying live to inspire each other without interrupting.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildHowItWorksItem(
            icon: Icons.favorite_outline_rounded,
            iconColor: AppColors.urgentRed,
            title: 'Pre-written Cheers',
            subtitle: 'Send encouragement emojis and notes with zero chat drama or notification spam.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: AppRadius.roundedM,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLarge),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyNoticeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.sageTint.withValues(alpha: 0.5),
        borderRadius: AppRadius.roundedM,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.sageBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: isDark ? AppColors.forestEmerald : AppColors.deepForest, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy & Security Guarantee', style: AppTypography.labelMedium.copyWith(color: isDark ? AppColors.forestEmerald : AppColors.deepForest)),
                const SizedBox(height: 2),
                Text(
                  'Your private notes, planner tasks, study journals, and unshared syllabus details remain 100% private to your device. Only mutual focus minutes and cheers are shared in this space.',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnchantedSanctuaryHero(SharedSpaceProvider shared, bool isDark) {
    final partnerName = shared.partnerName.isNotEmpty ? shared.partnerName : 'Navya';
    final isFocusing = shared.isPartnerFocusing;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2F23), const Color(0xFF121B15)]
              : [const Color(0xFFE8F3EB), const Color(0xFFF6FBF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.sageBorder,
          width: 1.5,
        ),
        boxShadow: isDark ? [] : AppShadows.softCard,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.sageTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.sageBorder, width: 1.5),
                ),
                child: const Text('🐱', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cherryPink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cherryPink.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.favorite_rounded, color: AppColors.cherryPink, size: 14),
                    SizedBox(width: 4),
                    Text('Sanctuary', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cherryPink)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.sageTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.sageBorder, width: 1.5),
                ),
                child: const Text('🐱', style: TextStyle(fontSize: 22)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Arya ❤️ $partnerName',
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Together Since 12 Nov 2024 (338 Days) • Whispering Meadow',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isFocusing
                  ? AppColors.safeGreen.withValues(alpha: 0.15)
                  : (isDark ? AppColors.forestEmerald : AppColors.deepForest).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isFocusing ? AppColors.safeGreen : (isDark ? AppColors.forestEmerald : AppColors.deepForest),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isFocusing ? 'Partner Studying Now 🌿' : 'Accountability Active 🕊️',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isFocusing ? AppColors.safeGreen : (isDark ? AppColors.forestEmerald : AppColors.deepForest),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourActionCards(BuildContext context, bool isDark, SharedSpaceProvider shared, ForestProvider forest) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.forest_rounded,
                iconColor: AppColors.forestEmerald,
                title: 'Shared Forest',
                subtitle: '${forest.totalTreesCount + shared.partnerTreesCountToday} Trees Planted',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Viewing Shared Forest Grove below 🌲')),
                  );
                },
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.cherryPink,
                title: 'Love Notes',
                subtitle: 'Send Cheers & Notes',
                onTap: () => _sendCheer('💌', 'Keep going, you are doing amazing!'),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.amberHoney,
                title: 'Challenges',
                subtitle: 'Daily Focus Goals',
                onTap: () => _openChallengesDialog(context, isDark, shared),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.auto_stories_rounded,
                iconColor: isDark ? AppColors.forestEmerald : AppColors.deepForest,
                title: 'Timeline',
                subtitle: 'Milestones & Memories',
                onTap: () => _openTimelineDialog(context, isDark),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
          boxShadow: isDark ? [] : AppShadows.softCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChallengesDialog(BuildContext context, bool isDark, SharedSpaceProvider shared) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.emoji_events_rounded, color: AppColors.amberHoney),
            SizedBox(width: 8),
            Text('Study Challenges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChallengeItem(
              'Daily 50m Focus Target',
              '${(shared.partnerFocusMinutesToday).clamp(0, 50)}/50 mins completed',
              0.8,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildChallengeItem(
              'Twin Oaks Challenge',
              'Plant 2 healthy trees in Whispering Meadow today',
              1.0,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildChallengeItem(
              'Weekend Revision Sprint',
              'Cover 3 CBSE chapters together',
              0.66,
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeItem(String title, String desc, double progress, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              if (progress >= 1.0)
                const Icon(Icons.check_circle_rounded, color: AppColors.safeGreen, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            color: progress >= 1.0 ? AppColors.safeGreen : AppColors.sageGreen,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  void _openTimelineDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.auto_stories_rounded, color: AppColors.sageGreen),
            SizedBox(width: 8),
            Text('Partner Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimelineItem('12 Nov 2024', 'Sanctuary Meadow established together 🌸', isDark),
            const SizedBox(height: 10),
            _buildTimelineItem('05 Jan 2025', 'First Ancient Oak bloomed in Shared Forest 🌳', isDark),
            const SizedBox(height: 10),
            _buildTimelineItem('18 Feb 2025', 'Surpassed 50 hours of mutual CBSE study 🏆', isDark),
            const SizedBox(height: 10),
            _buildTimelineItem('Today', 'Staying accountable & motivated every single day ✨', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String date, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.sageGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(date, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.forestEmerald : AppColors.deepForest)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
        ),
      ],
    );
  }
}
