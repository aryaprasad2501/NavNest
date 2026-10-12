import '../../../core/models/planner_task_model.dart';

class AdaptiveRescheduleResult {
  final List<PlannerTaskModel> rescheduledTasks;
  final int daysSpan;
  final int totalMinutesRedistributed;

  const AdaptiveRescheduleResult({
    required this.rescheduledTasks,
    required this.daysSpan,
    required this.totalMinutesRedistributed,
  });
}

class AdaptiveRescheduler {
  static const int defaultMaxDailyMinutes = 240; // 4 hours maximum daily study load

  /// Deterministically redistributes missed/unfinished tasks into upcoming days.
  ///
  /// - [missedTasks]: Unfinished tasks from past days
  /// - [existingFutureTasks]: Tasks already scheduled on target dates to respect capacity limits
  /// - [startDate]: The date from which redistribution begins (typically today or tomorrow)
  /// - [maxDailyMinutes]: Cap for total study minutes per day to prevent student burnout
  static AdaptiveRescheduleResult reschedule({
    required List<PlannerTaskModel> missedTasks,
    required List<PlannerTaskModel> existingFutureTasks,
    required DateTime startDate,
    int maxDailyMinutes = defaultMaxDailyMinutes,
  }) {
    if (missedTasks.isEmpty) {
      return const AdaptiveRescheduleResult(
        rescheduledTasks: [],
        daysSpan: 0,
        totalMinutesRedistributed: 0,
      );
    }

    final rescheduled = <PlannerTaskModel>[];
    int totalMinutes = 0;

    // Track daily minute commitments for upcoming dates
    final dailyMinutesMap = <String, int>{};
    for (final task in existingFutureTasks) {
      dailyMinutesMap[task.date] = (dailyMinutesMap[task.date] ?? 0) + task.plannedMinutes;
    }

    DateTime currentSlotDate = DateTime(startDate.year, startDate.month, startDate.day);
    int daysOffset = 0;

    for (final task in missedTasks) {
      // Find the next date that has enough capacity for this task
      while (true) {
        final dateKey = _formatDate(currentSlotDate);
        final currentLoad = dailyMinutesMap[dateKey] ?? 0;

        // If current day has room for at least 45 minutes or this task doesn't exceed cap:
        if (currentLoad + task.plannedMinutes <= maxDailyMinutes || currentLoad == 0) {
          // Assign task to this day
          final updated = task.copyWith(
            date: dateKey,
            status: PlannerTaskStatus.upcoming,
            outcome: 'Rescheduled from ${task.date}',
          );
          rescheduled.add(updated);

          dailyMinutesMap[dateKey] = currentLoad + task.plannedMinutes;
          totalMinutes += task.plannedMinutes;
          break;
        } else {
          // Move to next day
          daysOffset++;
          currentSlotDate = currentSlotDate.add(const Duration(days: 1));
        }
      }
    }

    return AdaptiveRescheduleResult(
      rescheduledTasks: rescheduled,
      daysSpan: daysOffset + 1,
      totalMinutesRedistributed: totalMinutes,
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
