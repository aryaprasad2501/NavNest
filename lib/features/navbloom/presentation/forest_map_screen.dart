import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import 'providers/forest_provider.dart';

class ForestAreaDef {
  final String id;
  final String name;
  final int unlockLevel;
  final String description;
  final IconData icon;

  const ForestAreaDef({
    required this.id,
    required this.name,
    required this.unlockLevel,
    required this.description,
    required this.icon,
  });
}

class ForestMapScreen extends StatefulWidget {
  const ForestMapScreen({super.key});

  @override
  State<ForestMapScreen> createState() => _ForestMapScreenState();
}

class _ForestMapScreenState extends State<ForestMapScreen> {
  final List<ForestAreaDef> _areaDefs = const [
    ForestAreaDef(
      id: 'area_1',
      name: 'Whispering Meadow',
      unlockLevel: 1,
      description: 'The heart of your sanctuary with cottages, waterfalls, and blooming flora.',
      icon: Icons.park_rounded,
    ),
    ForestAreaDef(
      id: 'area_2',
      name: 'Cherry Valley',
      unlockLevel: 2,
      description: 'Pink blossoms gently falling over mossy stone paths during spring study.',
      icon: Icons.spa_rounded,
    ),
    ForestAreaDef(
      id: 'area_3',
      name: 'Pine Ridge',
      unlockLevel: 3,
      description: 'Mountain ridge surrounded by tall, fragrant pine trees and fresh winds.',
      icon: Icons.nature_people_rounded,
    ),
    ForestAreaDef(
      id: 'area_4',
      name: 'Lotus Lake',
      unlockLevel: 5,
      description: 'Serene mountain waters reflecting floating lotus flowers and morning mist.',
      icon: Icons.waves_rounded,
    ),
    ForestAreaDef(
      id: 'area_5',
      name: 'Moonlight Path',
      unlockLevel: 8,
      description: 'Glowing stone lanterns illuminating night trails for late-evening study.',
      icon: Icons.dark_mode_rounded,
    ),
    ForestAreaDef(
      id: 'area_6',
      name: 'Zen Viewpoint',
      unlockLevel: 10,
      description: 'Mountain summit overlooking all sanctuaries with panoramic views.',
      icon: Icons.landscape_rounded,
    ),
  ];

  late String _selectedAreaId;

  @override
  void initState() {
    super.initState();
    _selectedAreaId = _areaDefs.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final forest = context.watch<ForestProvider>();
    final userLevel = forest.userLevel;

    final selectedArea = _areaDefs.firstWhere(
      (a) => a.id == _selectedAreaId,
      orElse: () => _areaDefs.first,
    );
    final isUnlocked = userLevel >= selectedArea.unlockLevel;
    final isCurrent = forest.selectedAreaId == selectedArea.id;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Text('Sanctuary Map', style: AppTypography.titleLarge),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left Area Selection Strip
                SizedBox(
                  width: 154,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: _areaDefs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final area = _areaDefs[index];
                      final unlocked = userLevel >= area.unlockLevel;
                      final isSelected = _selectedAreaId == area.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedAreaId = area.id);
                          if (unlocked) {
                            forest.selectArea(area.id);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.darkElevated : AppColors.sageTint)
                                : (isDark ? AppColors.darkSurface : AppColors.cardSurface),
                            borderRadius: AppRadius.roundedM,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.deepForest
                                  : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                unlocked
                                    ? (area.id == forest.selectedAreaId
                                        ? Icons.check_circle_rounded
                                        : area.icon)
                                    : Icons.lock_outline_rounded,
                                size: 16,
                                color: unlocked ? AppColors.deepForest : AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  area.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: unlocked
                                        ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                        : AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Right Area Visual Preview
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
                      borderRadius: AppRadius.roundedXL,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                      ),
                      boxShadow: AppShadows.softCard,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedArea.name,
                                style: AppTypography.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            NestBadge(
                              label: isUnlocked ? 'Unlocked' : 'Lv. ${selectedArea.unlockLevel}',
                              variant: isUnlocked
                                  ? NestBadgeVariant.safeGreen
                                  : NestBadgeVariant.neutral,
                              isDense: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(selectedArea.description, style: AppTypography.bodySmall),
                        const SizedBox(height: 14),
                        // Illustrated area thumbnail
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.warmCream,
                              borderRadius: AppRadius.roundedL,
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isUnlocked ? selectedArea.icon : Icons.lock_rounded,
                                    size: 48,
                                    color: isUnlocked ? AppColors.sageGreen : AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isUnlocked
                                        ? (isCurrent
                                            ? '${forest.totalTreesCount} Trees in this Grove'
                                            : 'Ready to Explore')
                                        : 'Unlocks at Level ${selectedArea.unlockLevel}',
                                    style: AppTypography.labelMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Current Area Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
              border: Border(
                top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.sageTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.park_rounded, color: AppColors.deepForest, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sanctuary: ${selectedArea.name}',
                        style: AppTypography.titleSmall,
                      ),
                      Text(
                        '${forest.totalTreesCount} trees planted across CBSE subjects',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Grove'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
