import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/core/models/user_profile.dart';
import 'package:navnest/features/navbloom/presentation/providers/forest_provider.dart';
import 'package:navnest/features/navbloom/presentation/tree_details_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NavBloom Reward Integrity & Anti-Cheat Regression Tests', () {
    late Database inMemoryDb;
    late DatabaseHelper dbHelper;

    setUp(() async {
      inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      dbHelper = DatabaseHelper.instance;
      dbHelper.setDatabaseForTesting(inMemoryDb);

      // Create user_profiles table
      await inMemoryDb.execute('''
        CREATE TABLE user_profiles (
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

      final initialUser = UserProfile.defaultProfile(id: 'default_student').copyWith(
        coins: 200,
        totalXp: 500,
      );
      await dbHelper.saveUserProfile(initialUser);
      await dbHelper.seedInitialForestData();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('1. Repeated taps on Nurture Tree cannot fabricate growth, XP, coins, or study time', () async {
      final provider = ForestProvider(dbHelper: dbHelper);
      await provider.loadForestData();

      // Plant an authoritative Stage 2 Sprout tree from a verified 25-minute study session
      final initialTree = await provider.plantTree(
        species: TreeSpecies.cherryBlossom,
        subjectName: 'Physics',
        chapterName: 'Light Reflection',
        focusMinutes: 25,
        sessionId: 'session_real_001',
      );

      expect(initialTree.stage, equals(2));
      final initialXp = provider.userXp;
      final initialCoins = provider.userCoins;
      final initialTreesCount = provider.trees.length;

      // Tap Nurture Tree 10 times in rapid succession
      for (int i = 0; i < 10; i++) {
        await provider.nurtureTree(initialTree.id);
      }

      final postTree = provider.trees.firstWhere((t) => t.id == initialTree.id);

      // Growth stage must strictly remain Stage 2 (unearned advancement blocked)
      expect(postTree.stage, equals(2), reason: 'Nurture must not advance tree growth stage');
      expect(postTree.focusMinutes, equals(25), reason: 'Nurture must not fabricate focus minutes');

      // Zero unearned XP and Zero unearned coins
      expect(provider.userXp, equals(initialXp), reason: 'Nurture must not grant unearned XP');
      expect(provider.userCoins, equals(initialCoins), reason: 'Nurture must not grant unearned coins');
      expect(provider.trees.length, equals(initialTreesCount));

      // Journal entries from nurturing should have 0 focusMinutes and 0 XP
      final journal = await dbHelper.getJournalEntries();
      final careEntries = journal.where((j) => j.category == 'CARE').toList();
      expect(careEntries.length, equals(10));
      for (final entry in careEntries) {
        expect(entry.focusMinutes, equals(0));
        expect(entry.xpEarned, equals(0));
        expect(entry.coinsEarned, equals(0));
      }
    });

    testWidgets('2. Visual stage preview is completely isolated from persisted authoritative growth stage', (tester) async {
      final provider = ForestProvider(dbHelper: dbHelper);
      final tree = ForestTreeModel(
        id: 'tree_stage_2_isolation_test',
        species: TreeSpecies.ancientOak,
        subjectName: 'Mathematics',
        chapterName: 'Real Numbers',
        stage: 2,
        xRatio: 0.5,
        yRatio: 0.5,
        focusMinutes: 25,
        xpEarned: 50,
        coinsEarned: 25,
        plantedAt: DateTime(2026, 3, 15),
        sessionId: 'session_real_oak_02',
      );

      provider.setForestDataForTesting(
        trees: [tree],
        userProfile: UserProfile.defaultProfile(id: 'default_student'),
      );

      expect(tree.stage, equals(2));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ForestProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: TreeDetailsScreen(tree: tree, autoSpin3D: false),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Authoritative growth progression tracker shows Stage 2
      expect(find.text('Growth Progression'), findsOneWidget);

      // Switch visual 3D preview to Stage 5 Bloom
      await tester.tap(find.text('Bloom 🌸'));
      await tester.pump(const Duration(milliseconds: 100));

      // Preview banner is displayed with clear separation
      expect(find.textContaining('Visual 3D Preview: Stage 5'), findsOneWidget);
      expect(find.textContaining('Actual Persisted Growth: Stage 2'), findsOneWidget);

      // Verify the persisted tree in the provider has NOT changed stage!
      final currentTreeInProvider = provider.trees.firstWhere((t) => t.id == tree.id);
      expect(currentTreeInProvider.stage, equals(2));

      // Tap Reset button in preview banner to snap back to persisted stage
      await tester.tap(find.text('Reset'));
      await tester.pump(const Duration(milliseconds: 100));

      // Banner should disappear after reset
      expect(find.textContaining('Visual 3D Preview: Stage 5'), findsNothing);
    });

    test('3. App process restart & database reload preserves exact tree stages and economy', () async {
      final provider1 = ForestProvider(dbHelper: dbHelper);
      await provider1.loadForestData();

      // Plant 2 trees with verified sessions
      await provider1.plantTree(
        species: TreeSpecies.cherryBlossom,
        subjectName: 'Science',
        chapterName: 'Chemical Reactions',
        focusMinutes: 45, // Stage 3 Sapling
        sessionId: 'session_restart_test_1',
      );

      await provider1.plantTree(
        species: TreeSpecies.mountainPine,
        subjectName: 'History',
        chapterName: 'Rise of Nationalism',
        focusMinutes: 90, // Stage 5 Bloom
        sessionId: 'session_restart_test_2',
      );

      final xpBeforeRestart = provider1.userXp;
      final coinsBeforeRestart = provider1.userCoins;
      final treesCountBeforeRestart = provider1.totalTreesCount;

      // Simulate App Process Restart by constructing a fresh provider instance
      final provider2 = ForestProvider(dbHelper: dbHelper);
      await provider2.loadForestData();

      expect(provider2.totalTreesCount, equals(treesCountBeforeRestart));
      expect(provider2.userXp, equals(xpBeforeRestart));
      expect(provider2.userCoins, equals(coinsBeforeRestart));

      final tree1 = provider2.trees.firstWhere((t) => t.sessionId == 'session_restart_test_1');
      expect(tree1.stage, equals(3));
      expect(tree1.focusMinutes, equals(45));

      final tree2 = provider2.trees.firstWhere((t) => t.sessionId == 'session_restart_test_2');
      expect(tree2.stage, equals(5));
      expect(tree2.focusMinutes, equals(90));
      expect(tree2.isMature, isTrue);
    });

    test('4. Duplicate reward attempts via plantTree with same sessionId are strictly idempotent', () async {
      final provider = ForestProvider(dbHelper: dbHelper);
      await provider.loadForestData();

      const uniqueSessionId = 'session_idempotent_proof_999';

      // 1st plantTree call: should award tree, XP, and coins
      final firstTree = await provider.plantTree(
        species: TreeSpecies.goldenGinkgo,
        subjectName: 'Geography',
        chapterName: 'Resources and Development',
        focusMinutes: 60,
        sessionId: uniqueSessionId,
      );

      final xpAfterFirst = provider.userXp;
      final coinsAfterFirst = provider.userCoins;
      final treeCountAfterFirst = provider.totalTreesCount;

      // 2nd plantTree call with IDENTICAL sessionId: Must return existing tree without awarding XP/coins
      final secondTree = await provider.plantTree(
        species: TreeSpecies.goldenGinkgo,
        subjectName: 'Geography',
        chapterName: 'Resources and Development',
        focusMinutes: 60,
        sessionId: uniqueSessionId,
      );

      expect(secondTree.id, equals(firstTree.id));
      expect(provider.totalTreesCount, equals(treeCountAfterFirst));
      expect(provider.userXp, equals(xpAfterFirst), reason: 'Duplicate call must not award extra XP');
      expect(provider.userCoins, equals(coinsAfterFirst), reason: 'Duplicate call must not award extra coins');

      // Verify transaction ledger has exactly 1 entry for this session
      final isRecorded = await dbHelper.isRewardTransactionRecorded('reward_session_$uniqueSessionId');
      expect(isRecorded, isTrue);

      final allTreesInDb = await dbHelper.getForestTrees();
      final matchingTrees = allTreesInDb.where((t) => t.sessionId == uniqueSessionId).toList();
      expect(matchingTrees.length, equals(1));
    });

    test('5. Repeated decoration unlock calls cannot deduct coins multiple times', () async {
      final provider = ForestProvider(dbHelper: dbHelper);
      await provider.loadForestData();

      final initialCoins = provider.userCoins; // 200 coins
      const decId = 'dec_stones_1';
      const decCost = 80;

      // 1st unlock: should deduct 80 coins
      final success1 = await provider.unlockDecoration(decId, decCost);
      expect(success1, isTrue);
      expect(provider.userCoins, equals(initialCoins - decCost));

      final coinsAfterFirstUnlock = provider.userCoins;

      // 2nd unlock attempt on same decoration: must NOT deduct coins again
      final success2 = await provider.unlockDecoration(decId, decCost);
      expect(success2, isTrue);
      expect(provider.userCoins, equals(coinsAfterFirstUnlock), reason: 'Already unlocked items must not deduct coins again');
    });
  });
}
