import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/forest_decoration_model.dart';
import '../../../core/models/forest_tree_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../syllabus/presentation/providers/syllabus_provider.dart';
import 'achievements_screen.dart';
import 'decorations_screen.dart';
import 'forest_journal_screen.dart';
import 'forest_map_screen.dart';
import 'providers/forest_provider.dart';
import 'tree_details_screen.dart';
import 'widgets/storybook_forest_painter.dart';

class NavBloomScreen extends StatefulWidget {
  final VoidCallback onStartTimer;

  const NavBloomScreen({
    super.key,
    required this.onStartTimer,
  });

  @override
  State<NavBloomScreen> createState() => _NavBloomScreenState();
}

class _NavBloomScreenState extends State<NavBloomScreen> {
  void _openTreeDetails(ForestTreeModel tree) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TreeDetailsScreen(tree: tree),
      ),
    );
  }

  void _openMap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForestMapScreen()),
    );
  }

  void _openJournal() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForestJournalScreen()),
    );
  }

  void _openAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AchievementsScreen()),
    );
  }

  void _openDecorations() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DecorationsScreen()),
    );
  }

  void _showPlantSeedDialog(BuildContext context) {
    final syllabusProvider = Provider.of<SyllabusProvider>(context, listen: false);
    final subjects = syllabusProvider.subjects;

    TreeSpecies selectedSpecies = TreeSpecies.cherryBlossom;
    String selectedSubject = subjects.isNotEmpty ? subjects.first.name : 'Mathematics';
    String selectedChapter = subjects.isNotEmpty && subjects.first.chapters.isNotEmpty
        ? subjects.first.chapters.first.name
        : 'Real Numbers';
    int focusMinutes = 45;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

            // Chapters for current subject
            final currSubObj = subjects.firstWhere(
              (s) => s.name == selectedSubject,
              orElse: () => subjects.isNotEmpty ? subjects.first : subjects.first,
            );
            final availableChapters = currSubObj.chapters.map((c) => c.name).toList();

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: AppShadows.elevated,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.sageTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.spa_rounded, color: AppColors.deepForest, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Plant Seed in NavBloom', style: AppTypography.titleLarge),
                            Text(
                              'Linked to CBSE Class 10 study session',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. Select Species
                    Text('Select Tree Species', style: AppTypography.titleSmall),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TreeSpecies.values.map((species) {
                          final isSel = selectedSpecies == species;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedSpecies = species),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? species.themeColor.withValues(alpha: 0.15)
                                    : (isDark ? AppColors.darkCard : AppColors.warmCream),
                                borderRadius: AppRadius.roundedM,
                                border: Border.all(
                                  color: isSel ? species.themeColor : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(species.iconEmoji, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(
                                    species.displayName,
                                    style: TextStyle(
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                      color: isSel
                                          ? (isDark ? Colors.white : AppColors.deepForest)
                                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Select Subject
                    Text('CBSE Subject', style: AppTypography.titleSmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.ivoryCanvas,
                        borderRadius: AppRadius.roundedM,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSubject,
                          isExpanded: true,
                          items: subjects.map((s) {
                            return DropdownMenuItem(
                              value: s.name,
                              child: Text(s.name, style: AppTypography.bodyMedium),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedSubject = val;
                                final newSub = subjects.firstWhere((s) => s.name == val);
                                selectedChapter = newSub.chapters.isNotEmpty
                                    ? newSub.chapters.first.name
                                    : 'General';
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Select Chapter
                    if (availableChapters.isNotEmpty) ...[
                      Text('Chapter', style: AppTypography.titleSmall),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.ivoryCanvas,
                          borderRadius: AppRadius.roundedM,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: availableChapters.contains(selectedChapter)
                                ? selectedChapter
                                : availableChapters.first,
                            isExpanded: true,
                            items: availableChapters.map((chap) {
                              return DropdownMenuItem(
                                value: chap,
                                child: Text(chap, style: AppTypography.bodyMedium),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedChapter = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 4. Planned Focus Minutes
                    Text('Focus Session Duration: $focusMinutes min', style: AppTypography.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [25, 45, 60, 90].map((mins) {
                        final isSel = focusMinutes == mins;
                        return ChoiceChip(
                          label: Text('$mins m'),
                          selected: isSel,
                          selectedColor: AppColors.deepForest,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => focusMinutes = mins);
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedL),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              final forest = context.read<ForestProvider>();
                              await forest.plantTree(
                                species: selectedSpecies,
                                subjectName: selectedSubject,
                                chapterName: selectedChapter,
                                focusMinutes: focusMinutes,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '🌱 Planted ${selectedSpecies.displayName} in your Sanctuary!',
                                    ),
                                    backgroundColor: AppColors.deepForest,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.park_rounded),
                            label: const Text('Plant Now'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.deepForest,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedL),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeIsDark = Theme.of(context).brightness == Brightness.dark;
    final forest = context.watch<ForestProvider>();
    final effectiveDark = forest.isMoonlitNight || themeIsDark;

    return Scaffold(
      backgroundColor: effectiveDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      body: Stack(
        children: [
          // 1. Layered Storybook Forest Canvas (Interactive World)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Storybook Custom Painted Vector Landscape
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: StorybookForestPainter(isDark: effectiveDark),
                    ),

                    // Equipped Sanctuary Decorations Placed in Meadow
                    ...forest.equippedDecorations.map((dec) {
                      final left = (constraints.maxWidth * dec.xRatio - 18).clamp(8.0, constraints.maxWidth - 44);
                      final top = (constraints.maxHeight * dec.yRatio - 18).clamp(80.0, constraints.maxHeight - 120);

                      return Positioned(
                        left: left,
                        top: top,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${dec.name}: ${dec.description}'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.deepForestDark,
                              ),
                            );
                          },
                          child: _buildDecorationMarker(dec, effectiveDark),
                        ),
                      );
                    }),

                    // Interactive Tree Pins Placed in Sanctuary
                    ...forest.trees.map((tree) {
                      final left = (constraints.maxWidth * tree.xRatio - 32).clamp(10.0, constraints.maxWidth - 74);
                      final top = (constraints.maxHeight * tree.yRatio - 44).clamp(90.0, constraints.maxHeight - 160);

                      return Positioned(
                        left: left,
                        top: top,
                        child: GestureDetector(
                          onTap: () => _openTreeDetails(tree),
                          child: _buildTreePin(tree, effectiveDark),
                        ),
                      );
                    }),

                    // Empty Sanctuary Prompt if no trees yet
                    if (forest.trees.isEmpty)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: (effectiveDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.9),
                            borderRadius: AppRadius.roundedL,
                            boxShadow: AppShadows.softCard,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌱', style: TextStyle(fontSize: 32)),
                              const SizedBox(height: 6),
                              Text('Your sanctuary is waiting!', style: AppTypography.titleMedium),
                              const SizedBox(height: 2),
                              Text(
                                "Tap 'Plant' below to start your CBSE focus tree.",
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // 2. Top Header Bar (Level, XP, Coins, Profile)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NavBloom',
                          style: AppTypography.titleLarge.copyWith(
                            color: effectiveDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          effectiveDark ? 'Moonlit Sanctuary' : 'Whispering Meadow',
                          style: AppTypography.bodySmall.copyWith(
                            color: effectiveDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildPill(
                      Icons.monetization_on_rounded,
                      '${forest.userCoins}',
                      AppColors.coinGold,
                      effectiveDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      Icons.stars_rounded,
                      '${forest.userXp}',
                      AppColors.amberWarm,
                      effectiveDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      Icons.shield_rounded,
                      'Lv. ${forest.userLevel}',
                      AppColors.sageGreen,
                      effectiveDark,
                    ),
                    const SizedBox(width: 10),
                    // Profile Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.sageTint,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: AppShadows.softCard,
                      ),
                      child: Center(
                        child: Text(
                          forest.userProfile?.displayName.isNotEmpty == true
                              ? forest.userProfile!.displayName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepForest,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Left Quick Action Pills: [Map], [Journal], [Tasks]
          Positioned(
            left: 16,
            top: 130,
            child: Column(
              children: [
                _buildQuickActionBtn(Icons.explore_rounded, 'Map', _openMap, effectiveDark),
                const SizedBox(height: 12),
                _buildQuickActionBtn(Icons.menu_book_rounded, 'Journal', _openJournal, effectiveDark),
                const SizedBox(height: 12),
                _buildQuickActionBtn(Icons.emoji_events_rounded, 'Tasks', _openAchievements, effectiveDark),
              ],
            ),
          ),

          // 4. Bottom Storybook Control Dock
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Today's Growth Bar
                GestureDetector(
                  onTap: () => _showPlantSeedDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: (effectiveDark ? AppColors.darkCard : AppColors.cardSurface)
                          .withValues(alpha: 0.95),
                      borderRadius: AppRadius.roundedL,
                      border: Border.all(
                        color: effectiveDark ? AppColors.darkBorder : AppColors.borderSubtle,
                      ),
                      boxShadow: AppShadows.softCard,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.sageTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.park_rounded, color: AppColors.deepForest, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Today's Sanctuary Growth",
                                style: AppTypography.titleSmall.copyWith(
                                  color: effectiveDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${forest.totalFocusMinutes}m focused • ${forest.matureTreesCount}/${forest.totalTreesCount} mature trees',
                                style: AppTypography.bodySmall.copyWith(
                                  color: effectiveDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.add_circle_outline_rounded, color: AppColors.sageGreen),
                      ],
                    ),
                  ),
                ),

                // Primary Bottom Dock: [Plant] [Trees] [Decorations] [Moonlight/Sunlight]
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (effectiveDark ? AppColors.darkSurface : AppColors.cardSurface)
                        .withValues(alpha: 0.95),
                    borderRadius: AppRadius.roundedXL,
                    border: Border.all(
                      color: effectiveDark ? AppColors.darkBorder : AppColors.sageBorder,
                      width: 1.2,
                    ),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDockItem(
                        Icons.spa_rounded,
                        'Plant',
                        () => _showPlantSeedDialog(context),
                        true,
                      ),
                      _buildDockItem(Icons.park_rounded, 'Trees', _openMap, false),
                      _buildDockItem(Icons.palette_rounded, 'Decorations', _openDecorations, false),
                      _buildDockItem(
                        effectiveDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        effectiveDark ? 'Sunlight' : 'Moonlight',
                        () => forest.toggleMoonlitMode(),
                        false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String text, Color iconColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.cardSurface).withValues(alpha: 0.9),
        borderRadius: AppRadius.roundedFull,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(IconData icon, String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 52,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : AppColors.cardSurface).withValues(alpha: 0.92),
          borderRadius: AppRadius.roundedM,
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
          boxShadow: AppShadows.softCard,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.deepForest),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem(IconData icon, String label, VoidCallback onTap, bool isPrimary) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPrimary ? AppColors.deepForest : AppColors.sageTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : AppColors.deepForest,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreePin(ForestTreeModel tree, bool isDark) {
    final color = tree.species.themeColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.92),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            tree.stage == 5
                ? Icons.park_rounded
                : tree.stage >= 3
                    ? Icons.nature_rounded
                    : Icons.spa_rounded,
            color: color,
            size: 32,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : AppColors.deepForestDark).withValues(alpha: 0.92),
            borderRadius: AppRadius.roundedS,
          ),
          child: Text(
            tree.species.displayName,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecorationMarker(ForestDecorationModel dec, bool isDark) {
    IconData icon = Icons.park_rounded;
    Color iconColor = AppColors.coinGold;

    if (dec.category == DecorationCategory.lighting) {
      icon = Icons.light_mode_rounded;
      iconColor = AppColors.coinGold;
    } else if (dec.category == DecorationCategory.flora) {
      icon = Icons.local_florist_rounded;
      iconColor = AppColors.cherryPink;
    } else if (dec.category == DecorationCategory.pathway) {
      icon = Icons.grain_rounded;
      iconColor = isDark ? Colors.white70 : Colors.brown.shade400;
    } else if (dec.category == DecorationCategory.furniture) {
      icon = Icons.chair_alt_rounded;
      iconColor = Colors.brown.shade600;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1B3D30) : Colors.white).withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: iconColor.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: iconColor),
    );
  }
}
