import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/models/planner_task_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_progress_bar.dart';
import '../../focus/presentation/providers/focus_session_provider.dart';
import '../../navbloom/presentation/providers/forest_provider.dart';
import '../../planner/presentation/providers/planner_provider.dart';
import '../../planner/presentation/widgets/exam_editor_sheet.dart';
import '../../planner/presentation/widgets/task_editor_sheet.dart';
import '../../distraction_control/presentation/app_blocker_screen.dart';
import '../../statistics/presentation/statistics_screen.dart';
import '../../syllabus/presentation/providers/syllabus_provider.dart';

typedef StartFocusWithDetails = void Function({
  String? subject,
  String? chapter,
  String? subtopic,
  String? linkedTaskId,
});

class HomeScreen extends StatelessWidget {
  final StartFocusWithDetails onOpenFocus;
  final VoidCallback onOpenPlanner;
  final VoidCallback onOpenSyllabus;
  final VoidCallback onOpenSettings;
  final VoidCallback? onOpenNavBloom;
  final VoidCallback? onOpenShared;

  const HomeScreen({
    super.key,
    required this.onOpenFocus,
    required this.onOpenPlanner,
    required this.onOpenSyllabus,
    required this.onOpenSettings,
    this.onOpenNavBloom,
    this.onOpenShared,
  });

  void _openExamEditor(BuildContext context, [ExamModel? examToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExamEditorSheet(initialExamToEdit: examToEdit),
    );
  }

  void _openTaskEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskEditorSheet(defaultDate: DateTime.now()),
    );
  }

  String _getGreetingText(bool isDark) {
    final hour = DateTime.now().hour;
    if (isDark) {
      return 'Moonlit Sanctuary 🌙';
    } else if (hour < 12) {
      return 'Morning Dew ☀️';
    } else if (hour < 17) {
      return 'Sunlit Focus 🌿';
    } else {
      return 'Evening Calm 🌅';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NavThemeColors.of(context);
    final isDark = colors.isDark;
    final forest = context.watch<ForestProvider>();
    final planner = context.watch<PlannerProvider>();
    final focusSession = context.watch<FocusSessionProvider>();
    final syllabus = context.watch<SyllabusProvider>();

    AuthService? auth;
    try {
      auth = context.watch<AuthService>();
    } catch (_) {}

    final user = auth?.currentUser ?? forest.userProfile;
    final displayName = (user?.displayName.isNotEmpty == true && user!.displayName != 'Student')
        ? user.displayName
        : 'Student 🌿';
    final photoUrl = user?.photoUrl;
    final isGoogleLinked = auth?.isGoogleLinked ?? false;
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    final textPrimary = colors.textPrimary;
    final iconColor = colors.primary;

    // Today's task list & pending tasks
    final todayTasks = planner.tasks;
    final pendingTasks = todayTasks.where((t) => !t.isCompleted).toList();
    final nextTask = pendingTasks.isNotEmpty ? pendingTasks.first : null;

    return Scaffold(
      backgroundColor: colors.canvas,
      endDrawer: _buildSideMenuDrawer(context, isDark, user, forest, auth),
      appBar: AppBar(
        backgroundColor: colors.canvas,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getGreetingText(isDark),
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isGoogleLinked) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.successLight.withValues(alpha: isDark ? 0.25 : 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.success.withValues(alpha: isDark ? 0.4 : 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done_rounded, size: 10, color: colors.success),
                        const SizedBox(width: 3),
                        Text(
                          'Cloud Synced',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              displayName,
              style: AppTypography.titleLarge.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          // Profile Avatar / Side Menu Drawer Button
          Builder(
            builder: (scaffoldContext) => GestureDetector(
              onTap: () => Scaffold.of(scaffoldContext).openEndDrawer(),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isGoogleLinked ? colors.success : colors.border,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.25) : AppColors.deepForest.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: photoUrl != null
                      ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: photoUrl == null
                    ? Center(
                        child: Text(
                          avatarLetter,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Builder(
            builder: (scaffoldContext) => IconButton(
              icon: Icon(Icons.tune_rounded, color: iconColor, size: 22),
              tooltip: 'Menu & Settings',
              onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Quick Stats Header Pills (Streak, XP, Coins)
            _buildQuickStatsHeader(colors, forest),

            const SizedBox(height: 16),

            // 2. Active Session Banner OR Hero "What to do next" Card
            if (focusSession.hasActiveSession)
              _buildActiveFocusBanner(context, colors, focusSession)
            else
              _buildNextActionHeroCard(context, colors, nextTask),

            const SizedBox(height: 20),

            // 3. Today's Study Progress Card (Hours, Target, Trees)
            _buildTodayStudyProgressSection(colors, forest, todayTasks),

            const SizedBox(height: 22),

            // 4. Dedicated NavBloom Cinematic Portal Card
            _buildNavBloomPortalGateway(context, colors, forest),

            const SizedBox(height: 24),

            // 5. Today's Tasks Timeline with Checkbox & Focus Trigger
            _buildTodayTasksTimeline(context, colors, planner, todayTasks),

            const SizedBox(height: 24),

            // 6. Syllabus Mastery Quick View
            _buildSyllabusQuickView(context, colors, syllabus),

            const SizedBox(height: 24),

            // 7. Upcoming Target Exams
            _buildUpcomingExamsSection(context, colors, planner),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // --- 1. Quick Stats Header Pills ---
  Widget _buildQuickStatsHeader(NavThemeColors colors, ForestProvider forest) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildMetricPill(
            icon: Icons.local_fire_department_rounded,
            iconColor: colors.accent,
            prefix: '${forest.userStreak}',
            label: 'Day Streak',
            colors: colors,
          ),
          const SizedBox(width: 8),
          _buildMetricPill(
            icon: Icons.stars_rounded,
            iconColor: colors.isDark ? colors.primary : colors.accent,
            label: 'Level ${forest.userLevel} • ${forest.userXp} XP',
            colors: colors,
          ),
          const SizedBox(width: 8),
          _buildMetricPill(
            icon: Icons.monetization_on_rounded,
            iconColor: colors.accent,
            label: '${forest.userCoins} Coins',
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required Color iconColor,
    String? prefix,
    required String label,
    required NavThemeColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark ? Colors.black.withValues(alpha: 0.25) : AppColors.deepForest.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          if (prefix != null) ...[
            Text(
              prefix,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2A. Active Session Banner ---
  Widget _buildActiveFocusBanner(BuildContext context, NavThemeColors colors, FocusSessionProvider focusSession) {
    final remainingSec = focusSession.remainingSeconds;
    final m = (remainingSec ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSec % 60).toString().padLeft(2, '0');
    final timeStr = '$m:$s';
    final subject = focusSession.subjectName.isNotEmpty ? focusSession.subjectName : 'Focus Session';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: colors.isDark ? AppGradients.forestAura : AppGradients.radiantEmerald,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestEmerald.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amberAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      focusSession.isPaused ? 'SESSION PAUSED' : 'FOCUS IN PROGRESS',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$timeStr remaining',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => onOpenFocus(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.deepForest,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Resume', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // --- 2B. Next Action Hero Card ---
  Widget _buildNextActionHeroCard(BuildContext context, NavThemeColors colors, PlannerTaskModel? nextTask) {
    final isDark = colors.isDark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? colors.primary.withValues(alpha: 0.35) : colors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : AppColors.deepForest.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle ambient glow
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? colors.primary : colors.accent).withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: isDark ? 0.8 : 0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? colors.primary.withValues(alpha: 0.3) : colors.border,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_filled_rounded,
                            size: 14,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            nextTask != null ? 'UP NEXT' : (isDark ? 'MOONLIT FOCUS' : 'READY TO BLOOM'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      nextTask != null ? '${nextTask.plannedMinutes} min target' : '25 min Pomodoro',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nextTask != null ? nextTask.title : (isDark ? 'Quiet Night Study' : 'Deep Study Session'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextTask != null
                      ? 'Scheduled for today • ${nextTask.subjectName}'
                      : (isDark
                          ? 'Shield all distractions and grow a tranquil tree under the stars.'
                          : 'Lock in distractions and grow a healthy tree in your forest.'),
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (nextTask != null) {
                        onOpenFocus(
                          subject: nextTask.subjectName,
                          linkedTaskId: nextTask.id,
                        );
                      } else {
                        onOpenFocus();
                      }
                    },
                    icon: Icon(isDark ? Icons.bedtime_rounded : Icons.eco_rounded, size: 20),
                    label: Text(
                      nextTask != null ? 'Start Task Focus 🌿' : (isDark ? 'Begin Moonlit Focus 🌙' : 'Start Focus Session 🌿'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? colors.canvas : Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? colors.primary : colors.primary,
                      foregroundColor: isDark ? colors.canvas : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Today's Study Progress Section ---
  Widget _buildTodayStudyProgressSection(
    NavThemeColors colors,
    ForestProvider forest,
    List<PlannerTaskModel> todayTasks,
  ) {
    final isDark = colors.isDark;
    final targetMinutes = forest.userProfile?.dailyTargetMinutes ?? 120;
    final todayMinutes = forest.trees
        .where((t) => t.plantedAt.day == DateTime.now().day && t.plantedAt.month == DateTime.now().month)
        .fold(0, (sum, t) => sum + t.focusMinutes);
    final progress = (todayMinutes / targetMinutes).clamp(0.0, 1.0);
    final completedTasks = todayTasks.where((t) => t.isCompleted).length;
    final matureTreesToday = forest.trees
        .where((t) => t.isMature && t.plantedAt.day == DateTime.now().day && t.plantedAt.month == DateTime.now().month)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : AppColors.deepForest.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Progress",
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% of goal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: progress >= 1.0 ? colors.success : colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          NestProgressBar(
            progress: progress,
            height: 9,
            progressColor: colors.primary,
            backgroundColor: isDark ? colors.surfaceVariant : colors.primaryContainer,
          ),
          const SizedBox(height: 18),
          // 3 Metric Badges
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.hourglass_top_rounded,
                  iconColor: colors.primary,
                  value: '${todayMinutes}m',
                  label: 'of ${targetMinutes}m target',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.park_rounded,
                  iconColor: isDark ? colors.primary : colors.secondary,
                  value: '$matureTreesToday',
                  label: 'Trees Blooming',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.task_alt_rounded,
                  iconColor: colors.accent,
                  value: '$completedTasks/${todayTasks.length}',
                  label: 'Tasks Done',
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required NavThemeColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.isDark ? colors.surfaceVariant : colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 4. NavBloom Cinematic Portal Gateway ---
  Widget _buildNavBloomPortalGateway(BuildContext context, NavThemeColors colors, ForestProvider forest) {
    final isDark = colors.isDark;
    return GestureDetector(
      onTap: onOpenNavBloom ?? () => onOpenFocus(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.magicalPortal : AppGradients.forestAura,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? colors.primary.withValues(alpha: 0.45) : colors.primaryLight.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.deepForest).withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Floating Ethereal Particle Orbs
            Positioned(
              left: 20,
              top: 15,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.sageLight.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.sageLight, blurRadius: 8, spreadRadius: 2),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: 25,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.amberAccent, blurRadius: 10, spreadRadius: 3),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  // Illuminated Gateway Circle
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF2ECC71), Color(0xFF133E27)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.park_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'NavBloom Sanctuary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Grove World',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${forest.totalTreesCount} trees planted • ${forest.matureTreesCount} in full bloom',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            Text(
                              'Enter Sanctuary',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4ADE80),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF4ADE80)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. Today's Tasks Timeline ---
  Widget _buildTodayTasksTimeline(
    BuildContext context,
    NavThemeColors colors,
    PlannerProvider planner,
    List<PlannerTaskModel> tasks,
  ) {
    final isDark = colors.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "Today's Plan",
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openTaskEditor(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('+ Add Task', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton(
                  onPressed: onOpenPlanner,
                  child: Text(
                    'Planner →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 36,
                  color: colors.textLight,
                ),
                const SizedBox(height: 8),
                Text(
                  'No Tasks Planned Yet Today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a revision topic or homework task to stay on track',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openTaskEditor(context),
                  icon: const Icon(Icons.add_task_rounded, size: 16),
                  label: const Text('Create Study Task', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          )
        else
          Column(
            children: tasks.take(4).map((task) {
              final isCompleted = task.isCompleted;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCompleted
                        ? colors.borderSubtle
                        : (isDark ? colors.primary.withValues(alpha: 0.3) : colors.border),
                  ),
                ),
                child: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () => planner.toggleTaskComplete(task),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? colors.success
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? colors.success : colors.textMuted,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted
                                  ? colors.textMuted
                                  : colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                task.subjectName ?? 'General Study',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${task.plannedMinutes} min',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isCompleted)
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_fill_rounded,
                          color: colors.primary,
                          size: 28,
                        ),
                        tooltip: 'Start Focus',
                        onPressed: () => onOpenFocus(
                          subject: task.subjectName,
                          linkedTaskId: task.id,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // --- 6. Syllabus Quick View ---
  Widget _buildSyllabusQuickView(BuildContext context, NavThemeColors colors, SyllabusProvider syllabus) {
    final isDark = colors.isDark;
    final subjects = syllabus.subjects;
    if (subjects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CBSE 10 Syllabus',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: onOpenSyllabus,
              child: Text(
                'View All →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final sub = subjects[index];
              final progress = sub.progress;
              final subjectColor = sub.color;

              return GestureDetector(
                onTap: onOpenSyllabus,
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.2) : AppColors.deepForest.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: subjectColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.menu_book_rounded, color: subjectColor, size: 16),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: subjectColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        sub.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      NestProgressBar(
                        progress: progress,
                        height: 4,
                        progressColor: subjectColor,
                        backgroundColor: isDark ? colors.surfaceVariant : colors.primaryContainer,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 7. Upcoming Exams Section ---
  Widget _buildUpcomingExamsSection(BuildContext context, NavThemeColors colors, PlannerProvider planner) {
    final isDark = colors.isDark;
    final exams = planner.exams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Exams',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _openExamEditor(context),
              icon: Icon(
                Icons.add_rounded,
                size: 16,
                color: colors.primary,
              ),
              label: Text(
                'Manage',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (exams.isEmpty)
          GestureDetector(
            onTap: () => _openExamEditor(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_note_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Target Exams Added Yet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Tap here to add CBSE Boards, Pre-Boards, or Unit Tests',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textMuted),
                ],
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: exams.map((exam) {
                Color examColor = colors.secondary;
                if (exam.colorHex != null) {
                  try {
                    examColor = Color(int.parse(exam.colorHex!.replaceAll('#', '0xFF')));
                  } catch (_) {}
                }

                return GestureDetector(
                  onTap: () => _openExamEditor(context, exam),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: examColor.withValues(alpha: 0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.2) : AppColors.deepForest.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: examColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                exam.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.edit_outlined, size: 14, color: colors.textMuted),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${exam.daysRemaining} days left',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: examColor,
                              ),
                            ),
                            if (exam.targetScore != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: examColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Target ${exam.targetScore}%',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: examColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSideMenuDrawer(
    BuildContext context,
    bool isDark,
    dynamic user,
    ForestProvider forest,
    AuthService? auth,
  ) {
    final colors = NavThemeColors.of(context);
    final bgColor = colors.surface;
    final textPrimary = colors.textPrimary;
    final textMuted = colors.textMuted;
    final borderColor = colors.border;
    final name = (user?.displayName.isNotEmpty == true && user!.displayName != 'Student')
        ? user.displayName
        : 'Arya 🌿';

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primaryContainer,
                      border: Border.all(color: colors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: colors.isDark ? Colors.black.withValues(alpha: 0.25) : AppColors.deepForest.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Focus • Grow • Achieve',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Level Progress Bar (Level 3 • 320/500 XP)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: AppRadius.roundedM,
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Level ${forest.userLevel}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary)),
                        Text('${forest.userXp}/500 XP', style: TextStyle(fontSize: 11, color: textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (forest.userXp % 500) / 500.0,
                        backgroundColor: AppColors.sageGreen.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amberWarm),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),

            // Menu Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.menu_book_rounded,
                    title: 'Syllabus',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenSyllabus();
                    },
                    textPrimary: textPrimary,
                  ),
                  _buildDrawerItem(
                    icon: Icons.edit_calendar_rounded,
                    title: 'Exams',
                    onTap: () {
                      Navigator.pop(context);
                      _openExamEditor(context);
                    },
                    textPrimary: textPrimary,
                  ),
                  _buildDrawerItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Statistics',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()));
                    },
                    textPrimary: textPrimary,
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite_rounded,
                    title: 'Shared Space',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenShared?.call();
                    },
                    textPrimary: textPrimary,
                  ),
                  _buildDrawerItem(
                    icon: Icons.shield_rounded,
                    title: 'App Blocker',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AppBlockerScreen()));
                    },
                    textPrimary: textPrimary,
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenSettings();
                    },
                    textPrimary: textPrimary,
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.urgentRed, size: 18),
                label: const Text('Logout', style: TextStyle(color: AppColors.urgentRed, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.urgentRed.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedM),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await auth?.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out safely.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color textPrimary,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.sageGreen, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedM),
    );
  }
}
