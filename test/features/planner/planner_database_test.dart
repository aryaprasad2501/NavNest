import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/exam_model.dart';
import 'package:navnest/core/models/planner_task_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DatabaseHelper dbHelper;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dbHelper = DatabaseHelper.instance;
    dbHelper.setDatabaseForTesting(db);

    // Initialize tables
    await db.execute('''
      CREATE TABLE subjects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        iconName TEXT NOT NULL,
        orderIndex INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exams (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        examDate TEXT NOT NULL,
        targetScore INTEGER,
        colorHex TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE planner_tasks (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        subjectId TEXT,
        chapterId TEXT,
        subtopicId TEXT,
        title TEXT NOT NULL,
        startTime TEXT,
        endTime TEXT,
        plannedMinutes INTEGER NOT NULL DEFAULT 45,
        actualMinutes INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'UPCOMING',
        outcome TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id TEXT PRIMARY KEY,
        subjectId TEXT NOT NULL,
        name TEXT NOT NULL,
        orderIndex INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subtopics (
        id TEXT PRIMARY KEY,
        chapterId TEXT NOT NULL,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'NOT_STARTED',
        estimatedMinutes INTEGER NOT NULL DEFAULT 30,
        notes TEXT,
        orderIndex INTEGER NOT NULL DEFAULT 0,
        completedAt TEXT,
        revisionCount INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Seed all 5 standard subjects & chapters
    await dbHelper.seedInitialSyllabus(db);
  });

  tearDown(() async {
    await db.close();
    dbHelper.setDatabaseForTesting(null);
  });

  group('Planner & Exam Database Tests', () {
    test('seedInitialPlannerData populates past, today, and future tasks & exams', () async {
      await dbHelper.seedInitialPlannerData(db);

      final now = DateTime.now();
      final todayKey = DatabaseHelper.formatDbDate(now);

      // Verify today's tasks exist and have joined subject details
      final todayTasks = await dbHelper.getTasksForDate(todayKey);
      expect(todayTasks.length, greaterThanOrEqualTo(2));
      final scienceTask = todayTasks.firstWhere((t) => t.id == 'pt_today_1');
      expect(scienceTask.subjectName, equals('Science'));
      expect(scienceTask.subjectColorHex, equals('#3B8A6E'));

      // Verify past missed tasks exist
      final missed = await dbHelper.getMissedTasksBefore(todayKey);
      expect(missed.length, greaterThanOrEqualTo(1));
      expect(missed.first.status, equals(PlannerTaskStatus.missed));

      // Verify exams seeded
      final exams = await dbHelper.getExams();
      expect(exams.length, equals(4));
      expect(exams.first.title, contains('Board'));
      expect(exams.first.daysRemaining, greaterThan(0));
    });

    test('Future Task CRUD operations function correctly across arbitrary dates', () async {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 7));
      final futureDateKey = DatabaseHelper.formatDbDate(futureDate);

      final futureTask = PlannerTaskModel(
        id: 'future_task_1',
        date: futureDateKey,
        subjectId: 'sub_science',
        title: 'Light: Reflection and Refraction Ray Diagrams',
        startTime: '10:00 AM',
        endTime: '11:30 AM',
        plannedMinutes: 90,
        notes: 'Derive mirror formula and magnification.',
        createdAt: now,
      );

      // 1. Insert Future Task
      await dbHelper.insertPlannerTask(futureTask);

      var tasksOnDate = await dbHelper.getTasksForDate(futureDateKey);
      expect(tasksOnDate.length, equals(1));
      expect(tasksOnDate.first.title, equals('Light: Reflection and Refraction Ray Diagrams'));
      expect(tasksOnDate.first.displayTimeRange, equals('10:00 AM - 11:30 AM'));
      expect(tasksOnDate.first.plannedMinutes, equals(90));
      expect(tasksOnDate.first.subjectName, equals('Science'));

      // 2. Update Future Task
      final updatedTask = futureTask.copyWith(
        title: 'Light: Lens Formula & Power Calculations',
        plannedMinutes: 100,
        notes: 'Practice numerical problems on concave lens.',
      );
      await dbHelper.updatePlannerTask(updatedTask);

      tasksOnDate = await dbHelper.getTasksForDate(futureDateKey);
      expect(tasksOnDate.first.title, equals('Light: Lens Formula & Power Calculations'));
      expect(tasksOnDate.first.plannedMinutes, equals(100));

      // 3. Mark Task as Completed
      final completedTask = updatedTask.copyWith(
        status: PlannerTaskStatus.completed,
        actualMinutes: 100,
      );
      await dbHelper.updatePlannerTask(completedTask);

      tasksOnDate = await dbHelper.getTasksForDate(futureDateKey);
      expect(tasksOnDate.first.isCompleted, isTrue);
      expect(tasksOnDate.first.actualMinutes, equals(100));

      // 4. Delete Task
      await dbHelper.deletePlannerTask('future_task_1');
      tasksOnDate = await dbHelper.getTasksForDate(futureDateKey);
      expect(tasksOnDate, isEmpty);
    });

    test('Exam CRUD operations function with countdown calculation', () async {
      final now = DateTime.now();
      final targetExam = ExamModel(
        id: 'exam_preboard_1',
        title: 'Pre-Board 1: Mathematics',
        examDate: now.add(const Duration(days: 15)),
        targetScore: 98,
        colorHex: '#4A7C59',
        createdAt: now,
      );

      await dbHelper.insertExam(targetExam);

      var exams = await dbHelper.getExams();
      expect(exams.length, equals(1));
      expect(exams.first.title, equals('Pre-Board 1: Mathematics'));
      expect(exams.first.targetScore, equals(98));
      expect(exams.first.daysRemaining, equals(15));

      await dbHelper.deleteExam('exam_preboard_1');
      exams = await dbHelper.getExams();
      expect(exams, isEmpty);
    });
  });
}
