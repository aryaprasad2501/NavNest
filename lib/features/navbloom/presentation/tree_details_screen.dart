import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/forest_tree_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_button.dart';
import '../../../core/widgets/nest_card.dart';
import '../../../core/widgets/nest_progress_bar.dart';
import 'providers/forest_provider.dart';

class TreeDetailsScreen extends StatelessWidget {
  final ForestTreeModel? tree;
  final String treeName;
  final String subject;
  final String chapter;
  final int stage; // 1 to 5
  final int currentXp;
  final int targetXp;
  final String plantedDate;
  final String totalFocusTime;

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
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final forestProvider = context.watch<ForestProvider>();

    // Retrieve active tree instance from provider if available
    final currentTree = tree != null
        ? forestProvider.trees.firstWhere(
            (t) => t.id == tree!.id,
            orElse: () => tree!,
          )
        : null;

    final effectiveTreeName = currentTree?.species.displayName ?? treeName;
    final effectiveSubject = currentTree?.subjectName ?? subject;
    final effectiveChapter = currentTree?.chapterName ?? chapter;
    final effectiveStage = currentTree?.stage ?? stage;
    final effectiveXp = currentTree?.xpEarned ?? currentXp;
    final effectiveFocusTime = currentTree != null
        ? '${currentTree.focusMinutes}m focus'
        : totalFocusTime;
    final effectivePlantedDate = currentTree != null
        ? '${currentTree.plantedAt.day}/${currentTree.plantedAt.month}/${currentTree.plantedAt.year}'
        : plantedDate;
    final effectiveSpecies = currentTree?.species ?? TreeSpecies.mountainPine;

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
            // Grand Illustrated Tree View Card
            _buildGrandTreeIllustrationCard(isDark, effectiveSpecies, effectiveStage),

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

            // Action Buttons
            if (currentTree != null && effectiveStage < 5)
              NestButton(
                label: 'Nurture Tree (+40 XP, +15 Coins)',
                icon: Icons.water_drop_rounded,
                onPressed: () async {
                  await forestProvider.nurtureTree(currentTree.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🌱 ${currentTree.species.displayName} was nurtured with water and care!',
                        ),
                        backgroundColor: AppColors.deepForest,
                      ),
                    );
                  }
                },
                variant: NestButtonVariant.primary,
                isFullWidth: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),

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

  Widget _buildGrandTreeIllustrationCard(bool isDark, TreeSpecies species, int currentStage) {
    return Container(
      width: double.infinity,
      height: 290,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.warmCream,
        borderRadius: AppRadius.roundedXL,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: AppShadows.softCard,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient circular glow
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF264835).withValues(alpha: 0.5)
                  : species.themeColor.withValues(alpha: 0.15),
            ),
          ),

          // Custom Detailed Dynamic Tree Drawing
          CustomPaint(
            size: const Size(260, 240),
            painter: DynamicStageTreePainter(
              isDark: isDark,
              species: species,
              stage: currentStage,
            ),
          ),

          // Stage Badge Overlay
          Positioned(
            top: 16,
            right: 16,
            child: NestBadge(
              label: currentStage >= 5 ? 'Full Bloom • Lv. 5' : 'Stage $currentStage / 5',
              variant: currentStage >= 5 ? NestBadgeVariant.forest : NestBadgeVariant.amber,
              icon: currentStage >= 5 ? Icons.verified_rounded : Icons.spa_rounded,
            ),
          ),
        ],
      ),
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
                              : (isDark ? AppColors.darkBorder : AppColors.warmCream),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? AppColors.coinGold : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isReached
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : Text(
                              '$step',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stages[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? AppColors.deepForest
                          : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
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

/// Dynamic Painter rendering 5 growth stages for all sanctuary tree species
class DynamicStageTreePainter extends CustomPainter {
  final bool isDark;
  final TreeSpecies species;
  final int stage;

  DynamicStageTreePainter({
    required this.isDark,
    required this.species,
    required this.stage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.72;

    // Soil Mound at base
    final soilPaint = Paint()
      ..color = isDark ? const Color(0xFF2E241E) : const Color(0xFF795548)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 24), width: 110, height: 26),
      soilPaint,
    );

    // Grass Tuft accents
    final grassPaint = Paint()
      ..color = isDark ? const Color(0xFF274B39) : const Color(0xFF81C784)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 36, cy + 18), 7, grassPaint);
    canvas.drawCircle(Offset(cx + 34, cy + 19), 6, grassPaint);

    if (stage == 1) {
      // STAGE 1: SEED
      final seedPaint = Paint()
        ..color = isDark ? const Color(0xFFD4A373) : const Color(0xFFB08968);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 16), width: 14, height: 20),
        seedPaint,
      );
      // Gentle golden glow
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD166).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(cx, cy + 16), 18, glowPaint);
      return;
    }

    if (stage == 2) {
      // STAGE 2: SPROUT
      final stemPaint = Paint()
        ..color = isDark ? const Color(0xFF4CAF50) : const Color(0xFF66BB6A)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, cy + 16), Offset(cx, cy - 14), stemPaint);

      // Two tiny leaves
      final leafPaint = Paint()
        ..color = isDark ? const Color(0xFF81C784) : const Color(0xFFA5D6A7)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 10, cy - 18), width: 18, height: 10),
        leafPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 10, cy - 20), width: 18, height: 10),
        leafPaint,
      );
      return;
    }

    if (stage == 3) {
      // STAGE 3: SAPLING
      final trunkPaint = Paint()
        ..color = isDark ? const Color(0xFF4E342E) : const Color(0xFF6D4C41)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, cy + 18), Offset(cx, cy - 40), trunkPaint);

      final foliagePaint = Paint()
        ..color = species.themeColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy - 45), 26, foliagePaint);
      canvas.drawCircle(Offset(cx - 16, cy - 36), 18, foliagePaint);
      canvas.drawCircle(Offset(cx + 16, cy - 36), 18, foliagePaint);
      return;
    }

    if (stage == 4) {
      // STAGE 4: YOUNG TREE
      final trunkPaint = Paint()
        ..color = isDark ? const Color(0xFF3E2723) : const Color(0xFF5D4037)
        ..style = PaintingStyle.fill;
      final trunkPath = Path()
        ..moveTo(cx - 10, cy + 20)
        ..lineTo(cx + 10, cy + 20)
        ..lineTo(cx + 5, cy - 35)
        ..lineTo(cx + 18, cy - 50)
        ..lineTo(cx + 12, cy - 54)
        ..lineTo(cx + 2, cy - 38)
        ..lineTo(cx - 4, cy - 55)
        ..lineTo(cx - 10, cy - 52)
        ..lineTo(cx - 3, cy - 36)
        ..lineTo(cx - 5, cy + 20)
        ..close();
      canvas.drawPath(trunkPath, trunkPaint);

      final foliagePaint = Paint()
        ..color = species.themeColor.withValues(alpha: 0.95);
      canvas.drawCircle(Offset(cx, cy - 60), 38, foliagePaint);
      canvas.drawCircle(Offset(cx - 28, cy - 50), 26, foliagePaint);
      canvas.drawCircle(Offset(cx + 28, cy - 48), 28, foliagePaint);
      return;
    }

    // STAGE 5: FULL BLOOM
    final trunkPaint = Paint()
      ..color = isDark ? const Color(0xFF38291F) : const Color(0xFF5D4037)
      ..style = PaintingStyle.fill;
    final trunkPath = Path()
      ..moveTo(cx - 16, cy + 24)
      ..lineTo(cx + 16, cy + 24)
      ..lineTo(cx + 8, cy - 20)
      ..lineTo(cx + 26, cy - 45)
      ..lineTo(cx + 18, cy - 50)
      ..lineTo(cx + 4, cy - 28)
      ..lineTo(cx - 6, cy - 55)
      ..lineTo(cx - 14, cy - 50)
      ..lineTo(cx - 4, cy - 26)
      ..lineTo(cx - 24, cy - 42)
      ..lineTo(cx - 28, cy - 36)
      ..lineTo(cx - 8, cy - 18)
      ..close();
    canvas.drawPath(trunkPath, trunkPaint);

    // Layered Canopy
    final foliagePrimary = Paint()..color = species.themeColor;
    final foliageShadow = Paint()
      ..color = isDark
          ? species.themeColor.withValues(alpha: 0.65)
          : species.themeColor.withValues(alpha: 0.85);

    canvas.drawCircle(Offset(cx, cy - 65), 52, foliageShadow);
    canvas.drawCircle(Offset(cx - 45, cy - 60), 38, foliageShadow);
    canvas.drawCircle(Offset(cx + 45, cy - 55), 42, foliageShadow);

    canvas.drawCircle(Offset(cx, cy - 75), 46, foliagePrimary);
    canvas.drawCircle(Offset(cx - 40, cy - 70), 34, foliagePrimary);
    canvas.drawCircle(Offset(cx + 38, cy - 66), 36, foliagePrimary);
    canvas.drawCircle(Offset(cx + 8, cy - 100), 30, foliagePrimary);

    // Wooden Bench & Stone Lantern at foot
    final benchPaint = Paint()
      ..color = isDark ? const Color(0xFF4A3728) : const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 36, cy + 18), width: 34, height: 10),
        const Radius.circular(3),
      ),
      benchPaint,
    );
    canvas.drawRect(Rect.fromLTWH(cx - 50, cy + 22, 4, 10), benchPaint);
    canvas.drawRect(Rect.fromLTWH(cx - 24, cy + 22, 4, 10), benchPaint);

    final lanternPaint = Paint()..color = const Color(0xFFFFD166);
    canvas.drawCircle(Offset(cx + 40, cy + 16), 8, lanternPaint);

    // Fluttering butterflies
    final butterflyPaint = Paint()..color = const Color(0xFFFFE66D);
    canvas.drawCircle(Offset(cx + 55, cy - 70), 4, butterflyPaint);
    canvas.drawCircle(Offset(cx - 60, cy - 85), 3, butterflyPaint);
  }

  @override
  bool shouldRepaint(covariant DynamicStageTreePainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.species != species ||
        oldDelegate.stage != stage;
  }
}
