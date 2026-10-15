import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/planner_task_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_button.dart';
import '../../../core/widgets/nest_card.dart';
import '../../../core/widgets/nest_progress_bar.dart';
import 'providers/planner_provider.dart';
import 'widgets/exam_editor_sheet.dart';
import 'widgets/task_editor_sheet.dart';

typedef StartFocusCallback = void Function({
  String? subject,
  String? chapter,
  String? subtopic,
  String? linkedTaskId,
});

class PlannerScreen extends StatefulWidget {
  final StartFocusCallback? onStartFocus;

  const PlannerScreen({
    super.key,
    this.onStartFocus,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _monthNames = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final _dayNames = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final planner = Provider.of<PlannerProvider>(context, listen: false);
      planner.loadInitialData();
    });
  }

  void _openTaskEditor(BuildContext context, {PlannerTaskModel? task, required DateTime date}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskEditorSheet(
        existingTask: task,
        defaultDate: date,
      ),
    );
  }

  void _openExamEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExamEditorSheet(),
    );
  }

  Future<void> _pickArbitraryDate(BuildContext context, PlannerProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      provider.setSelectedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NavThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<PlannerProvider>(context);

    final selectedDate = provider.selectedDate;
    final weekDays = provider.currentWeekDays;

    final startDay = weekDays.first;
    final endDay = weekDays.last;
    final weekRangeTitle = '${_monthNames[startDay.month - 1]} ${startDay.day} – ${_monthNames[endDay.month - 1]} ${endDay.day}';

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        iconTheme: IconThemeData(color: colors.primary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily & Weekly Planner', style: AppTypography.titleLarge.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w800)),
            Text(
              weekRangeTitle,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          if (!provider.isSelectedDateToday)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: ActionChip(
                backgroundColor: colors.surfaceCard,
                side: BorderSide(color: colors.borderSubtle),
                avatar: Icon(Icons.today_rounded, size: 16, color: colors.primary),
                label: Text('Today', style: TextStyle(fontSize: 12, color: colors.textPrimary)),
                onPressed: provider.goToToday,
              ),
            ),
          IconButton(
            icon: Icon(Icons.calendar_month_rounded, color: colors.primary),
            tooltip: 'Jump to Any Date',
            onPressed: () => _pickArbitraryDate(context, provider),
          ),
          IconButton(
            icon: Icon(Icons.alarm_rounded, color: colors.primary),
            tooltip: 'Target Exams',
            onPressed: () => _openExamEditor(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // 1. Dynamic Week Strip with Forward/Backward Pagination
          _buildDynamicWeekStrip(provider, weekDays, colors, isDark),

          const SizedBox(height: AppSpacing.m),

          // 2. Day Context & Metric Summary Card
          _buildDayMetricsCard(provider, colors, isDark),

          // 3. Adaptive Rescheduling Banner (if missed past tasks exist)
          if (provider.missedPastTasks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            _buildAdaptiveRescheduleBanner(context, provider, isDark),
          ],

          const SizedBox(height: AppSpacing.l),

          // 4. Section Header: Tasks for the Selected Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks (${provider.tasks.length})',
                style: AppTypography.titleMedium.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
              ),
              NestButton(
                label: '+ Add Task',
                variant: NestButtonVariant.secondary,
                onPressed: () => _openTaskEditor(context, date: selectedDate),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.m),

          // 5. Tasks List
          if (provider.tasks.isEmpty)
            _buildEmptyDayState(provider, colors, isDark)
          else
            ...provider.tasks.map((task) => _buildTaskCard(context, task, provider, colors, isDark)),

          const SizedBox(height: 80), // Fab spacing
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Plan Session', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openTaskEditor(context, date: selectedDate),
      ),
    );
  }

  Widget _buildDynamicWeekStrip(PlannerProvider provider, List<DateTime> weekDays, NavThemeColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.roundedL,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          // Week Switcher Navigation Arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: colors.primary),
                tooltip: 'Previous Week',
                onPressed: provider.previousWeek,
              ),
              Text(
                '${_monthNames[provider.selectedDate.month - 1]} ${provider.selectedDate.year}',
                style: AppTypography.titleSmall.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: colors.primary),
                tooltip: 'Next Week',
                onPressed: provider.nextWeek,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 7 Days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) {
              final isSelected = d.year == provider.selectedDate.year &&
                  d.month == provider.selectedDate.month &&
                  d.day == provider.selectedDate.day;

              final now = DateTime.now();
              final isToday = d.year == now.year && d.month == now.month && d.day == now.day;

              final weekdayLabel = _dayNames[d.weekday - 1];

              return GestureDetector(
                onTap: () => provider.setSelectedDate(d),
                child: Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary
                        : Colors.transparent,
                    borderRadius: AppRadius.roundedM,
                  ),
                  child: Column(
                    children: [
                      Text(
                        weekdayLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : colors.textPrimary,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white : colors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayMetricsCard(PlannerProvider provider, NavThemeColors colors, bool isDark) {
    String contextBadge;
    NestBadgeVariant badgeVariant;

    if (provider.isSelectedDatePast) {
      contextBadge = 'Past Day Review';
      badgeVariant = NestBadgeVariant.sage;
    } else if (provider.isSelectedDateFuture) {
      contextBadge = 'Future Schedule';
      badgeVariant = NestBadgeVariant.neutral;
    } else {
      contextBadge = 'Today';
      badgeVariant = NestBadgeVariant.safeGreen;
    }

    final plannedHours = (provider.plannedMinutesToday / 60).toStringAsFixed(1);
    final actualHours = (provider.actualMinutesToday / 60).toStringAsFixed(1);

    return NestCard(
      color: colors.surfaceCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${_monthNames[provider.selectedDate.month - 1]} ${provider.selectedDate.day}, ${provider.selectedDate.year}',
                    style: AppTypography.titleMedium.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  NestBadge(label: contextBadge, variant: badgeVariant, isDense: true),
                ],
              ),
              Text(
                '${provider.completedTasksToday}/${provider.totalTasksToday} Done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NestProgressBar(
            progress: provider.completionProgressToday,
            height: 8,
            progressColor: colors.primary,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Planned: ${plannedHours}h (${provider.plannedMinutesToday}m)',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textMuted,
                ),
              ),
              Text(
                'Actual: ${actualHours}h completed',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: provider.actualMinutesToday > 0 ? AppColors.safeGreen : colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveRescheduleBanner(BuildContext context, PlannerProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberHoney.withValues(alpha: isDark ? 0.2 : 0.15),
        borderRadius: AppRadius.roundedM,
        border: Border.all(color: AppColors.amberHoney.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_fix_high_rounded, color: AppColors.amberHoney, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.missedPastTasks.length} Incomplete Past Tasks',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.amberHoney),
                ),
                const SizedBox(height: 2),
                Text(
                  'Adaptively rebalance onto future study days without overloading daily limits.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amberHoney,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              final result = await provider.runAdaptiveReschedule();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Rescheduled ${result.rescheduledTasks.length} tasks across ${result.daysSpan} upcoming days!',
                    ),
                    backgroundColor: AppColors.deepForest,
                  ),
                );
              }
            },
            child: const Text('Reschedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState(PlannerProvider provider, NavThemeColors colors, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available_rounded, size: 48, color: colors.borderSubtle),
            const SizedBox(height: 12),
            Text(
              'No study tasks planned for this day.',
              style: AppTypography.titleSmall.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              provider.isSelectedDateFuture
                  ? 'Tap "+ Add Task" to schedule ahead for board exams.'
                  : 'Add a new study session or review past work.',
              style: AppTypography.bodySmall.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    PlannerTaskModel task,
    PlannerProvider provider,
    NavThemeColors colors,
    bool isDark,
  ) {
    final color = task.subjectColorHex != null
        ? Color(int.parse('FF${task.subjectColorHex!.replaceAll('#', '')}', radix: 16))
        : colors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NestCard(
        color: colors.surfaceCard,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox Circle
            GestureDetector(
              onTap: () => provider.toggleTaskComplete(task),
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted ? colors.primary : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted
                        ? colors.primary
                        : colors.borderSubtle,
                    width: 2,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Vertical Subject Color Stripe
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.roundedFull,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: GestureDetector(
                onTap: () => _openTaskEditor(context, task: task, date: provider.selectedDate),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted
                            ? colors.textMuted
                            : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          task.displayTimeRange,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        if (task.outcome != null) ...[
                          const SizedBox(width: 8),
                          NestBadge(label: task.outcome!, variant: NestBadgeVariant.neutral, isDense: true),
                        ],
                      ],
                    ),
                    if (task.notes != null && task.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.notes!,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: colors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions: Quick Focus Timer trigger or Edit
            if (!task.isCompleted && !provider.isSelectedDatePast)
              IconButton(
                icon: Icon(Icons.play_circle_fill_rounded, color: colors.primary, size: 28),
                tooltip: 'Start Focus Timer',
                onPressed: () {
                  widget.onStartFocus?.call(
                    subject: task.subjectName,
                    chapter: task.chapterId ?? task.title,
                    subtopic: task.title,
                    linkedTaskId: task.id,
                  );
                },
              )
            else
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: colors.textMuted),
                tooltip: 'Edit Task',
                onPressed: () => _openTaskEditor(context, task: task, date: provider.selectedDate),
              ),
          ],
        ),
      ),
    );
  }
}
