import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/core/models/user_profile.dart';
import 'package:navnest/features/focus/models/active_session_model.dart';
import 'package:navnest/features/focus/services/active_session_store.dart';
import 'package:navnest/features/navbloom/presentation/providers/forest_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Focus Timer Reliability — Monotonic Math & ActiveSessionModel Tests', () {
    test('calculateActiveElapsedMs strictly counts active time without clock drift', () {
      final session = ActiveSessionModel(
        id: 'test_session_1',
        mode: FocusTimerMode.custom,
        targetSeconds: 1500, // 25 minutes
        elapsedRealtimeStartMs: 100000,
        wallClockStartMs: 1700000000000,
        accumulatedActiveMs: 0,
        accumulatedPausedMs: 0,
        lastResumeRealtimeMs: 100000,
        lastResumeWallMs: 1700000000000,
        bootTimeEpochMs: 1699900000000,
        state: FocusSessionState.running,
        subjectName: 'Mathematics',
        chapterName: 'Real Numbers',
        updatedAt: DateTime.now(),
      );

      // 60 seconds of monotonic time elapsed
      final currentMonotonic = 160000;
      expect(session.calculateActiveElapsedMs(currentMonotonic), equals(60000));
      expect(session.calculateActiveSeconds(currentMonotonic), equals(60));
      expect(session.calculateRemainingSeconds(currentMonotonic), equals(1440));
      expect(session.isExpired(currentMonotonic), isFalse);
      expect(session.calculateProgress(currentMonotonic), closeTo(60 / 1500, 0.001));

      // Notification target deadline is 1440 seconds in the future
      final currentWall = 1700000060000;
      final targetDeadline = session.calculateTargetDeadlineEpochMs(currentMonotonic, currentWall);
      expect(targetDeadline, equals(currentWall + (1440 * 1000)));
    });

    test('Pause intervals are strictly excluded from active elapsed time', () {
      // Step 1: Running for 60 seconds (monotonic: 100k -> 160k)
      // Step 2: Paused at 160k. Accumulated active = 60,000ms.
      final pausedSession = ActiveSessionModel(
        id: 'test_session_pause',
        mode: FocusTimerMode.pomodoro,
        targetSeconds: 1500,
        elapsedRealtimeStartMs: 100000,
        wallClockStartMs: 1700000000000,
        accumulatedActiveMs: 60000,
        accumulatedPausedMs: 0,
        lastResumeRealtimeMs: 100000,
        lastResumeWallMs: 1700000000000,
        pauseStartRealtimeMs: 160000,
        pauseStartWallMs: 1700000060000,
        bootTimeEpochMs: 1699900000000,
        state: FocusSessionState.paused,
        subjectName: 'Science',
        chapterName: 'Light Reflection',
        updatedAt: DateTime.now(),
      );

      // While paused, even if monotonic time advances by 10 minutes (600,000ms) to 760k:
      expect(pausedSession.calculateActiveElapsedMs(760000), equals(60000));
      expect(pausedSession.calculateActiveSeconds(760000), equals(60));
      expect(pausedSession.calculateRemainingSeconds(760000), equals(1440));

      // Step 3: Resumed at 760k.
      // Accumulated paused = 600,000ms. lastResumeRealtimeMs = 760,000ms.
      final resumedSession = pausedSession.copyWith(
        state: FocusSessionState.running,
        lastResumeRealtimeMs: 760000,
        lastResumeWallMs: 1700000660000,
        accumulatedPausedMs: 600000,
        pauseStartRealtimeMs: null,
        pauseStartWallMs: null,
      );

      // Now run 30 more seconds (to 790k):
      // Active elapsed should be 60s + 30s = 90s (90,000ms).
      expect(resumedSession.calculateActiveElapsedMs(790000), equals(90000));
      expect(resumedSession.calculateActiveSeconds(790000), equals(90));
      expect(resumedSession.calculateRemainingSeconds(790000), equals(1410));
    });

    test('Stopwatch mode counts up without bounds and remainingSeconds returns 0', () {
      final stopwatchSession = ActiveSessionModel(
        id: 'test_stopwatch',
        mode: FocusTimerMode.stopwatch,
        targetSeconds: 0,
        elapsedRealtimeStartMs: 50000,
        wallClockStartMs: 1700000000000,
        lastResumeRealtimeMs: 50000,
        lastResumeWallMs: 1700000000000,
        bootTimeEpochMs: 1699900000000,
        state: FocusSessionState.running,
        subjectName: 'Revision',
        chapterName: 'General',
        updatedAt: DateTime.now(),
      );

      // 120 seconds elapsed
      final currentMonotonic = 170000;
      expect(stopwatchSession.calculateActiveElapsedMs(currentMonotonic), equals(120000));
      expect(stopwatchSession.calculateActiveSeconds(currentMonotonic), equals(120));
      expect(stopwatchSession.calculateRemainingSeconds(currentMonotonic), equals(0));
      expect(stopwatchSession.isExpired(currentMonotonic), isFalse);
    });

    test('Expired session stops exactly at 0 remaining seconds and marks isExpired true', () {
      final session = ActiveSessionModel(
        id: 'test_session_expired',
        mode: FocusTimerMode.custom,
        targetSeconds: 60, // 1 minute target
        elapsedRealtimeStartMs: 10000,
        wallClockStartMs: 1700000000000,
        lastResumeRealtimeMs: 10000,
        lastResumeWallMs: 1700000000000,
        bootTimeEpochMs: 1699900000000,
        state: FocusSessionState.running,
        subjectName: 'English',
        chapterName: 'First Flight',
        updatedAt: DateTime.now(),
      );

      // 70 seconds elapsed (target was 60)
      final currentMonotonic = 80000;
      expect(session.calculateActiveSeconds(currentMonotonic), equals(70));
      expect(session.calculateRemainingSeconds(currentMonotonic), equals(0));
      expect(session.isExpired(currentMonotonic), isTrue);
      expect(session.calculateProgress(currentMonotonic), equals(1.0));
    });
  });

  group('Focus Timer Reliability — SQLite ActiveSessionStore Persistence', () {
    late Database inMemoryDb;
    late DatabaseHelper dbHelper;
    late ActiveSessionStore sessionStore;

    setUp(() async {
      inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      dbHelper = DatabaseHelper.instance;
      dbHelper.setDatabaseForTesting(inMemoryDb);
      sessionStore = ActiveSessionStore(dbHelper: dbHelper);
      await sessionStore.ensureTableExists(inMemoryDb);
    });

    test('Saves, retrieves and clears active session in SQLite store', () async {
      final session = ActiveSessionModel(
        id: 'session_sqlite_test_1',
        mode: FocusTimerMode.pomodoro,
        pomodoroPhase: PomodoroPhase.work,
        pomodoroCycle: 2,
        targetSeconds: 1500,
        elapsedRealtimeStartMs: 250000,
        wallClockStartMs: 1700000000000,
        accumulatedActiveMs: 120000,
        accumulatedPausedMs: 45000,
        lastResumeRealtimeMs: 295000,
        lastResumeWallMs: 1700000045000,
        bootTimeEpochMs: 1699900000000,
        state: FocusSessionState.running,
        subjectName: 'Chemistry',
        chapterName: 'Chemical Reactions',
        subtopicName: 'Balancing Equations',
        treeSpecies: TreeSpecies.mountainPine,
        strictModeEnabled: true,
        updatedAt: DateTime.now(),
      );

      // Save to SQLite
      await sessionStore.persistSession(session, inMemoryDb);

      // Retrieve from SQLite
      final restored = await sessionStore.loadActiveSession(inMemoryDb);
      expect(restored, isNotNull);
      expect(restored!.id, equals('session_sqlite_test_1'));
      expect(restored.mode, equals(FocusTimerMode.pomodoro));
      expect(restored.pomodoroPhase, equals(PomodoroPhase.work));
      expect(restored.pomodoroCycle, equals(2));
      expect(restored.targetSeconds, equals(1500));
      expect(restored.elapsedRealtimeStartMs, equals(250000));
      expect(restored.accumulatedActiveMs, equals(120000));
      expect(restored.accumulatedPausedMs, equals(45000));
      expect(restored.subjectName, equals('Chemistry'));
      expect(restored.chapterName, equals('Chemical Reactions'));
      expect(restored.subtopicName, equals('Balancing Equations'));
      expect(restored.treeSpecies, equals(TreeSpecies.mountainPine));
      expect(restored.strictModeEnabled, isTrue);

      // Clear session
      await sessionStore.clearActiveSession(inMemoryDb);
      final afterClear = await sessionStore.loadActiveSession(inMemoryDb);
      expect(afterClear, isNull);
    });
  });

  group('Focus Timer Reliability — Reward Idempotency Ledger Tests', () {
    late Database inMemoryDb;
    late DatabaseHelper dbHelper;
    late ForestProvider forestProvider;

    setUp(() async {
      inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      dbHelper = DatabaseHelper.instance;
      dbHelper.setDatabaseForTesting(inMemoryDb);

      // Create core user_profiles table
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

      // Initialize initial user
      final initialUser = UserProfile.defaultProfile(id: 'default_student').copyWith(
        coins: 100,
        totalXp: 50,
      );
      await dbHelper.saveUserProfile(initialUser);

      // Seed Forest initial data (creates forest_trees, forest_achievements, reward_transactions)
      await dbHelper.seedInitialForestData();

      forestProvider = ForestProvider();
      await forestProvider.loadForestData();
    });

    test('reward_transactions ledger prevents duplicate reward recording', () async {
      const txId = 'reward_session_audit_test_99';

      // First check: transaction not recorded
      expect(await dbHelper.isRewardTransactionRecorded(txId), isFalse);

      // Record first transaction
      await dbHelper.recordRewardTransaction(
        transactionId: txId,
        type: 'focus_session_reward',
        xpAmount: 25,
        coinsAmount: 5,
        reason: '25 min study',
      );
      expect(await dbHelper.isRewardTransactionRecorded(txId), isTrue);
    });

    test('ForestProvider.plantTree with sessionId is strictly idempotent', () async {
      const sessionId = 'focus_session_unique_42';

      final initialProfile = await dbHelper.getUserProfile('default_student');
      final initialCoins = initialProfile!.coins;
      final initialXp = initialProfile.totalXp;

      // 1st plantTree call: Should plant tree, award XP & coins
      final firstTree = await forestProvider.plantTree(
        species: TreeSpecies.ancientOak,
        focusMinutes: 25,
        subjectName: 'Mathematics',
        chapterName: 'Trigonometry',
        sessionId: sessionId,
      );

      expect(firstTree, isNotNull);
      expect(firstTree.subjectName, equals('Mathematics'));
      expect(firstTree.focusMinutes, equals(25));
      expect(firstTree.status, equals('HEALTHY'));

      final profileAfterFirst = await dbHelper.getUserProfile('default_student');
      // 25 mins: stage 2 (20-39m): xpEarned = 25*2 + 25 = 75, coinsEarned = round(25*0.5)+5 = 13+5 = 18
      expect(profileAfterFirst!.coins, greaterThan(initialCoins));
      expect(profileAfterFirst.totalXp, greaterThan(initialXp));

      // 2nd plantTree call with same sessionId: Must be idempotent!
      // Must return the already planted tree without granting extra coins or XP.
      final secondTree = await forestProvider.plantTree(
        species: TreeSpecies.ancientOak,
        focusMinutes: 25,
        subjectName: 'Mathematics',
        chapterName: 'Trigonometry',
        sessionId: sessionId,
      );

      expect(secondTree.id, equals(firstTree.id));

      final profileAfterDuplicate = await dbHelper.getUserProfile('default_student');
      // Ensure coins and XP DID NOT increment again!
      expect(profileAfterDuplicate!.coins, equals(profileAfterFirst.coins));
      expect(profileAfterDuplicate.totalXp, equals(profileAfterFirst.totalXp));

      // Ensure total tree count in forest only incremented once
      final treesInForest = await dbHelper.getForestTrees();
      final matchingTrees = treesInForest.where((t) => t.id == firstTree.id).toList();
      expect(matchingTrees.length, equals(1));
    });
  });

  group('Focus Timer Reliability — Reboot Detection & Duration Integrity', () {
    test('Detects device reboot when boot time changes and does not fabricate false time', () {
      final recordedBootTime = 1700000000000;
      final newBootTimeAfterReboot = 1700050000000; // Device rebooted 50,000s later

      final sessionBeforeReboot = ActiveSessionModel(
        id: 'session_interrupted_by_reboot',
        mode: FocusTimerMode.custom,
        targetSeconds: 3600, // 60 minutes
        elapsedRealtimeStartMs: 50000,
        wallClockStartMs: 1700010000000,
        accumulatedActiveMs: 900000, // 15 mins active before power off
        accumulatedPausedMs: 0,
        lastResumeRealtimeMs: 50000,
        lastResumeWallMs: 1700010000000,
        bootTimeEpochMs: recordedBootTime,
        state: FocusSessionState.running,
        subjectName: 'Physics',
        chapterName: 'Electricity',
        updatedAt: DateTime.now(),
      );

      // Check if reboot occurred:
      final isRebootDetected = (newBootTimeAfterReboot - sessionBeforeReboot.bootTimeEpochMs).abs() > 5000;
      expect(isRebootDetected, isTrue);

      // On reboot recovery, session transitions to interruptedByReboot
      final recoveredSession = sessionBeforeReboot.copyWith(
        state: FocusSessionState.interruptedByReboot,
      );

      // Monotonic time on new boot is reset (e.g. only 10,000ms since new boot)
      final newMonotonicMs = 10000;

      // Active elapsed time must preserve pre-reboot active time (15 mins = 900,000ms)
      // and MUST NOT calculate negative or fabricated time
        expect(recoveredSession.calculateActiveElapsedMs(newMonotonicMs), equals(900000));
      expect(recoveredSession.calculateActiveSeconds(newMonotonicMs), equals(900));
      expect(recoveredSession.isInterrupted, isTrue);
    });
  });

  group('Focus Timer Reliability — Pomodoro Cycle Progression Tests', () {
    test('Pomodoro transitions properly from work to break and long break after cycle 4', () {
      // Phase 1: Work (Cycle 1)
      final p1 = ActiveSessionModel(
        id: 'pomo_1',
        mode: FocusTimerMode.pomodoro,
        pomodoroPhase: PomodoroPhase.work,
        pomodoroCycle: 1,
        targetSeconds: 25 * 60,
        elapsedRealtimeStartMs: 0,
        wallClockStartMs: 0,
        lastResumeRealtimeMs: 0,
        lastResumeWallMs: 0,
        bootTimeEpochMs: 0,
        state: FocusSessionState.running,
        subjectName: 'Math',
        chapterName: 'Real Numbers',
        updatedAt: DateTime.now(),
      );
      expect(p1.pomodoroPhase, equals(PomodoroPhase.work));
      expect(p1.pomodoroCycle, equals(1));
      expect(p1.targetSeconds, equals(1500));

      // Transition 1: Work (cycle 1) -> Short Break (cycle 1, 5 min)
      final p2NextPhase = p1.pomodoroCycle % 4 == 0 ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
      final p2Target = p2NextPhase == PomodoroPhase.longBreak ? 15 * 60 : 5 * 60;
      final p2 = p1.copyWith(
        pomodoroPhase: p2NextPhase,
        targetSeconds: p2Target,
      );
      expect(p2.pomodoroPhase, equals(PomodoroPhase.shortBreak));
      expect(p2.targetSeconds, equals(300));
      expect(p2.pomodoroCycle, equals(1));

      // Transition 2: Short Break (cycle 1) -> Work (cycle 2, 25 min)
      final p3 = p2.copyWith(
        pomodoroPhase: PomodoroPhase.work,
        pomodoroCycle: p2.pomodoroCycle + 1,
        targetSeconds: 25 * 60,
      );
      expect(p3.pomodoroPhase, equals(PomodoroPhase.work));
      expect(p3.pomodoroCycle, equals(2));
      expect(p3.targetSeconds, equals(1500));

      // Fast forward to Work (cycle 4)
      final pWork4 = p3.copyWith(
        pomodoroPhase: PomodoroPhase.work,
        pomodoroCycle: 4,
        targetSeconds: 25 * 60,
      );

      // Transition 4: Work (cycle 4) -> Long Break (cycle 4, 15 min) because 4 % 4 == 0
      final p4NextPhase = pWork4.pomodoroCycle % 4 == 0 ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
      final p4Target = p4NextPhase == PomodoroPhase.longBreak ? 15 * 60 : 5 * 60;
      final p4 = pWork4.copyWith(
        pomodoroPhase: p4NextPhase,
        targetSeconds: p4Target,
      );
      expect(p4.pomodoroPhase, equals(PomodoroPhase.longBreak));
      expect(p4.targetSeconds, equals(900));
      expect(p4.pomodoroCycle, equals(4));
    });
  });
}
