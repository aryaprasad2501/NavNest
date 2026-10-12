import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/forest_journal_entry.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import 'providers/forest_provider.dart';

class ForestJournalScreen extends StatefulWidget {
  const ForestJournalScreen({super.key});

  @override
  State<ForestJournalScreen> createState() => _ForestJournalScreenState();
}

class _ForestJournalScreenState extends State<ForestJournalScreen> {
  String _selectedTab = 'All';

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final diffDays = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  IconData _resolveIcon(ForestJournalEntry entry) {
    switch (entry.category.toUpperCase()) {
      case 'BLOOM':
        return Icons.park_rounded;
      case 'PLANTING':
        return Icons.spa_rounded;
      case 'MILESTONE':
        return Icons.stars_rounded;
      case 'ACHIEVEMENT':
        return Icons.emoji_events_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  NestBadgeVariant _resolveBadgeVariant(ForestJournalEntry entry) {
    if (entry.category == 'BLOOM' || entry.category == 'ACHIEVEMENT') {
      return NestBadgeVariant.forest;
    }
    if (entry.coinsEarned < 0) {
      return NestBadgeVariant.neutral;
    }
    return NestBadgeVariant.amber;
  }

  String _resolveRewardText(ForestJournalEntry entry) {
    if (entry.xpEarned > 0 && entry.coinsEarned > 0) {
      return '+${entry.xpEarned} XP • +${entry.coinsEarned} C';
    } else if (entry.xpEarned > 0) {
      return '+${entry.xpEarned} XP';
    } else if (entry.coinsEarned < 0) {
      return '${entry.coinsEarned} Coins';
    } else if (entry.coinsEarned > 0) {
      return '+${entry.coinsEarned} Coins';
    }
    return 'Logged';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final forest = context.watch<ForestProvider>();
    final tabs = ['All', 'Trees', 'Rewards', 'Milestones'];

    final filtered = _selectedTab == 'All'
        ? forest.journalEntries
        : forest.journalEntries.where((e) {
            final cat = e.category.toUpperCase();
            if (_selectedTab == 'Trees') return cat == 'PLANTING' || cat == 'BLOOM';
            if (_selectedTab == 'Rewards') return e.coinsEarned != 0 || e.xpEarned > 0;
            if (_selectedTab == 'Milestones') return cat == 'MILESTONE' || cat == 'ACHIEVEMENT';
            return true;
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Text('Forest Journal', style: AppTypography.titleLarge),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
          ),

          // Timeline Events List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.sageGreen),
                        const SizedBox(height: 12),
                        Text('No journal entries yet', style: AppTypography.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Complete focus sessions to record your sanctuary growth.',
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
                      return _buildJournalCard(item, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(ForestJournalEntry item, bool isDark) {
    final dateHeader = _formatDateHeader(item.date);
    final timeStr = _formatTime(item.date);
    final iconData = _resolveIcon(item);
    final badgeVar = _resolveBadgeVariant(item);
    final rewardText = _resolveRewardText(item);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
        borderRadius: AppRadius.roundedL,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.sageTint,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: AppColors.deepForest, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$dateHeader • $timeStr',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                    NestBadge(label: rewardText, variant: badgeVar, isDense: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.notes!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
                if (item.subjectName != null && item.subjectName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.sageTint,
                      borderRadius: AppRadius.roundedS,
                    ),
                    child: Text(
                      item.subjectName!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepForest,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
