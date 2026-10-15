import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/chapter_model.dart';
import 'package:navnest/core/models/subject_model.dart';
import 'package:navnest/core/models/subtopic_model.dart';
import 'package:navnest/core/models/topic_status.dart';

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
  });

  tearDown(() async {
    await db.close();
    dbHelper.setDatabaseForTesting(null);
  });

  group('Syllabus Database Operations Tests', () {
    test('seedInitialSyllabus populates 6 default CBSE Class 10 subjects and chapters', () async {
      await dbHelper.seedInitialSyllabus(db);

      final subjects = await dbHelper.getSubjectsWithHierarchy();
      expect(subjects.length, equals(6));

      final maths = subjects.firstWhere((s) => s.id == 'sub_maths');
      expect(maths.name, equals('Mathematics'));
      expect(maths.chapters.length, greaterThanOrEqualTo(10));

      final science = subjects.firstWhere((s) => s.id == 'sub_science');
      expect(science.name, equals('Science'));
      expect(science.chapters.length, greaterThanOrEqualTo(10));

      // Test that subtopics are loaded inside chapters
      final firstChapter = maths.chapters.first;
      expect(firstChapter.subtopics.length, greaterThanOrEqualTo(3));
      expect(firstChapter.subtopics.first.name, equals('Fundamental Theorem of Arithmetic'));
      expect(firstChapter.subtopics.first.status, equals(TopicStatus.notStarted));
    });

    test('Subject CRUD and reordering operate correctly', () async {
      final now = DateTime.now();
      final newSubject = SubjectModel(
        id: 'sub_cs',
        name: 'Computer Science',
        colorHex: '#3D6B52',
        iconName: 'laptop',
        orderIndex: 0,
        createdAt: now,
      );

      // Insert
      await dbHelper.insertSubject(newSubject);
      var subjects = await dbHelper.getSubjectsWithHierarchy();
      expect(subjects.length, equals(1));
      expect(subjects.first.name, equals('Computer Science'));

      // Update
      final updatedSubject = SubjectModel(
        id: 'sub_cs',
        name: 'Informatics Practices',
        colorHex: '#E8833A',
        iconName: 'code',
        orderIndex: 0,
        createdAt: now,
      );
      await dbHelper.updateSubject(updatedSubject);
      subjects = await dbHelper.getSubjectsWithHierarchy();
      expect(subjects.first.name, equals('Informatics Practices'));
      expect(subjects.first.colorHex, equals('#E8833A'));

      // Insert second subject and reorder
      final subMath = SubjectModel(
        id: 'sub_math',
        name: 'Mathematics',
        colorHex: '#4A7C59',
        iconName: 'functions',
        orderIndex: 1,
        createdAt: now,
      );
      await dbHelper.insertSubject(subMath);
      await dbHelper.reorderSubjects(['sub_math', 'sub_cs']);

      subjects = await dbHelper.getSubjectsWithHierarchy();
      expect(subjects[0].id, equals('sub_math'));
      expect(subjects[1].id, equals('sub_cs'));

      // Delete
      await dbHelper.deleteSubject('sub_cs');
      subjects = await dbHelper.getSubjectsWithHierarchy();
      expect(subjects.length, equals(1));
      expect(subjects.first.id, equals('sub_math'));
    });

    test('Chapter and Subtopic CRUD operate with proper parent linkages', () async {
      final now = DateTime.now();
      await dbHelper.insertSubject(
        SubjectModel(
          id: 'sub_chem',
          name: 'Chemistry',
          colorHex: '#E06C54',
          iconName: 'science',
          createdAt: now,
        ),
      );

      final chapter = ChapterModel(
        id: 'ch_solutions',
        subjectId: 'sub_chem',
        name: 'Solutions',
        orderIndex: 0,
        createdAt: now,
        updatedAt: now,
      );
      await dbHelper.insertChapter(chapter);

      final subtopic1 = SubtopicModel(
        id: 'st_sol_1',
        chapterId: 'ch_solutions',
        name: 'Raoult\'s Law',
        status: TopicStatus.notStarted,
        estimatedMinutes: 40,
        createdAt: now,
        updatedAt: now,
      );
      await dbHelper.insertSubtopic(subtopic1);

      var subjects = await dbHelper.getSubjectsWithHierarchy();
      expect(subjects.first.chapters.length, equals(1));
      expect(subjects.first.chapters.first.subtopics.length, equals(1));
      expect(subjects.first.chapters.first.subtopics.first.name, equals('Raoult\'s Law'));

      // Subtopic status transitions
      // 1. Mark completed
      await dbHelper.updateSubtopicStatus('st_sol_1', TopicStatus.completed);
      var updatedList = await dbHelper.getSubjectsWithHierarchy();
      expect(updatedList.first.chapters.first.subtopics.first.status, equals(TopicStatus.completed));
      expect(updatedList.first.chapters.first.subtopics.first.completedAt, isNotNull);

      // 2. Mark needs revision (should increment revision count)
      await dbHelper.updateSubtopicStatus('st_sol_1', TopicStatus.needsRevision);
      final revisionQueue = await dbHelper.getRevisionQueue();
      expect(revisionQueue.length, equals(1));
      expect(revisionQueue.first.id, equals('st_sol_1'));
      expect(revisionQueue.first.revisionCount, equals(1));

      // 3. Update notes and duration
      await dbHelper.updateSubtopicNotes('st_sol_1', 'Formula: P_total = P_A + P_B');
      await dbHelper.updateSubtopicDuration('st_sol_1', 45);
      updatedList = await dbHelper.getSubjectsWithHierarchy();
      expect(updatedList.first.chapters.first.subtopics.first.notes, equals('Formula: P_total = P_A + P_B'));
      expect(updatedList.first.chapters.first.subtopics.first.estimatedMinutes, equals(45));

      // 4. Mark needs restudy and verify restudy queue
      await dbHelper.updateSubtopicStatus('st_sol_1', TopicStatus.needsRestudy);
      final restudyQueue = await dbHelper.getRestudyQueue();
      expect(restudyQueue.length, equals(1));
      expect(restudyQueue.first.id, equals('st_sol_1'));

      // 5. Search syllabus
      final searchResults = await dbHelper.searchSyllabus('Raoult');
      expect(searchResults.length, equals(1));
      expect(searchResults.first['subtopicName'], equals('Raoult\'s Law'));
      expect(searchResults.first['subjectName'], equals('Chemistry'));

      // 6. Chapter update and Subtopic update
      final updatedChapter = chapter.copyWith(name: 'Solutions & Colligative Properties');
      await dbHelper.updateChapter(updatedChapter);
      subjects = await dbHelper.getSubjectsWithHierarchy();
      expect(subjects.first.chapters.first.name, equals('Solutions & Colligative Properties'));

      final updatedSubtopic = subtopic1.copyWith(name: 'Raoult\'s Law for Volatile Solutes', estimatedMinutes: 50);
      await dbHelper.updateSubtopic(updatedSubtopic);
      subjects = await dbHelper.getSubjectsWithHierarchy();
      expect(subjects.first.chapters.first.subtopics.first.name, equals('Raoult\'s Law for Volatile Solutes'));
      expect(subjects.first.chapters.first.subtopics.first.estimatedMinutes, equals(50));
    });

    test('reloadClass10Syllabus cleanly resets and repopulates all 6 CBSE Class 10 subjects', () async {
      // First seed a custom subject
      final customSub = SubjectModel(
        id: 'sub_custom_robotics',
        name: 'Robotics',
        colorHex: '#333333',
        iconName: 'smart_toy',
        createdAt: DateTime.now(),
      );
      await dbHelper.insertSubject(customSub);
      var subs = await dbHelper.getSubjectsWithHierarchy();
      expect(subs.length, equals(1));

      // Reload official CBSE Class 10 syllabus
      await dbHelper.reloadClass10Syllabus();

      subs = await dbHelper.getSubjectsWithHierarchy();
      expect(subs.length, equals(6));
      expect(subs.map((s) => s.id).toList(), containsAll(['sub_maths', 'sub_science', 'sub_sst', 'sub_english', 'sub_hindi', 'sub_it402']));
    });
  });
}
