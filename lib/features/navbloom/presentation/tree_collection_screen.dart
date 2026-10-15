import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/forest_tree_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'providers/forest_provider.dart';
import 'tree_details_screen.dart';

class TreeCollectionScreen extends StatefulWidget {
  final void Function({String? subject, String? chapter})? onStartTimer;
  const TreeCollectionScreen({super.key, this.onStartTimer});

  @override
  State<TreeCollectionScreen> createState() => _TreeCollectionScreenState();
}

class TreeDef {
  final TreeSpecies species;
  final String name;
  final int requiredLevel;
  final String description;
  final bool isDefaultUnlocked;

  const TreeDef({
    required this.species,
    required this.name,
    required this.requiredLevel,
    required this.description,
    this.isDefaultUnlocked = false,
  });
}

class _TreeCollectionScreenState extends State<TreeCollectionScreen> {
  int _selectedFilter = 0; // 0: All, 1: Unlocked, 2: Locked

  List<TreeDef> get _catalog => TreeSpecies.values.map((s) {
        return TreeDef(
          species: s,
          name: s.displayName,
          requiredLevel: s.unlockLevel,
          description: s.lore,
          isDefaultUnlocked: s.unlockLevel <= 1,
        );
      }).toList();

  @override
  Widget build(BuildContext context) {
    final themeIsDark = Theme.of(context).brightness == Brightness.dark;
    final forest = context.watch<ForestProvider>();
    final isDark = themeIsDark || forest.isMoonlitNight;
    final userLevel = forest.userLevel;

    final bgColor = isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas;
    final cardBg = isDark ? AppColors.darkCard : AppColors.cardSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.borderSubtle;

    final filters = ['All', 'Unlocked', 'Locked'];

    final filtered = _catalog.where((item) {
      final unlocked = item.isDefaultUnlocked || userLevel >= item.requiredLevel;
      if (_selectedFilter == 1) return unlocked;
      if (_selectedFilter == 2) return !unlocked;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Tree Collection',
          style: AppTypography.titleLarge.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.warmCream,
              borderRadius: AppRadius.roundedFull,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.sageGreen, size: 16),
                const SizedBox(width: 4),
                Text('Lv. $userLevel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs [All] [Unlocked] [Locked]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.warmCream,
                borderRadius: AppRadius.roundedFull,
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: List.generate(filters.length, (idx) {
                  final isSelected = _selectedFilter == idx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.deepForest : Colors.transparent,
                          borderRadius: AppRadius.roundedFull,
                        ),
                        child: Center(
                          child: Text(
                            filters[idx],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Grid of Trees
          Expanded(
            child: GridView.builder(
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
                final isUnlocked = item.isDefaultUnlocked || userLevel >= item.requiredLevel;

                return GestureDetector(
                  onTap: () {
                    if (isUnlocked) {
                      // Find if user already planted this tree or show preview
                      final existing = forest.trees.firstWhere(
                        (t) => t.species == item.species,
                        orElse: () => ForestTreeModel(
                          id: 'preview_${item.species.name}',
                          species: item.species,
                          stage: 5,
                          xRatio: 0.5,
                          yRatio: 0.5,
                          plantedAt: DateTime.now(),
                          subjectName: 'Class 10 CBSE',
                          chapterName: 'General Study',
                          focusMinutes: 120,
                          xpEarned: 300,
                          coinsEarned: 50,
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TreeDetailsScreen(
                            tree: existing,
                            treeName: item.name,
                            subject: 'Mathematics',
                            chapter: 'Real Numbers',
                            stage: 5,
                            onStartTimer: ({chapter, linkedTaskId, subject, subtopic}) {
                              widget.onStartTimer?.call(subject: subject, chapter: chapter);
                            },
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🔒 ${item.name} unlocks at Sanctuary Level ${item.requiredLevel}! Keep studying.'),
                          backgroundColor: AppColors.deepForestDark,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: AppRadius.roundedL,
                      border: Border.all(
                        color: isUnlocked
                            ? item.species.themeColor.withValues(alpha: 0.4)
                            : borderColor,
                        width: isUnlocked ? 1.4 : 1,
                      ),
                      boxShadow: isUnlocked ? AppShadows.softCard : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge: Level or Lock
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? AppColors.safeGreen.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: isUnlocked
                                ? Text(
                                    'Lv. ${item.requiredLevel}',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.safeGreen),
                                  )
                                : const Icon(Icons.lock_rounded, size: 10, color: Colors.grey),
                          ),
                        ),
                        const Spacer(),

                        // Tree Emoji / Silhouette
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? item.species.themeColor.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              isUnlocked ? item.species.iconEmoji : '🔒',
                              style: TextStyle(fontSize: isUnlocked ? 26 : 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tree Name
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? textPrimary : textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),

                        Text(
                          isUnlocked ? 'Unlocked' : 'Locked',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: isUnlocked ? AppColors.sageGreen : textMuted,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
