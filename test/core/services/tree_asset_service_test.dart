import 'package:flutter_test/flutter_test.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/core/services/tree_asset_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TreeSpecies Botanical Metadata & Asset Paths Tests', () {
    test('All 15 TreeSpecies possess botanical names, prefixes, lore, and unlock requirements', () {
      expect(TreeSpecies.values.length, equals(15));

      for (final species in TreeSpecies.values) {
        expect(species.botanicalName, isNotEmpty);
        expect(species.assetPrefix, isNotEmpty);
        expect(species.lore, isNotEmpty);
        expect(species.displayName, isNotEmpty);
        expect(species.unlockRequirement, isNotEmpty);
        expect(species.tier, isNotEmpty);

        // Stages 1 to 5 asset paths
        for (int stage = 1; stage <= 5; stage++) {
          final path = species.getAssetPath(stage);
          expect(path, equals('assets/trees/${species.assetPrefix}_stage_$stage.png'));
        }

        // Withered asset path
        expect(species.getWitheredAssetPath(), equals('assets/trees/${species.assetPrefix}_withered.png'));
        expect(species.getAssetPath(3, isWithered: true), equals('assets/trees/${species.assetPrefix}_withered.png'));

        // Mature asset path
        expect(species.getMatureAssetPath(), equals('assets/trees/${species.assetPrefix}_stage_5.png'));
      }
    });

    test('ForestTreeModel exposes botanical metadata and dynamically resolves asset paths', () {
      final healthyTree = ForestTreeModel(
        id: 'cherry_tree_1',
        species: TreeSpecies.cherryBlossom,
        stage: 4,
        xRatio: 0.5,
        yRatio: 0.5,
        plantedAt: DateTime(2026, 10, 14),
        subjectName: 'Biology',
        chapterName: 'Life Processes',
        focusMinutes: 45,
        xpEarned: 120,
        coinsEarned: 30,
        status: 'HEALTHY',
      );

      expect(healthyTree.botanicalName, equals('Prunus serrulata'));
      expect(healthyTree.lore, contains('blossoms'));
      expect(healthyTree.assetPath, equals('assets/trees/cherry_blossom_stage_4.png'));
      expect(healthyTree.matureAssetPath, equals('assets/trees/cherry_blossom_stage_5.png'));

      final witheredTree = healthyTree.copyWith(status: 'WITHERED');
      expect(witheredTree.isWithered, isTrue);
      expect(witheredTree.assetPath, equals('assets/trees/cherry_blossom_withered.png'));
      expect(witheredTree.witheredAssetPath, equals('assets/trees/cherry_blossom_withered.png'));
    });
  });

  group('TreeAssetService Caching & Missing Asset Safety Tests', () {
    final service = TreeAssetService.instance;

    setUp(() {
      service.clearCache();
    });

    test('Non-existent sprite path safely fails without throwing and caches missing state', () async {
      const nonExistentPath = 'assets/trees/non_existent_pine.png';

      expect(service.getCachedSprite(nonExistentPath), isNull);
      expect(service.hasCachedSprite(nonExistentPath), isFalse);
      expect(service.isKnownMissing(nonExistentPath), isFalse);

      final result = await service.loadTreeSprite(nonExistentPath);
      expect(result, isNull);
      expect(service.isKnownMissing(nonExistentPath), isTrue);

      // Subsequent lookup returns null immediately without attempting reload
      final secondLookup = await service.loadTreeSprite(nonExistentPath);
      expect(secondLookup, isNull);
    });

    test('PreloadAllSpecies attempts gracefully for future assets without exceptions', () async {
      await expectLater(service.preloadAllSpecies(), completes);
    });
  });
}
