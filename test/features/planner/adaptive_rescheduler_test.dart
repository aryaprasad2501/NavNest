import 'package:flutter_test/flutter_test.dart';
import 'package:navnest/core/models/planner_task_model.dart';
import 'package:navnest/features/planner/domain/adaptive_rescheduler.dart';

void main() {
  group('AdaptiveRescheduler Unit Tests', () {
    final now = DateTime(2026, 10, 12);

    test('Empty missed tasks list returns zero redistributed tasks', () {
      final result = AdaptiveRescheduler.reschedule(
        missedTasks: [],
        existingFutureTasks: [],
        startDate: now,
      );

      expect(result.rescheduledTasks, isEmpty);
      expect(result.daysSpan, equals(0));
      expect(result.totalMinutesRedistributed, equals(0));
    });

    test('Reschedules missed past tasks starting from target start date', () {
      final missed = [
        PlannerTaskModel(
          id: 'missed_1',
          date: '2026-10-10',
          title: 'Physics Optics',
          plannedMinutes: 60,
          status: PlannerTaskStatus.missed,
          createdAt: now,
        ),
        PlannerTaskModel(
          id: 'missed_2',
          date: '2026-10-11',
          title: 'Chemistry Electrochemistry',
          plannedMinutes: 90,
          status: PlannerTaskStatus.missed,
          createdAt: now,
        ),
      ];

      final result = AdaptiveRescheduler.reschedule(
        missedTasks: missed,
        existingFutureTasks: [],
        startDate: now,
        maxDailyMinutes: 240,
      );

      expect(result.rescheduledTasks.length, equals(2));
      expect(result.totalMinutesRedistributed, equals(150));
      // Both tasks fit within 240 mins on the first day
      expect(result.rescheduledTasks[0].date, equals('2026-10-12'));
      expect(result.rescheduledTasks[1].date, equals('2026-10-12'));
      expect(result.rescheduledTasks[0].status, equals(PlannerTaskStatus.upcoming));
      expect(result.rescheduledTasks[0].outcome, contains('Rescheduled from 2026-10-10'));
    });

    test('Rolls over tasks into subsequent days when daily cap is exceeded', () {
      // Day cap = 120 mins
      // Existing load on 2026-10-12 = 90 mins (only 30 mins room left)
      final existing = [
        PlannerTaskModel(
          id: 'exist_1',
          date: '2026-10-12',
          title: 'Existing Math',
          plannedMinutes: 90,
          createdAt: now,
        ),
      ];

      final missed = [
        // Task 1: 60 mins -> exceeds 120 (90 + 60 = 150 > 120) -> should move to next day 2026-10-13
        PlannerTaskModel(
          id: 'missed_1',
          date: '2026-10-09',
          title: 'Physics Mechanics',
          plannedMinutes: 60,
          status: PlannerTaskStatus.missed,
          createdAt: now,
        ),
        // Task 2: 90 mins -> 2026-10-13 already has 60 mins -> 60 + 90 = 150 > 120 -> should roll over to 2026-10-14
        PlannerTaskModel(
          id: 'missed_2',
          date: '2026-10-10',
          title: 'Chemistry Thermodynamics',
          plannedMinutes: 90,
          status: PlannerTaskStatus.missed,
          createdAt: now,
        ),
      ];

      final result = AdaptiveRescheduler.reschedule(
        missedTasks: missed,
        existingFutureTasks: existing,
        startDate: now,
        maxDailyMinutes: 120,
      );

      expect(result.rescheduledTasks.length, equals(2));
      expect(result.rescheduledTasks[0].date, equals('2026-10-13'));
      expect(result.rescheduledTasks[1].date, equals('2026-10-14'));
      expect(result.daysSpan, equals(3));
      expect(result.totalMinutesRedistributed, equals(150));
    });
  });
}
