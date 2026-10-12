import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  bool _isPaired = true;
  final String _inviteCode = 'NEST-2027-CBSE';
  final String _partnerName = 'Divya 🌸';
  final String _partnerTopic = 'Science: Chemical Reactions';
  final int _partnerFocusMinutesToday = 145;
  int _cheersSent = 3;

  void _copyInviteCode() {
    Clipboard.setData(ClipboardData(text: _inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code NEST-2027-CBSE copied to clipboard!')),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Private Shared Space'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 6-character code from your study partner:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. NEST-8492',
                border: OutlineInputBorder(borderRadius: AppRadius.roundedM),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isPaired = true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Connected with $_partnerName in Private Shared Space!'),
                  backgroundColor: AppColors.deepForest,
                ),
              );
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isPaired = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disconnected from shared space.')),
              );
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
    final combinedTreesCount = myTreesCount + (_isPaired ? 18 : 0);

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
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerStatusCard(bool isDark) {
    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.sageTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.sageBorder, width: 1.5),
                ),
                child: const Center(
                  child: Text('D', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.deepForest)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.safeGreen,
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
                    Text(_partnerName, style: AppTypography.titleMedium),
                    const SizedBox(width: 8),
                    const NestBadge(label: 'Studying Now', variant: NestBadgeVariant.safeGreen, isDense: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Active Focus: $_partnerTopic • 32m', style: AppTypography.bodySmall),
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
                Text('$myTrees You • 18 Divya', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedGroveCard(ForestProvider forest, bool isDark) {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGroveTree('You', Icons.park_rounded, AppColors.deepForest, forest.trees.isNotEmpty ? forest.trees.first.species.displayName : 'Pine'),
                _buildGroveTree('Divya', Icons.spa_rounded, AppColors.sageGreen, 'Cherry Blossom'),
                _buildGroveTree('You', Icons.nature_rounded, AppColors.deepForest, 'Ancient Oak'),
                _buildGroveTree('Divya', Icons.park_rounded, AppColors.sageGreen, 'Golden Ginkgo'),
              ],
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

  Widget _buildUnpairedCard(bool isDark) {
    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.sageGreen),
          const SizedBox(height: 14),
          Text('Study Together in Private', style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Connect with one friend or study partner. Grow a joint forest and share exam countdowns distraction-free.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          NestButton(
            label: 'Share Invite Code',
            icon: Icons.copy_rounded,
            onPressed: _copyInviteCode,
            variant: NestButtonVariant.primary,
            isFullWidth: true,
          ),
          const SizedBox(height: 10),
          NestButton(
            label: 'Join with Code',
            icon: Icons.login_rounded,
            onPressed: _showJoinSpaceDialog,
            variant: NestButtonVariant.secondary,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
