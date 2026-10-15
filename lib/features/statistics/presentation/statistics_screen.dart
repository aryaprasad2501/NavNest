import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../navbloom/presentation/providers/forest_provider.dart';
import '../../planner/presentation/providers/planner_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedFilterIndex = 1; // 0: Day, 1: Week, 2: Month, 3: All

  final List<String> _filters = ['Day', 'Week', 'Month', 'All'];

  @override
  Widget build(BuildContext context) {
    final colors = NavThemeColors.of(context);
    final themeIsDark = Theme.of(context).brightness == Brightness.dark;
    final forest = context.watch<ForestProvider>();
    final planner = context.watch<PlannerProvider>();
    final isDark = themeIsDark || forest.isMoonlitNight;

    // Computed or actual stats
    final totalMins = forest.totalFocusMinutes > 0 ? forest.totalFocusMinutes : 1100;
    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;
    final totalTrees = forest.totalTreesCount > 0 ? forest.totalTreesCount : 12;
    final completedTasks = planner.completedTasksCount > 0 ? planner.completedTasksCount : 28;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        title: Text(
          'Stats',
          style: AppTypography.titleLarge.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Pills [Day] [Week] [Month] [All]
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.roundedFull,
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : Colors.transparent,
                          borderRadius: AppRadius.roundedFull,
                          boxShadow: isSelected ? AppShadows.softCard : null,
                        ),
                        child: Center(
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : colors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Focus Time Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.roundedXL,
                border: Border.all(color: colors.borderSubtle),
                boxShadow: AppShadows.softCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Focus Time', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${hours}h ${mins}m',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.safeGreen.withValues(alpha: 0.15),
                          borderRadius: AppRadius.roundedFull,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.safeGreen),
                            SizedBox(width: 2),
                            Text(
                              '+12% this week',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.safeGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Weekly Bar Chart (Mon - Sun)
                  _buildWeeklyBarChart(colors, isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Badges (Trees Planted & Tasks Completed)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: AppRadius.roundedL,
                      border: Border.all(color: colors.borderSubtle),
                      boxShadow: AppShadows.softCard,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.park_rounded, color: colors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalTrees',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Trees Planted',
                              style: TextStyle(fontSize: 11, color: colors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: AppRadius.roundedL,
                      border: Border.all(color: colors.borderSubtle),
                      boxShadow: AppShadows.softCard,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.amberWarm.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppColors.amberWarm, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completedTasks',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Tasks Completed',
                              style: TextStyle(fontSize: 11, color: colors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subject Breakdown Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.roundedXL,
                border: Border.all(color: colors.borderSubtle),
                boxShadow: AppShadows.softCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject Breakdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSubjectBar('Mathematics', 0.40, colors.primary, colors.textPrimary, colors.textMuted),
                  const SizedBox(height: 12),
                  _buildSubjectBar('Physics', 0.25, AppColors.amberWarm, colors.textPrimary, colors.textMuted),
                  const SizedBox(height: 12),
                  _buildSubjectBar('Chemistry', 0.20, colors.secondary, colors.textPrimary, colors.textMuted),
                  const SizedBox(height: 12),
                  _buildSubjectBar('English', 0.15, AppColors.skyBlue, colors.textPrimary, colors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart(NavThemeColors colors, bool isDark) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final heights = [0.45, 0.70, 0.35, 0.90, 0.55, 0.80, 0.40]; // relative heights
    const activeDayIndex = 3; // Thu highlighted

    return SizedBox(
      height: 130,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(days.length, (i) {
          final isHighlighted = i == activeDayIndex;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 22,
                height: 80 * heights[i],
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? colors.primary
                      : (isDark ? colors.surfaceElevated : colors.primaryContainer),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isHighlighted ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ] : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  color: isHighlighted
                      ? colors.primary
                      : colors.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSubjectBar(String name, double ratio, Color color, Color textPrimary, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ],
            ),
            Text(
              '${(ratio * 100).toInt()}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
