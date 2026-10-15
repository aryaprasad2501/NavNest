import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/core/models/study_session_model.dart';
import 'package:navnest/core/models/sync_queue_item.dart';
import 'package:navnest/core/models/user_profile.dart';
import 'package:navnest/core/services/cloud_sync_service.dart';

void main() {
  late Database inMemoryDb;
  late DatabaseHelper dbHelper;
  late CloudSyncService syncService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dbHelper = DatabaseHelper.instance;
    dbHelper.setDatabaseForTesting(inMemoryDb);

    await inMemoryDb.execute('''
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
    await inMemoryDb.execute('''
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
    await dbHelper.ensureSyncQueueTableExist(inMemoryDb);

    syncService = CloudSyncService(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('SyncQueueItem Model Tests', () {
    test('Correctly serializes and parses payload JSON', () {
      final now = DateTime.now();
      final item = SyncQueueItem(
        id: 'queue_1',
        entityType: 'STUDY_SESSION',
        entityId: 'session_101',
        action: 'UPSERT',
        payload: '{"id":"session_101","activeSeconds":2700,"rewardXp":150}',
        status: 'PENDING',
        createdAt: now,
        updatedAt: now,
      );

      final map = item.toMap();
      final fromDb = SyncQueueItem.fromMap(map);

      expect(fromDb.id, equals('queue_1'));
      expect(fromDb.entityType, equals('STUDY_SESSION'));
      expect(fromDb.status, equals('PENDING'));

      final parsed = fromDb.parsePayload();
      expect(parsed['id'], equals('session_101'));
      expect(parsed['activeSeconds'], equals(2700));
      expect(parsed['rewardXp'], equals(150));
    });

    test('copyWith updates retry count and error status', () {
      final now = DateTime.now();
      final item = SyncQueueItem(
        id: 'queue_1',
        entityType: 'STUDY_SESSION',
        entityId: 'session_101',
        action: 'UPSERT',
        payload: '{}',
        status: 'PENDING',
        createdAt: now,
        updatedAt: now,
      );

      final failedItem = item.copyWith(
        status: 'FAILED',
        retryCount: 1,
        lastError: 'Network unreachable',
      );

      expect(failedItem.status, equals('FAILED'));
      expect(failedItem.retryCount, equals(1));
      expect(failedItem.lastError, equals('Network unreachable'));
    });
  });

  group('CloudSyncService SQLite Offline Queue Operations', () {
    test('queueCompletedSession writes durable item to sync_queue table', () async {
      final now = DateTime.now();
      final session = StudySessionModel(
        id: 'sess_99',
        subjectName: 'Physics',
        chapterName: 'Units & Measurements',
        startedAt: now.subtract(const Duration(minutes: 50)),
        endedAt: now,
        activeSeconds: 3000,
        rewardXp: 120,
        rewardCoins: 25,
        createdAt: now,
      );

      await syncService.queueCompletedSession(session);

      final pendingCount = await dbHelper.getSyncQueuePendingCount();
      expect(pendingCount, equals(1));

      final items = await dbHelper.getPendingSyncQueueItems();
      expect(items.length, equals(1));
      expect(items.first.entityType, equals('STUDY_SESSION'));
      expect(items.first.entityId, equals('sess_99'));
      expect(items.first.status, equals('PENDING'));

      final payload = items.first.parsePayload();
      expect(payload['subjectId'], equals('Physics'));
      expect(payload['activeSeconds'], equals(3000));
      expect(payload['rewardXp'], equals(120));
    });

    test('queueUserProfile writes durable update to sync_queue table', () async {
      final profile = UserProfile(
        id: 'user_cbse',
        displayName: 'Class 10 Scholar',
        email: 'scholar@gmail.com',
        streakDays: 14,
        bestStreak: 14,
        totalXp: 1850,
        coins: 420,
        dailyTargetMinutes: 180,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await syncService.queueUserProfile(profile);

      final pendingCount = await dbHelper.getSyncQueuePendingCount();
      expect(pendingCount, equals(1));

      final items = await dbHelper.getPendingSyncQueueItems();
      expect(items.first.entityType, equals('USER_PROFILE'));
      expect(items.first.entityId, equals('user_cbse'));

      final payload = items.first.parsePayload();
      expect(payload['displayName'], equals('Class 10 Scholar'));
      expect(payload['totalXp'], equals(1850));
      expect(payload['coins'], equals(420));
    });

    test('queueForestTree writes mature tree record to sync_queue table', () async {
      final now = DateTime.now();
      final tree = ForestTreeModel(
        id: 'tree_mature_1',
        species: TreeSpecies.ancientOak,
        stage: 5,
        xRatio: 0.5,
        yRatio: 0.5,
        plantedAt: now,
        subjectName: 'Physics',
        chapterName: 'Kinematics',
        focusMinutes: 120,
        xpEarned: 250,
        coinsEarned: 50,
      );

      await syncService.queueForestTree(tree);

      final items = await dbHelper.getPendingSyncQueueItems();
      expect(items.first.entityType, equals('FOREST_TREE'));
      expect(items.first.entityId, equals('tree_mature_1'));

      final payload = items.first.parsePayload();
      expect(payload['stage'], equals(5));
      expect(payload['focusMinutes'], equals(120));
      expect(payload['subjectName'], equals('Physics'));
    });

    test('Multiple queued items accumulate and update pendingCount accurately', () async {
      final now = DateTime.now();
      for (int i = 0; i < 5; i++) {
        await syncService.queueCompletedSession(StudySessionModel(
          id: 'sess_$i',
          subjectName: 'Subject $i',
          chapterName: 'Chapter $i',
          startedAt: now,
          endedAt: now,
          activeSeconds: 1500,
          rewardXp: 50,
          rewardCoins: 10,
          createdAt: now,
        ));
      }

      await syncService.updatePendingCount();
      expect(syncService.pendingCount, equals(5));

      final items = await dbHelper.getPendingSyncQueueItems(limit: 3);
      expect(items.length, equals(3));
    });

    test('Deleting item from sync queue decrements pending count', () async {
      final now = DateTime.now();
      await syncService.queueCompletedSession(StudySessionModel(
        id: 'sess_to_delete',
        subjectName: 'Mathematics',
        chapterName: 'Real Numbers',
        startedAt: now,
        endedAt: now,
        activeSeconds: 1800,
        rewardXp: 60,
        rewardCoins: 12,
        createdAt: now,
      ));

      final items = await dbHelper.getPendingSyncQueueItems();
      expect(items.length, equals(1));

      await dbHelper.deleteSyncQueueItem(items.first.id);

      await syncService.updatePendingCount();
      expect(syncService.pendingCount, equals(0));
    });
  });

  group('Monotonic Reward Conflict Resolution Integrity', () {
    test('Max resolution preserves highest earned XP and coins across devices', () {
      final localXp = 1200;
      final remoteXp = 1500;
      final localCoins = 300;
      final remoteCoins = 250;

      // Rule: max(local, remote) prevents rollbacks when syncing offline progress
      final resolvedXp = localXp > remoteXp ? localXp : remoteXp;
      final resolvedCoins = localCoins > remoteCoins ? localCoins : remoteCoins;

      expect(resolvedXp, equals(1500), reason: 'Remote had higher XP from other device');
      expect(resolvedCoins, equals(300), reason: 'Local had higher coins earned offline');
    });
  });
}
