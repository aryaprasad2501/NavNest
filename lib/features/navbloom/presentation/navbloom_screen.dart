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
import 'widgets/forest_particles_overlay.dart';
import 'widgets/storybook_forest_painter.dart';

enum ForestTimelineFilter { today, week, month, allTime }

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
  ForestTimelineFilter _selectedFilter = ForestTimelineFilter.today;

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

  List<ForestTreeModel> _filterTrees(List<ForestTreeModel> allTrees) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case ForestTimelineFilter.today:
        final startOfToday = DateTime(now.year, now.month, now.day);
        return allTrees.where((t) => t.plantedAt.isAfter(startOfToday)).toList();
      case ForestTimelineFilter.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return allTrees.where((t) => t.plantedAt.isAfter(weekAgo)).toList();
      case ForestTimelineFilter.month:
        final monthAgo = now.subtract(const Duration(days: 30));
        return allTrees.where((t) => t.plantedAt.isAfter(monthAgo)).toList();
      case ForestTimelineFilter.allTime:
        return allTrees;
    }
  }

  void _showTreeInspectSheet(ForestTreeModel tree) {
    final effectiveDark = Theme.of(context).brightness == Brightness.dark ||
        context.read<ForestProvider>().isMoonlitNight;
    final cardBg = effectiveDark ? AppColors.darkSurface : AppColors.cardSurface;
    final textCol = effectiveDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedCol = effectiveDark ? AppColors.darkTextMuted : AppColors.textMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: AppShadows.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            // Glowing Tree Avatar
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tree.species.themeColor.withValues(alpha: 0.15),
                border: Border.all(color: tree.species.themeColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: tree.species.themeColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(tree.species.iconEmoji, style: const TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tree.species.displayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: tree.isMature
                    ? AppColors.safeGreen.withValues(alpha: 0.15)
                    : AppColors.amberWarm.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tree.isMature ? '🌟 Full Bloom (Stage 5)' : '🌱 Growing (Stage ${tree.stage})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tree.isMature ? AppColors.safeGreen : AppColors.amberHoney,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Study Info
            if (tree.subjectName.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveDark ? AppColors.darkCard : AppColors.warmCream.withValues(alpha: 0.6),
                  borderRadius: AppRadius.roundedM,
                  border: Border.all(color: effectiveDark ? AppColors.darkBorder : AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('${tree.focusMinutes}m', 'Focused', Icons.timer_outlined, textCol, mutedCol),
                    _buildStatCol(tree.subjectName, 'Subject', Icons.book_outlined, textCol, mutedCol),
                    _buildStatCol('+${tree.xpEarned} XP', 'Earned', Icons.stars_rounded, textCol, mutedCol),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openTreeDetails(tree);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedM),
                    ),
                    child: Text('Inspect Tree', style: TextStyle(color: textCol)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onStartTimer();
                    },
                    icon: const Icon(Icons.timer_rounded),
                    label: const Text('Study Again', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepForest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedM),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String val, String label, IconData icon, Color textCol, Color mutedCol) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.sageGreen),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol)),
        Text(label, style: TextStyle(fontSize: 10, color: mutedCol)),
      ],
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
            final cardBg = isDark ? AppColors.darkSurface : AppColors.cardSurface;
            final textCol = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
            final borderCol = isDark ? AppColors.darkBorder : AppColors.borderSubtle;

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
                color: cardBg,
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
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkElevated : AppColors.sageTint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.spa_rounded,
                            color: isDark ? AppColors.sageLight : AppColors.deepForest,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plant Seed in Sanctuary',
                              style: AppTypography.titleLarge.copyWith(color: textCol),
                            ),
                            Text(
                              'Linked to CBSE Class 10 study session',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. Select Species
                    Text(
                      'Select Tree Species',
                      style: AppTypography.titleSmall.copyWith(color: textCol),
                    ),
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
                                    ? species.themeColor.withValues(alpha: 0.18)
                                    : (isDark ? AppColors.darkCard : AppColors.warmCream),
                                borderRadius: AppRadius.roundedM,
                                border: Border.all(
                                  color: isSel ? species.themeColor : borderCol,
                                  width: isSel ? 2 : 1,
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
                                          ? species.themeColor
                                          : textCol,
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
                    Text('CBSE Subject', style: AppTypography.titleSmall.copyWith(color: textCol)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.ivoryCanvas,
                        borderRadius: AppRadius.roundedM,
                        border: Border.all(color: borderCol),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSubject,
                          isExpanded: true,
                          dropdownColor: cardBg,
                          items: subjects.map((s) {
                            return DropdownMenuItem(
                              value: s.name,
                              child: Text(s.name, style: TextStyle(color: textCol)),
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
                      Text('Chapter', style: AppTypography.titleSmall.copyWith(color: textCol)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.ivoryCanvas,
                          borderRadius: AppRadius.roundedM,
                          border: Border.all(color: borderCol),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: availableChapters.contains(selectedChapter)
                                ? selectedChapter
                                : availableChapters.first,
                            isExpanded: true,
                            dropdownColor: cardBg,
                            items: availableChapters.map((chap) {
                              return DropdownMenuItem(
                                value: chap,
                                child: Text(chap, style: TextStyle(color: textCol)),
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

                    // 4. Focus Duration
                    Text(
                      'Focus Session Duration: $focusMinutes min',
                      style: AppTypography.titleSmall.copyWith(color: textCol),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [25, 45, 60, 90].map((mins) {
                        final isSel = focusMinutes == mins;
                        return ChoiceChip(
                          label: Text('$mins m'),
                          selected: isSel,
                          selectedColor: AppColors.sageGreen,
                          backgroundColor: isDark ? AppColors.darkCard : AppColors.warmCream,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : textCol,
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
                              foregroundColor: Colors.white,
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

    final filteredTrees = _filterTrees(forest.trees);
    final filteredFocusMins = filteredTrees.fold<int>(0, (sum, t) => sum + t.focusMinutes);
    final focusHours = filteredFocusMins ~/ 60;
    final focusRemMins = filteredFocusMins % 60;
    final focusTimeStr = focusHours > 0 ? '${focusHours}h ${focusRemMins}m' : '${focusRemMins}m';

    final textPrimary = effectiveDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = effectiveDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final iconColor = effectiveDark ? AppColors.sageLight : AppColors.deepForest;

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

                    // Ambient Floating Cherry Petals / Bioluminescent Fireflies
                    Positioned.fill(
                      child: ForestParticlesOverlay(isMoonlit: effectiveDark),
                    ),

                    // Equipped Sanctuary Decorations Placed in Meadow
                    ...forest.equippedDecorations.map((dec) {
                      final left = (constraints.maxWidth * dec.xRatio - 18).clamp(8.0, constraints.maxWidth - 44);
                      final top = (constraints.maxHeight * dec.yRatio - 18).clamp(110.0, constraints.maxHeight - 160);

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
                    ...filteredTrees.map((tree) {
                      final left = (constraints.maxWidth * tree.xRatio - 32).clamp(12.0, constraints.maxWidth - 76);
                      final top = (constraints.maxHeight * tree.yRatio - 44).clamp(120.0, constraints.maxHeight - 180);

                      return Positioned(
                        left: left,
                        top: top,
                        child: GestureDetector(
                          onTap: () => _showTreeInspectSheet(tree),
                          child: _buildTreePin(tree, effectiveDark),
                        ),
                      );
                    }),

                    // Empty Sanctuary Prompt if no trees yet for this timeframe
                    if (filteredTrees.isEmpty)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          decoration: BoxDecoration(
                            color: (effectiveDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.92),
                            borderRadius: AppRadius.roundedL,
                            border: Border.all(
                              color: effectiveDark ? AppColors.darkBorder : AppColors.borderSubtle,
                            ),
                            boxShadow: AppShadows.softCard,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌱', style: TextStyle(fontSize: 34)),
                              const SizedBox(height: 6),
                              Text(
                                'Sanctuary is Blooming',
                                style: AppTypography.titleMedium.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "Plant & Focus" below to grow your first CBSE tree.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(color: textMuted),
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

          // 2. Top Header & Forest App Timeline Filter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Level, XP, Coins, Profile
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'NavBloom',
                              style: AppTypography.titleLarge.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              effectiveDark ? 'Moonlit Sanctuary' : 'Whispering Meadow',
                              style: AppTypography.bodySmall.copyWith(
                                color: textMuted,
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
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Forest App Signature Timeline Filter Bar: [Today] [Week] [Month] [Year]
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: (effectiveDark ? AppColors.darkCard : AppColors.cardSurface)
                            .withValues(alpha: 0.92),
                        borderRadius: AppRadius.roundedFull,
                        border: Border.all(
                          color: effectiveDark ? AppColors.darkBorder : AppColors.borderSubtle,
                        ),
                        boxShadow: AppShadows.softCard,
                      ),
                      child: Row(
                        children: [
                          _buildTimelineTab('Today', ForestTimelineFilter.today, effectiveDark),
                          _buildTimelineTab('Week', ForestTimelineFilter.week, effectiveDark),
                          _buildTimelineTab('Month', ForestTimelineFilter.month, effectiveDark),
                          _buildTimelineTab('All Time', ForestTimelineFilter.allTime, effectiveDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Filtered Stats Ribbon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: (effectiveDark ? AppColors.darkSurface : AppColors.sageTint)
                            .withValues(alpha: 0.85),
                        borderRadius: AppRadius.roundedFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.park_rounded, size: 13, color: AppColors.sageGreen),
                          const SizedBox(width: 4),
                          Text(
                            '${filteredTrees.length} Trees',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.timer_outlined, size: 13, color: AppColors.amberHoney),
                          const SizedBox(width: 4),
                          Text(
                            focusTimeStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
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
            top: 155,
            child: Column(
              children: [
                _buildQuickActionBtn(Icons.explore_rounded, 'Map', _openMap, effectiveDark),
                const SizedBox(height: 10),
                _buildQuickActionBtn(Icons.menu_book_rounded, 'Journal', _openJournal, effectiveDark),
                const SizedBox(height: 10),
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
                // Quick Plant & Focus Launch Bar
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
                          decoration: BoxDecoration(
                            color: effectiveDark ? AppColors.darkElevated : AppColors.sageTint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.park_rounded, color: iconColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Plant & Grow Forest Tree",
                                style: AppTypography.titleSmall.copyWith(
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${forest.totalFocusMinutes}m focused • ${forest.matureTreesCount}/${forest.totalTreesCount} mature trees',
                                style: AppTypography.bodySmall.copyWith(
                                  color: textMuted,
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
                        effectiveDark,
                      ),
                      _buildDockItem(Icons.park_rounded, 'Trees', _openMap, false, effectiveDark),
                      _buildDockItem(Icons.palette_rounded, 'Decorations', _openDecorations, false, effectiveDark),
                      _buildDockItem(
                        effectiveDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        effectiveDark ? 'Sunlight' : 'Moonlight',
                        () => forest.toggleMoonlitMode(),
                        false,
                        effectiveDark,
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

  Widget _buildTimelineTab(String label, ForestTimelineFilter filter, bool isDark) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.sageGreen : Colors.transparent,
            borderRadius: AppRadius.roundedFull,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
          ),
        ),
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
            Icon(icon, size: 20, color: isDark ? AppColors.sageLight : AppColors.deepForest),
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

  Widget _buildDockItem(IconData icon, String label, VoidCallback onTap, bool isPrimary, bool isDark) {
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
                color: isPrimary
                    ? AppColors.deepForest
                    : (isDark ? AppColors.darkElevated : AppColors.sageTint),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? AppColors.sageLight : AppColors.deepForest),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
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
