import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/core/models/user_profile.dart';

void main() {
  late Directory tempDir;
  late Database prodDb;
  late Database demoDb;
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.instance;

    // Set up clean, completely isolated temporary databases for production and demo
    tempDir = await Directory.systemTemp.createTemp('navnest_isolation_test_');
    prodDb = await databaseFactoryFfi.openDatabase('${tempDir.path}/prod.db');
    demoDb = await databaseFactoryFfi.openDatabase('${tempDir.path}/demo.db');

    // Create full schema on prodDb
    await _createFullSchema(prodDb);
    // Create full schema on demoDb
    await _createFullSchema(demoDb);

    dbHelper.setDatabaseForTesting(prodDb);
  });

  tearDown(() async {
    await prodDb.close();
    await demoDb.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    dbHelper.setDatabaseForTesting(null);
  });

  group('Demo Mode & Clean Install Isolation Tests', () {
    test('1. Fresh installation creates clean state with 0 trees and NOT_STARTED syllabus', () async {
      await dbHelper.seedInitialSyllabus(prodDb);
      await dbHelper.seedInitialForestData(prodDb);

      // Verify zero user trees
      final trees = await dbHelper.getForestTrees();
      expect(trees.isEmpty, isTrue, reason: 'Fresh install must never seed dummy trees');

      // Verify user profile is clean
      final defaultUser = UserProfile.defaultProfile();
      await dbHelper.saveUserProfile(defaultUser);
      final profile = await dbHelper.getUserProfile('default_student');
      expect(profile, isNotNull);
      expect(profile!.streakDays, equals(0));
      expect(profile.totalXp, equals(0));
      expect(profile.coins, equals(0));

      // Verify all seeded subtopics start in NOT_STARTED state
      final subtopics = await prodDb.query('subtopics');
      expect(subtopics.isNotEmpty, isTrue);
      for (final s in subtopics) {
        expect(s['status'], equals('NOT_STARTED'), reason: 'Fresh install subtopic must be NOT_STARTED');
        expect(s['completedAt'], isNull);
        expect(s['revisionCount'], equals(0));
      }
    });

    test('2. Demo dataset populates 30 trees across 5 growth stages and 5 species', () async {
      await dbHelper.seedInitialSyllabus(demoDb);
      await dbHelper.seedInitialForestData(demoDb);
      await dbHelper.seedDemoDataset(demoDb);

      // Switch helper to test demo database
      dbHelper.setDatabaseForTesting(demoDb);

      final demoTrees = await dbHelper.getForestTrees();
      expect(demoTrees.length, equals(30), reason: 'Demo mode must populate 30 sample trees');

      // Verify all 5 growth stages are represented
      final stages = demoTrees.map((t) => t.stage).toSet();
      expect(stages.contains(1), isTrue, reason: 'Stage 1 (Seedling) must be present');
      expect(stages.contains(2), isTrue, reason: 'Stage 2 (Sprout) must be present');
      expect(stages.contains(3), isTrue, reason: 'Stage 3 (Sapling) must be present');
      expect(stages.contains(4), isTrue, reason: 'Stage 4 (Bush/Flowering) must be present');
      expect(stages.contains(5), isTrue, reason: 'Stage 5 (Mature Bloom) must be present');

      // Verify 5 distinct species
      final species = demoTrees.map((t) => t.species).toSet();
      expect(species.length, greaterThanOrEqualTo(5));

      // Verify demo user profile
      final demoUser = await dbHelper.getUserProfile('demo_student_arya');
      expect(demoUser, isNotNull);
      expect(demoUser!.displayName, contains('Demo'));
      expect(demoUser.streakDays, equals(14));
      expect(demoUser.totalXp, equals(3450));
      expect(demoUser.coins, equals(820));

      // Verify demo shared space with partner
      final sharedSpace = await dbHelper.getActiveSharedSpace();
      expect(sharedSpace, isNotNull);
      expect(sharedSpace!.inviteCode, equals('NEST-WAR27'));
      expect(sharedSpace.memberProfiles, isNotNull);
      expect(sharedSpace.memberProfiles['partner_rohan'], isNotNull);
    });

    test('3. Demo records are completely isolated and never leak into production', () async {
      // 1. Production database: user plants 1 genuine tree
      dbHelper.setDatabaseForTesting(prodDb);
      await dbHelper.seedInitialForestData(prodDb);
      final realTree = ForestTreeModel(
        id: 'real_user_tree_1',
        species: TreeSpecies.mountainPine,
        stage: 2,
        xRatio: 0.5,
        yRatio: 0.5,
        subjectName: 'Mathematics',
        chapterName: 'Real Numbers',
        plantedAt: DateTime.now(),
        focusMinutes: 25,
        xpEarned: 100,
        coinsEarned: 25,
      );
      await dbHelper.insertForestTree(realTree);

      // Verify prodDb has only 1 real tree
      var prodTrees = await dbHelper.getForestTrees();
      expect(prodTrees.length, equals(1));
      expect(prodTrees.first.id, equals('real_user_tree_1'));

      // 2. Switch to Demo database and seed 30 trees
      dbHelper.setDatabaseForTesting(demoDb);
      await dbHelper.seedInitialForestData(demoDb);
      await dbHelper.seedDemoDataset(demoDb);
      var demoTrees = await dbHelper.getForestTrees();
      expect(demoTrees.length, equals(30));

      // 3. Switch back to Production database
      dbHelper.setDatabaseForTesting(prodDb);
      prodTrees = await dbHelper.getForestTrees();
      expect(prodTrees.length, equals(1), reason: 'Zero demo trees must leak into production');
      expect(prodTrees.first.id, equals('real_user_tree_1'));
    });

    test('4. Reset My Data cleanly wipes user data while preserving static catalogues', () async {
      dbHelper.setDatabaseForTesting(prodDb);
      await dbHelper.seedInitialSyllabus(prodDb);
      await dbHelper.seedInitialForestData(prodDb);

      // Add user tree and session
      await dbHelper.insertForestTree(ForestTreeModel(
        id: 'user_tree_1',
        species: TreeSpecies.ancientOak,
        stage: 5,
        xRatio: 0.5,
        yRatio: 0.5,
        subjectName: 'Science',
        chapterName: 'Chemical Reactions',
        plantedAt: DateTime.now(),
        focusMinutes: 45,
        xpEarned: 180,
        coinsEarned: 45,
      ));

      // Mark a subtopic completed
      await prodDb.update('subtopics', {'status': 'COMPLETED'}, where: "id = 'subtopic_ch_math_1_0'");

      // Verify user data exists before reset
      expect((await dbHelper.getForestTrees()).length, equals(1));
      final completedBefore = await prodDb.query('subtopics', where: "status = 'COMPLETED'");
      expect(completedBefore.length, equals(1));

      // Perform Reset My Data
      await dbHelper.resetProductionUserData();

      // Verify user trees are wiped
      expect((await dbHelper.getForestTrees()).isEmpty, isTrue);

      // Verify subtopics are reset to NOT_STARTED
      final completedAfter = await prodDb.query('subtopics', where: "status = 'COMPLETED'");
      expect(completedAfter.isEmpty, isTrue);

      // Verify static catalogues remain intact
      final subjects = await prodDb.query('subjects');
      expect(subjects.length, equals(6), reason: 'All 6 CBSE subjects must remain');
      final decorations = await dbHelper.getDecorations();
      expect(decorations.isNotEmpty, isTrue, reason: 'Static decorations catalogue must remain');
    });
  });
}

Future<void> _createFullSchema(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS user_profiles (
      id TEXT PRIMARY KEY,
      displayName TEXT NOT NULL,
      email TEXT,
      photoUrl TEXT,
      streakDays INTEGER NOT NULL DEFAULT 0,
      bestStreak INTEGER NOT NULL DEFAULT 0,
      lastStudyDate TEXT,
      totalXp INTEGER NOT NULL DEFAULT 0,
      coins INTEGER NOT NULL DEFAULT 0,
      dailyTargetMinutes INTEGER NOT NULL DEFAULT 120,
      activeSharedSpaceId TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS shared_spaces (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      inviteCode TEXT NOT NULL,
      createdByUserId TEXT NOT NULL,
      memberIds TEXT NOT NULL,
      memberProfiles TEXT,
      totalForestTrees INTEGER NOT NULL DEFAULT 0,
      combinedFocusMinutes INTEGER NOT NULL DEFAULT 0,
      sharedExamName TEXT,
      sharedExamDate TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS subjects (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      colorHex TEXT NOT NULL,
      iconName TEXT NOT NULL,
      orderIndex INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS chapters (
      id TEXT PRIMARY KEY,
      subjectId TEXT NOT NULL,
      name TEXT NOT NULL,
      orderIndex INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS subtopics (
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

  await db.execute('''
    CREATE TABLE IF NOT EXISTS exams (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      examDate TEXT NOT NULL,
      targetScore INTEGER,
      colorHex TEXT,
      createdAt TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS planner_tasks (
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
    CREATE TABLE IF NOT EXISTS study_sessions (
      id TEXT PRIMARY KEY,
      startedAt TEXT NOT NULL,
      endedAt TEXT NOT NULL,
      activeSeconds INTEGER NOT NULL DEFAULT 0,
      pausedSeconds INTEGER NOT NULL DEFAULT 0,
      subjectId TEXT,
      chapterId TEXT,
      subtopicId TEXT,
      status TEXT NOT NULL DEFAULT 'COMPLETED',
      rewardXp INTEGER NOT NULL DEFAULT 0,
      rewardCoins INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS forest_trees (
      id TEXT PRIMARY KEY,
      sessionId TEXT,
      treeType TEXT NOT NULL DEFAULT 'Mountain Pine',
      stage INTEGER NOT NULL DEFAULT 1,
      gridX INTEGER NOT NULL DEFAULT 0,
      gridY INTEGER NOT NULL DEFAULT 0,
      xRatio REAL NOT NULL DEFAULT 0.5,
      yRatio REAL NOT NULL DEFAULT 0.5,
      plantedAt TEXT NOT NULL,
      maturedAt TEXT,
      subjectName TEXT,
      chapterName TEXT,
      focusMinutes INTEGER NOT NULL DEFAULT 25,
      xpEarned INTEGER NOT NULL DEFAULT 100,
      coinsEarned INTEGER NOT NULL DEFAULT 25,
      status TEXT NOT NULL DEFAULT 'HEALTHY',
      isShared INTEGER NOT NULL DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS forest_decorations (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      category TEXT NOT NULL,
      costCoins INTEGER NOT NULL,
      isUnlocked INTEGER NOT NULL DEFAULT 0,
      isEquipped INTEGER NOT NULL DEFAULT 0,
      xRatio REAL NOT NULL DEFAULT 0.5,
      yRatio REAL NOT NULL DEFAULT 0.5,
      iconName TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS forest_journal (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      date TEXT NOT NULL,
      subjectName TEXT,
      focusMinutes INTEGER NOT NULL DEFAULT 0,
      xpEarned INTEGER NOT NULL DEFAULT 0,
      coinsEarned INTEGER NOT NULL DEFAULT 0,
      notes TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS achievements (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      iconName TEXT NOT NULL,
      progress INTEGER NOT NULL DEFAULT 0,
      target INTEGER NOT NULL DEFAULT 1,
      isUnlocked INTEGER NOT NULL DEFAULT 0,
      unlockedAt TEXT,
      xpReward INTEGER NOT NULL DEFAULT 100,
      coinsReward INTEGER NOT NULL DEFAULT 50
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS reward_transactions (
      transactionId TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      xpAmount INTEGER NOT NULL DEFAULT 0,
      coinsAmount INTEGER NOT NULL DEFAULT 0,
      reason TEXT NOT NULL,
      createdAt TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY,
      entityType TEXT NOT NULL,
      entityId TEXT NOT NULL,
      action TEXT NOT NULL,
      payload TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'PENDING',
      retryCount INTEGER NOT NULL DEFAULT 0,
      lastError TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');
}
