import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_button.dart';
import '../../../core/widgets/nest_card.dart';
import '../../navbloom/presentation/providers/forest_provider.dart';

class SharedSpaceScreen extends StatefulWidget {
  const SharedSpaceScreen({super.key});

  @override
  State<SharedSpaceScreen> createState() => _SharedSpaceScreenState();
}

class _SharedSpaceScreenState extends State<SharedSpaceScreen> {
  bool _isPaired = false;
  String _inviteCode = 'NEST-2027-CBSE';
  String _partnerName = '';
  String _partnerTopic = '';
  int _partnerFocusMinutesToday = 0;
  int _cheersSent = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadState();
    });
  }

  void _loadState() {
    final storage = context.read<LocalStorageService>();
    setState(() {
      _isPaired = storage.isSharedPaired;
      _partnerName = storage.sharedPartnerName;
      _inviteCode = storage.sharedInviteCode;
      _partnerTopic = _isPaired ? 'CBSE Class 10 Board Prep' : '';
      _partnerFocusMinutesToday = 0;
      _cheersSent = 0;
    });
  }

  void _copyInviteCode() {
    Clipboard.setData(ClipboardData(text: _inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite code $_inviteCode copied to clipboard!'),
        backgroundColor: AppColors.deepForest,
      ),
    );
  }

  void _sendCheer(String emoji, String message) {
    setState(() => _cheersSent++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent cheer to $_partnerName: $emoji $message'),
        backgroundColor: AppColors.deepForest,
        duration: const Duration(seconds: 2),
      ),
    );
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
              'Enter your study partner\'s invite code:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. NEST-8492',
                border: OutlineInputBorder(borderRadius: AppRadius.roundedM),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Partner\'s Name (optional):',
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
              final storage = context.read<LocalStorageService>();
              await storage.setSharedPaired(true);
              await storage.setSharedPartnerName(name);
              setState(() {
                _isPaired = true;
                _partnerName = name;
                _partnerTopic = 'CBSE Class 10 Board Prep';
                _partnerFocusMinutesToday = 0;
                _cheersSent = 0;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Connected with $name in Private Shared Space!'),
                    backgroundColor: AppColors.deepForest,
                  ),
                );
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
          'Are you sure you want to leave this accountability space? Your own personal study trees and XP will remain completely safe.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
            onPressed: () async {
              Navigator.pop(ctx);
              final storage = context.read<LocalStorageService>();
              await storage.clearSharedSpaceData();
              await DatabaseHelper.instance.clearSharedSpace();
              setState(() {
                _isPaired = false;
                _partnerName = '';
                _partnerTopic = '';
                _partnerFocusMinutesToday = 0;
                _cheersSent = 0;
              });
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
    final forest = context.watch<ForestProvider>();
    final myFocusMins = forest.totalFocusMinutes;
    final combinedFocusMins = myFocusMins + (_isPaired ? _partnerFocusMinutesToday : 0);
    final myTreesCount = forest.totalTreesCount;
    final combinedTreesCount = myTreesCount;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Private Shared Space', style: AppTypography.titleLarge),
            Text('Study accountability with one partner', style: AppTypography.bodySmall),
          ],
        ),
        actions: [
          if (_isPaired)
            IconButton(
              icon: const Icon(Icons.link_off_rounded, color: AppColors.textMuted),
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
            if (_isPaired) ...[
              // Partner Status Card
              _buildPartnerStatusCard(isDark),

              const SizedBox(height: AppSpacing.l),

              // Combined Metrics Card
              _buildCombinedMetricsCard(combinedFocusMins, combinedTreesCount, myTreesCount, isDark),

              const SizedBox(height: AppSpacing.l),

              // Shared Forest Grove Preview
              _buildSharedGroveCard(forest, isDark),

              const SizedBox(height: AppSpacing.l),

              // Pre-written Cheer Messages
              _buildEncouragementCheerCard(isDark),

              const SizedBox(height: AppSpacing.l),

              // Privacy & Security Guarantee
              _buildPrivacyNoticeCard(isDark),
            ] else ...[
              // Unpaired State / Join Space
              _buildUnpairedCard(isDark),

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

  Widget _buildPartnerStatusCard(bool isDark) {
    final initial = _partnerName.isNotEmpty ? _partnerName[0].toUpperCase() : 'P';
    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.sageTint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sageBorder, width: 1.5),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.deepForest),
              ),
            ),
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
                        _partnerName,
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const NestBadge(label: 'Connected', variant: NestBadgeVariant.safeGreen, isDense: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _partnerTopic.isNotEmpty ? _partnerTopic : 'CBSE Class 10 Board Prep',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.deepForest),
            onPressed: _copyInviteCode,
            tooltip: 'Copy Invite Code',
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedMetricsCard(int combinedFocusMins, int combinedTrees, int myTrees, bool isDark) {
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
                Text('$combinedFocusMins mins', style: AppTypography.titleLarge.copyWith(color: AppColors.deepForest)),
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
                Text('$myTrees You • 0 $_partnerName', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedGroveCard(ForestProvider forest, bool isDark) {
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
              const NestBadge(label: 'Private 2-Person', variant: NestBadgeVariant.neutral),
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

  Widget _buildEncouragementCheerCard(bool isDark) {
    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Send Pre-written Cheer', style: AppTypography.titleMedium),
              NestBadge(label: '$_cheersSent sent', variant: NestBadgeVariant.amber, isDense: true),
            ],
          ),
          const SizedBox(height: 4),
          Text('Distraction-free encouragement without chat rabbit holes', style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCheerChip('🌱', 'Keep growing!'),
              _buildCheerChip('⭐', 'Proud of you!'),
              _buildCheerChip('🔥', 'CBSE 10th Board ready!'),
              _buildCheerChip('☕', 'Remember to take a break'),
              _buildCheerChip('🏆', 'Let\'s score 95%+!'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheerChip(String emoji, String message) {
    return InkWell(
      onTap: () => _sendCheer(emoji, message),
      borderRadius: AppRadius.roundedS,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warmCream,
          borderRadius: AppRadius.roundedS,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(message, style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpairedCard(bool isDark) {
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
                        _inviteCode,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.deepForest,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppColors.deepForest, size: 20),
                  onPressed: _copyInviteCode,
                  tooltip: 'Copy Code',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          NestButton(
            label: 'Share Invite Code',
            icon: Icons.share_rounded,
            onPressed: _copyInviteCode,
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
            iconColor: AppColors.deepForest,
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
            icon: Icons.favorite_border_rounded,
            iconColor: AppColors.amberHoney,
            title: 'Pre-written Study Cheers',
            subtitle: 'Send one-tap positive cheers like "Keep growing! 🌱" without opening chatting apps.',
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
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: AppRadius.roundedS,
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
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.3,
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
      padding: AppSpacing.cardPaddingDense,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.sageTint.withValues(alpha: 0.5),
        borderRadius: AppRadius.roundedM,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.sageBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.deepForest, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your individual notes and private study topics are never shared. Only grove trees and focus minutes are synced to protect your focus and privacy.',
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.deepForestDark,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
