import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_card.dart';
import '../../../core/widgets/nest_progress_bar.dart';
import '../../navbloom/presentation/providers/forest_provider.dart';
import '../../planner/presentation/providers/planner_provider.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenFocus;
  final VoidCallback onOpenPlanner;
  final VoidCallback onOpenSyllabus;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.onOpenFocus,
    required this.onOpenPlanner,
    required this.onOpenSyllabus,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final forest = context.watch<ForestProvider>();
    final planner = context.watch<PlannerProvider>();
    AuthService? auth;
    try {
      auth = context.watch<AuthService>();
    } catch (_) {}

    final user = auth?.currentUser ?? forest.userProfile;
    final displayName = (user?.displayName.isNotEmpty == true && user!.displayName != 'Student')
        ? user.displayName
        : 'Aditi 🌸';
    final photoUrl = user?.photoUrl;
    final isGoogleLinked = auth?.isGoogleLinked ?? false;
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Good Morning',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                    if (isGoogleLinked) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.safeGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.cloud_done_rounded, size: 10, color: AppColors.safeGreen),
                            SizedBox(width: 3),
                            Text(
                              'Synced',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.safeGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  displayName,
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: onOpenSettings,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.sageTint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isGoogleLinked ? AppColors.safeGreen : Colors.white,
                  width: 1.5,
                ),
                boxShadow: AppShadows.softCard,
                image: photoUrl != null
                    ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: photoUrl == null
                  ? Center(
                      child: Text(
                        avatarLetter,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepForest),
                      ),
                    )
                  : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.deepForest),
            tooltip: 'Settings',
            onPressed: onOpenSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motivational Quote Card
            _buildMotivationalQuoteCard(isDark),

            const SizedBox(height: AppSpacing.m),

            // Top Stats Bar
            _buildStatsRow(isDark, forest),

            const SizedBox(height: AppSpacing.l),

            // Today's Progress Card
            _buildTodayProgressCard(isDark, forest),

            const SizedBox(height: AppSpacing.l),

            // Upcoming Exams
            _buildUpcomingExamsCard(isDark, planner),

            const SizedBox(height: AppSpacing.l),

            // NavBloom Forest Preview Shortcut
            _buildNavBloomPreviewCard(isDark, forest),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalQuoteCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.sageTint.withValues(alpha: 0.6),
        borderRadius: AppRadius.roundedL,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.sageBorder.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '"Small steps today create big forests tomorrow."',
              style: AppTypography.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.deepForestDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, ForestProvider forest) {
    return Row(
      children: [
        Expanded(child: _buildStatItem('${forest.userStreak}', 'Day Streak', Icons.local_fire_department_rounded, AppColors.amberHoney, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatItem('${forest.userXp}', 'XP', Icons.stars_rounded, AppColors.amberWarm, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatItem('${forest.userCoins}', 'Coins', Icons.monetization_on_rounded, AppColors.coinGold, isDark)),
      ],
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        borderRadius: AppRadius.roundedM,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                val,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgressCard(bool isDark, ForestProvider forest) {
    final focusMins = forest.totalFocusMinutes;
    final targetMins = forest.userProfile?.dailyTargetMinutes ?? 120;
    final progress = (focusMins / targetMins).clamp(0.0, 1.0);
    final hours = focusMins ~/ 60;
    final mins = focusMins % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    final targetHours = targetMins ~/ 60;

    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Progress", style: AppTypography.titleMedium),
              NestBadge(
                label: progress >= 0.5 ? 'On Track' : 'Focus Today',
                variant: progress >= 0.5 ? NestBadgeVariant.safeGreen : NestBadgeVariant.amber,
                isDense: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular Meter
              NestCircularProgress(
                progress: progress > 0 ? progress : 0.05,
                size: 96,
                strokeWidth: 8,
                progressColor: AppColors.sageGreen,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.warmCream,
                centerWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'of ${targetHours}h',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              // Storybook Cottage & Forest Vignette Card
              Expanded(
                child: Container(
                  height: 96,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.warmCream,
                    borderRadius: AppRadius.roundedL,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.sageTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cottage_rounded, color: AppColors.deepForest, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${forest.totalTreesCount} Trees Planted',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${forest.matureTreesCount} reached Full Bloom',
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExamsCard(bool isDark, PlannerProvider planner) {
    final exams = planner.exams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Exams', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: _buildExamPill(
                exams.isNotEmpty ? exams.first.title : 'Physics',
                exams.isNotEmpty ? '${exams.first.daysRemaining} days left' : '20 days left',
                AppColors.subjectPhysics,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExamPill(
                exams.length > 1 ? exams[1].title : 'Chemistry',
                exams.length > 1 ? '${exams[1].daysRemaining} days left' : '52 days left',
                AppColors.subjectChemistry,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExamPill(String title, String days, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        borderRadius: AppRadius.roundedL,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  days,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBloomPreviewCard(bool isDark, ForestProvider forest) {
    return GestureDetector(
      onTap: onOpenFocus,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.elevatedSurface,
          borderRadius: AppRadius.roundedXL,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.sageBorder,
            width: 1.2,
          ),
          boxShadow: AppShadows.softCard,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.sageTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.park_rounded, color: AppColors.deepForest, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NavBloom Sanctuary', style: AppTypography.titleSmall),
                  const SizedBox(height: 2),
                  Text('${forest.totalTreesCount} Trees in Sanctuary • ${forest.matureTreesCount} Matured', style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.deepForest),
          ],
        ),
      ),
    );
  }
}
