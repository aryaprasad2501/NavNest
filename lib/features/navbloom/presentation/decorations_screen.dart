import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/forest_decoration_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import 'providers/forest_provider.dart';

class DecorationsScreen extends StatefulWidget {
  const DecorationsScreen({super.key});

  @override
  State<DecorationsScreen> createState() => _DecorationsScreenState();
}

class _DecorationsScreenState extends State<DecorationsScreen> {
  String _selectedCategory = 'All';

  IconData _resolveIcon(ForestDecorationModel item) {
    switch (item.category) {
      case DecorationCategory.lighting:
        return Icons.light_mode_rounded;
      case DecorationCategory.flora:
        return Icons.local_florist_rounded;
      case DecorationCategory.pathway:
        return Icons.grain_rounded;
      case DecorationCategory.furniture:
        return Icons.chair_alt_rounded;
    }
  }

  void _handleDecorationTap(BuildContext context, ForestDecorationModel item, ForestProvider forest) {
    if (item.isUnlocked) {
      // Toggle equip status
      forest.toggleEquipDecoration(item.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !item.isEquipped
                ? '🌿 ${item.name} placed in your Sanctuary!'
                : '${item.name} stored in sanctuary inventory.',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.deepForest,
        ),
      );
    } else {
      // Prompt to unlock
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Unlock ${item.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, color: AppColors.coinGold, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Cost: ${item.costCoins} Coins',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Your balance: ${forest.userCoins} Coins',
                style: TextStyle(
                  color: forest.userCoins >= item.costCoins ? AppColors.sageGreen : AppColors.urgentRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.deepForest),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await forest.unlockDecoration(item.id, item.costCoins);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✨ Unlocked and placed ${item.name}!'),
                        backgroundColor: AppColors.deepForest,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Not enough coins! Complete focus sessions to earn coins.'),
                        backgroundColor: AppColors.urgentRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final forest = context.watch<ForestProvider>();

    final categories = ['All', 'Lighting', 'Flora & Flowers', 'Pathway', 'Cozy Haven'];

    final filtered = _selectedCategory == 'All'
        ? forest.decorations
        : forest.decorations.where((i) {
            if (_selectedCategory == 'Lighting') return i.category == DecorationCategory.lighting;
            if (_selectedCategory == 'Flora & Flowers') return i.category == DecorationCategory.flora;
            if (_selectedCategory == 'Pathway') return i.category == DecorationCategory.pathway;
            if (_selectedCategory == 'Cozy Haven') return i.category == DecorationCategory.furniture;
            return true;
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Text('Sanctuary Decorations', style: AppTypography.titleLarge),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.warmCream,
              borderRadius: AppRadius.roundedFull,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded, color: AppColors.coinGold, size: 16),
                const SizedBox(width: 4),
                Text('${forest.userCoins} Coins', style: AppTypography.labelMedium),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
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

          // Grid of Decoration Cards
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No decorations in this category.',
                      style: AppTypography.bodyMedium,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return GestureDetector(
                        onTap: () => _handleDecorationTap(context, item, forest),
                        child: _buildDecorationCard(item, isDark),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorationCard(ForestDecorationModel item, bool isDark) {
    final iconData = _resolveIcon(item);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
        borderRadius: AppRadius.roundedL,
        border: Border.all(
          color: item.isEquipped
              ? AppColors.deepForest
              : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
          width: item.isEquipped ? 2.0 : 1.0,
        ),
        boxShadow: item.isEquipped
            ? [
                BoxShadow(
                  color: AppColors.deepForest.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : AppShadows.softCard,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.isEquipped
                      ? AppColors.sageTint
                      : (isDark ? AppColors.darkCard : AppColors.warmCream),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  size: 22,
                  color: item.isUnlocked ? AppColors.deepForest : AppColors.textMuted,
                ),
              ),
              if (item.isEquipped)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.deepForest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (item.isEquipped)
            const NestBadge(label: 'Equipped', variant: NestBadgeVariant.safeGreen, isDense: true)
          else if (item.isUnlocked)
            const NestBadge(label: 'Owned', variant: NestBadgeVariant.neutral, isDense: true)
          else
            NestBadge(
              label: '${item.costCoins} Coins',
              variant: NestBadgeVariant.amber,
              isDense: true,
              icon: Icons.monetization_on_rounded,
            ),
        ],
      ),
    );
  }
}
