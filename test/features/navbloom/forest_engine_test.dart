import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/core/models/user_profile.dart';
import 'package:navnest/features/navbloom/presentation/providers/forest_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NavBloom Forest Engine & Persistence Tests', () {
    late Database inMemoryDb;
    late DatabaseHelper dbHelper;

    setUp(() async {
      inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      dbHelper = DatabaseHelper.instance;
      dbHelper.setDatabaseForTesting(inMemoryDb);

      // Create core user_profiles table
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

      // Save initial user profile
      final initialUser = UserProfile.defaultProfile(id: 'default_student').copyWith(
        coins: 200,
        totalXp: 500,
      );
      await dbHelper.saveUserProfile(initialUser);

      // Seed initial Forest data
      await dbHelper.seedInitialForestData();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('seedInitialForestData populates default trees, decorations, journal, and achievements', () async {
      final trees = await dbHelper.getForestTrees();
      expect(trees.length, greaterThanOrEqualTo(4));
      expect(trees.any((t) => t.species == TreeSpecies.cherryBlossom), isTrue);
      expect(trees.any((t) => t.species == TreeSpecies.mountainPine), isTrue);

      final decorations = await dbHelper.getDecorations();
      expect(decorations.length, greaterThanOrEqualTo(4));
      expect(decorations.any((d) => d.name == 'Stone Lantern'), isTrue);

      final journal = await dbHelper.getJournalEntries();
      expect(journal.length, greaterThanOrEqualTo(4));

      final achievements = await dbHelper.getAchievements();
      expect(achievements.length, greaterThanOrEqualTo(5));
      expect(achievements.any((a) => a.id == 'ach_first_seed'), isTrue);
    });

    test('ForestTreeModel CRUD operations function properly', () async {
      final now = DateTime.now();
      final newTree = ForestTreeModel(
        id: 'tree_test_oak_99',
        species: TreeSpecies.ancientOak,
        stage: 2,
        xRatio: 0.45,
        yRatio: 0.55,
        plantedAt: now,
        subjectName: 'Science',
        chapterName: 'Chemical Reactions and Equations',
        focusMinutes: 45,
        xpEarned: 120,
        coinsEarned: 30,
      );

      // Insert
      await dbHelper.insertForestTree(newTree);
      var trees = await dbHelper.getForestTrees();
      expect(trees.any((t) => t.id == 'tree_test_oak_99'), isTrue);

      // Update growth stage to 5
      final updatedTree = newTree.copyWith(stage: 5, maturedAt: now);
      await dbHelper.updateForestTree(updatedTree);

      trees = await dbHelper.getForestTrees();
      final retrieved = trees.firstWhere((t) => t.id == 'tree_test_oak_99');
      expect(retrieved.stage, equals(5));
      expect(retrieved.isMatured, isTrue);

      // Delete
      await dbHelper.deleteForestTree('tree_test_oak_99');
      trees = await dbHelper.getForestTrees();
      expect(trees.any((t) => t.id == 'tree_test_oak_99'), isFalse);
    });

    test('ForestDecorationModel unlock and toggle equip operations work', () async {
      var decs = await dbHelper.getDecorations();
      final unlockedCount = decs.where((d) => d.isUnlocked).length;
      expect(unlockedCount, greaterThanOrEqualTo(3));

      // Toggle equip state of stone lantern
      const lanternId = 'dec_lantern_1';
      final lanternBefore = decs.firstWhere((d) => d.id == lanternId);
      final prevEquipped = lanternBefore.isEquipped;

      await dbHelper.toggleEquipDecoration(lanternId, !prevEquipped);
      decs = await dbHelper.getDecorations();
      final lanternAfter = decs.firstWhere((d) => d.id == lanternId);
      expect(lanternAfter.isEquipped, equals(!prevEquipped));
    });

    test('AchievementModel progress updating and unlocking works', () async {
      await dbHelper.updateAchievementProgress('ach_green_thumb', 5);
      final achievements = await dbHelper.getAchievements();
      final greenThumb = achievements.firstWhere((a) => a.id == 'ach_green_thumb');
      expect(greenThumb.progress, equals(5));
      expect(greenThumb.isUnlocked, isTrue);
    });

    test('ForestProvider coordinates planting, nurturing, and coin economy', () async {
      final provider = ForestProvider(dbHelper: dbHelper);
      await provider.loadForestData();

      final initialTreesCount = provider.totalTreesCount;
      final initialCoins = provider.userCoins;
      final initialXp = provider.userXp;

      // 1. Plant a 90-minute full-bloom Ginkgo tree
      final plantedTree = await provider.plantTree(
        species: TreeSpecies.goldenGinkgo,
        subjectName: 'Mathematics',
        chapterName: 'Quadratic Equations',
        focusMinutes: 90,
      );

      expect(provider.totalTreesCount, equals(initialTreesCount + 1));
      expect(plantedTree.stage, equals(5)); // >=90m should be full bloom
      expect(provider.userCoins, greaterThan(initialCoins));
      expect(provider.userXp, greaterThan(initialXp));

      // 2. Plant a 25-minute sprout Pine tree and nurture it
      final sproutTree = await provider.plantTree(
        species: TreeSpecies.mountainPine,
        subjectName: 'English',
        chapterName: 'A Letter to God',
        focusMinutes: 25,
      );
      expect(sproutTree.stage, equals(2));

      // Nurture the tree
      await provider.nurtureTree(sproutTree.id);
      final nurturedTree = provider.trees.firstWhere((t) => t.id == sproutTree.id);
      expect(nurturedTree.stage, equals(3)); // Advanced to stage 3

      // 3. Moonlit Night Mode Toggle
      expect(provider.isMoonlitNight, isFalse);
      provider.toggleMoonlitMode();
      expect(provider.isMoonlitNight, isTrue);

      // 4. Area selection
      provider.selectArea('area_2');
      expect(provider.selectedAreaId, equals('area_2'));
    });
  });
}
