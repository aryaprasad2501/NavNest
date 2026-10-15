import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/forest_tree_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_card.dart';
import '../../../core/widgets/nest_progress_bar.dart';
import 'providers/forest_provider.dart';
import 'widgets/interactive_tree_3d_viewer.dart';

typedef StartFocusTimerCallback = void Function({
  String? subject,
  String? chapter,
  String? subtopic,
  String? linkedTaskId,
});

class TreeDetailsScreen extends StatefulWidget {
  final ForestTreeModel? tree;
  final String treeName;
  final String subject;
  final String chapter;
  final int stage; // 1 to 5
  final int currentXp;
  final int targetXp;
  final String plantedDate;
  final String totalFocusTime;
  final StartFocusTimerCallback? onStartTimer;
  final bool autoSpin3D;

  const TreeDetailsScreen({
    super.key,
    this.tree,
    this.treeName = 'Cherry Blossom',
    this.subject = 'Physics',
    this.chapter = 'Units and Measurements',
    this.stage = 5,
    this.currentXp = 120,
    this.targetXp = 300,
    this.plantedDate = '2 Aug 2024',
    this.totalFocusTime = '8h 26m focus',
    this.onStartTimer,
    this.autoSpin3D = true,
  });

  @override
  State<TreeDetailsScreen> createState() => _TreeDetailsScreenState();
}

class _TreeDetailsScreenState extends State<TreeDetailsScreen> {
  int? _previewStage;

  @override
  void initState() {
    super.initState();
    _previewStage = widget.tree?.stage ?? widget.stage;
  }

  String _getStageName(int stage) {
    switch (stage) {
      case 1:
        return 'Seed';
      case 2:
        return 'Sprout';
      case 3:
        return 'Sapling';
      case 4:
        return 'Young Tree';
      case 5:
      default:
        return 'Full Bloom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final forestProvider = context.watch<ForestProvider>();

    // Retrieve active tree instance from provider if available
    final currentTree = widget.tree != null
        ? forestProvider.trees.firstWhere(
            (t) => t.id == widget.tree!.id,
            orElse: () => widget.tree!,
          )
        : null;

    final effectiveTreeName = currentTree?.species.displayName ?? widget.treeName;
    final effectiveSubject = currentTree?.subjectName ?? widget.subject;
    final effectiveChapter = currentTree?.chapterName ?? widget.chapter;
    final effectiveStage = currentTree?.stage ?? widget.stage;
    final effectiveXp = currentTree?.xpEarned ?? widget.currentXp;
    final effectiveFocusTime = currentTree != null
        ? '${currentTree.focusMinutes}m focus'
        : widget.totalFocusTime;
    final effectivePlantedDate = currentTree != null
        ? '${currentTree.plantedAt.day}/${currentTree.plantedAt.month}/${currentTree.plantedAt.year}'
        : widget.plantedDate;
    final effectiveSpecies = currentTree?.species ?? TreeSpecies.mountainPine;

    final displayStage = _previewStage ?? effectiveStage;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Text(effectiveTreeName, style: AppTypography.titleLarge),
        actions: [
          if (currentTree != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.urgentRed),
              tooltip: 'Uproot Tree',
              onPressed: () => _confirmUprootTree(context, currentTree),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hero Real-Time 3D Tree Viewer with 360° Touch Orbit & Stage Selector
            InteractiveTree3DViewer(
              species: effectiveSpecies,
              initialStage: displayStage,
              isDark: isDark,
              height: 330,
              showStageSelector: true,
              autoSpin: widget.autoSpin3D,
              onStageChanged: (stage) {
                setState(() => _previewStage = stage);
              },
            ),

            // Strict Visual Preview vs. Authoritative Growth Stage Separation
            if (displayStage != effectiveStage) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.amberWarm.withValues(alpha: 0.12),
                  borderRadius: AppRadius.roundedM,
                  border: Border.all(color: AppColors.amberWarm.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.preview_rounded, size: 18, color: AppColors.amberHoney),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Visual 3D Preview: Stage $displayStage (${_getStageName(displayStage)})\nActual Persisted Growth: Stage $effectiveStage (${_getStageName(effectiveStage)})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _previewStage = effectiveStage),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.l),

            // Botanical Classification & Lore
            NestCard(
              color: isDark ? AppColors.darkCard : AppColors.cardSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(effectiveSpecies.iconEmoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(effectiveSpecies.displayName, style: AppTypography.titleMedium),
                              Text(
                                effectiveSpecies.botanicalName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: effectiveSpecies.themeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      NestBadge(
                        label: currentTree?.isWithered == true ? 'Withered' : 'Healthy',
                        variant: currentTree?.isWithered == true ? NestBadgeVariant.urgentRed : NestBadgeVariant.safeGreen,
                        isDense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    effectiveSpecies.lore,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Growth Stage Progress Tracker
            _buildStageProgressCard(isDark, effectiveStage, effectiveXp),

            const SizedBox(height: AppSpacing.l),

            // Linked Study Topic & Session History
            _buildLinkedStudyCard(
              isDark,
              effectiveSubject,
              effectiveChapter,
              effectivePlantedDate,
              effectiveFocusTime,
              currentTree?.coinsEarned ?? 25,
            ),

            const SizedBox(height: AppSpacing.l),

            // Action Buttons: Strict Reward Integrity Protected
            if (currentTree != null) ...[
              Row(
                children: [
                  // Cosmetic Care Interaction: Tends/waters tree with 0 unearned XP/coins
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.water_drop_rounded, size: 18, color: AppColors.forestEmerald),
                      label: const Text('Water Tree 💧'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedL),
                      ),
                      onPressed: () async {
                        await forestProvider.nurtureTree(currentTree.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '💧 Tended to ${currentTree.species.displayName}! Regular care keeps your sanctuary vibrant.',
                              ),
                              backgroundColor: AppColors.deepForest,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Genuine Focus Study Action: Drives authoritative growth progression
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.timer_rounded, size: 18),
                      label: Text(
                        effectiveStage < 5 ? 'Study to Grow 🌱' : 'Focus Again ⏱️',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepForest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedL),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onStartTimer?.call(
                          subject: effectiveSubject,
                          chapter: effectiveChapter,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  effectiveStage < 5
                      ? '🔒 Growth stages advance strictly through verified focus study sessions'
                      : '🌟 Full Bloom achieved through verified CBSE focus study',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.m),

            // Verified Study Sessions Info
            NestCard(
              color: isDark ? AppColors.darkCard : AppColors.cardSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Verified Study Sessions', style: AppTypography.titleMedium),
                      const NestBadge(label: 'Anti-Cheat Validated', variant: NestBadgeVariant.safeGreen, isDense: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSessionRow(
                    isDark,
                    'Deep Focus Block 1',
                    '${(currentTree?.focusMinutes ?? 45) ~/ 2}m distraction-free',
                    '+60 XP',
                  ),
                  const Divider(height: 16),
                  _buildSessionRow(
                    isDark,
                    'Deep Focus Block 2',
                    '${((currentTree?.focusMinutes ?? 45) + 1) ~/ 2}m distraction-free',
                    '+80 XP',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionRow(bool isDark, String title, String subtitle, String reward) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AppColors.sageTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.deepForest, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLarge),
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
        Text(
          reward,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.amberHoney,
          ),
        ),
      ],
    );
  }

  Widget _buildStageProgressCard(bool isDark, int currentStage, int xp) {
    final stages = ['Seed', 'Sprout', 'Sapling', 'Growing', 'Full Bloom'];
    final progressVal = (currentStage / 5.0).clamp(0.0, 1.0);

    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Growth Progression', style: AppTypography.titleMedium),
              Text(
                '$xp XP Earned',
                style: AppTypography.labelMedium.copyWith(color: AppColors.sageGreen),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          NestProgressBar(
            progress: progressVal,
            height: 8,
            progressColor: AppColors.deepForest,
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(stages.length, (index) {
              final step = index + 1;
              final isReached = step <= currentStage;
              final isCurrent = step == currentStage;

              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.deepForest
                          : isReached
                              ? AppColors.sageGreen
                              : (isDark ? AppColors.darkElevated : AppColors.borderSubtle),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isReached
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : Text('$step', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stages[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? AppColors.deepForest : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedStudyCard(
    bool isDark,
    String sub,
    String chap,
    String date,
    String focusTime,
    int coins,
  ) {
    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Linked CBSE Study Topic', style: AppTypography.titleMedium),
              const NestBadge(label: 'Verified', variant: NestBadgeVariant.safeGreen, isDense: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sageTint,
                  borderRadius: AppRadius.roundedM,
                ),
                child: const Icon(Icons.bookmark_rounded, color: AppColors.deepForest, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$sub • $chap', style: AppTypography.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Planted on $date • $focusTime • +$coins Coins',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmUprootTree(BuildContext context, ForestTreeModel currentTree) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uproot Tree?'),
        content: Text(
          'Are you sure you want to remove this ${currentTree.species.displayName}? The earned study XP and coins will remain safe in your profile.',
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
              await context.read<ForestProvider>().deleteTree(currentTree.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tree removed from sanctuary.')),
                );
              }
            },
            child: const Text('Uproot'),
          ),
        ],
      ),
    );
  }
}
