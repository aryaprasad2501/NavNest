import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/achievement_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_progress_bar.dart';
import 'providers/forest_provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedTab = 'All';

  IconData _resolveIcon(AchievementModel ach) {
    switch (ach.iconName) {
      case 'spa':
        return Icons.spa_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'alarm_on':
        return Icons.alarm_on_rounded;
      case 'dark_mode':
        return Icons.dark_mode_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'school':
        return Icons.school_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final forest = context.watch<ForestProvider>();
    final tabs = ['All', 'In Progress', 'Completed'];

    final filtered = _selectedTab == 'All'
        ? forest.achievements
        : _selectedTab == 'Completed'
            ? forest.achievements.where((a) => a.isUnlocked).toList()
            : forest.achievements.where((a) => !a.isUnlocked).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Text('Forest Achievements', style: AppTypography.titleLarge),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: tabs.map((tab) {
                final isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTab = tab);
                    },
                    selectedColor: isDark ? AppColors.darkElevated : AppColors.sageTint,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.deepForest
                          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.deepForest
                          : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Achievements List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded, size: 48, color: AppColors.sageGreen),
                        const SizedBox(height: 12),
                        Text('No achievements here', style: AppTypography.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Keep focusing to unlock sanctuary milestones!',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildAchievementCard(item, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(AchievementModel item, bool isDark) {
    final iconData = _resolveIcon(item);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
        borderRadius: AppRadius.roundedL,
        border: Border.all(
          color: item.isUnlocked
              ? AppColors.deepForest.withValues(alpha: 0.6)
              : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
          width: item.isUnlocked ? 1.5 : 1.0,
        ),
        boxShadow: item.isUnlocked
            ? [
                BoxShadow(
                  color: AppColors.deepForest.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isUnlocked
                      ? AppColors.sageTint
                      : (isDark ? AppColors.darkCard : AppColors.warmCream),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: item.isUnlocked ? AppColors.deepForest : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        NestBadge(
                          label: '+${item.xpReward} XP • +${item.coinsReward} C',
                          variant: NestBadgeVariant.amber,
                          isDense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item.isUnlocked)
                const NestBadge(label: 'Unlocked', variant: NestBadgeVariant.safeGreen, isDense: true)
              else
                Text(
                  '${item.progress} / ${item.target}',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (!item.isUnlocked) ...[
            const SizedBox(height: 6),
            NestProgressBar(
              progress: item.progressRatio,
              height: 6,
              progressColor: AppColors.deepForest,
            ),
          ],
        ],
      ),
    );
  }
}
