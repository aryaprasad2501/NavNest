import 'package:flutter_test/flutter_test.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/features/navbloom/presentation/utils/forest_preview_fixture.dart';
import 'package:navnest/features/navbloom/presentation/utils/planting_space_manager.dart';

void main() {
  group('NavBloom Forest Population Preview & Mature Simulation Tests', () {
    test('1. Presets return expected tree counts across all population densities', () {
      expect(ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.live), isEmpty);
      expect(ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.newGrove).length, equals(4));
      expect(ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.growingGrove).length, equals(12));
      expect(ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.establishedForest).length, equals(30));
      expect(ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.denseWoodland).length, equals(50));
      expect(ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.matureWoodland).length, equals(80));
      expect(ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.primevalCanopy).length, equals(120));
      expect(ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.legendaryWildwood).length, equals(160));
    });

    test('2. Default preview (allMature = false) contains realistic mixture of all 5 growth stages and withered trees', () {
      final denseTrees = ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.denseWoodland, allMature: false);

      final stages = denseTrees.map((t) => t.stage).toSet();
      expect(stages.contains(1), isTrue, reason: 'Must contain seeds or sprouts');
      expect(stages.contains(2), isTrue, reason: 'Must contain sprouts');
      expect(stages.contains(3), isTrue, reason: 'Must contain saplings');
      expect(stages.contains(4), isTrue, reason: 'Must contain young trees');
      expect(stages.contains(5), isTrue, reason: 'Must contain mature trees');

      final hasWithered = denseTrees.any((t) => t.isWithered);
      expect(hasWithered, isTrue, reason: 'Must contain withered reminder trees in realistic simulation');
    });

    test('3. allMature = true transforms 100% of trees in the preset to Stage 5 Full Bloom', () {
      final matureWoodland = ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.matureWoodland, allMature: true);

      expect(matureWoodland.length, equals(80));
      for (final tree in matureWoodland) {
        expect(tree.stage, equals(5), reason: 'Every tree must be Stage 5 in allMature mode');
        expect(tree.isWithered, isFalse, reason: 'All trees are healthy and blooming in endgame simulation');
        expect(tree.maturedAt, isNotNull, reason: 'Matured timestamp must be set');
        expect(tree.focusMinutes, greaterThanOrEqualTo(90));
      }
    });

    test('4. All 15 botanical species are represented in the dense and mature presets', () {
      final matureTrees = ForestPreviewFixture.getTreesForDensity(ForestPreviewDensity.matureWoodland);
      final speciesFound = matureTrees.map((t) => t.species).toSet();

      for (final species in TreeSpecies.values) {
        expect(speciesFound.contains(species), isTrue, reason: '${species.displayName} must be present');
      }
    });

    test('5. Tree placement coordinates remain within bounded glade ratios and have stable spatial dispersion', () {
      for (final density in [
        ForestPreviewDensity.newGrove,
        ForestPreviewDensity.growingGrove,
        ForestPreviewDensity.establishedForest,
        ForestPreviewDensity.denseWoodland,
        ForestPreviewDensity.matureWoodland,
        ForestPreviewDensity.primevalCanopy,
        ForestPreviewDensity.legendaryWildwood,
      ]) {
        final trees = ForestPreviewFixture.getTreesForDensity(density);
        for (final tree in trees) {
          expect(tree.xRatio, greaterThanOrEqualTo(0.08));
          expect(tree.xRatio, lessThanOrEqualTo(0.92));
          expect(tree.yRatio, greaterThanOrEqualTo(0.15));
          expect(tree.yRatio, lessThanOrEqualTo(0.88));
          expect(tree.id, isNotEmpty);
          expect(tree.subjectName, isNotEmpty);
          expect(tree.chapterName, isNotEmpty);
        }
      }
    });
  });

  group('NavBloom Planting Space Manager & Capacity Tests', () {
    test('1. Evaluates empty glade and finds spacious central placement', () {
      final result = PlantingSpaceManager.findOptimalPlantingSpot(existingTrees: []);
      expect(result.isFullCapacity, isFalse);
      expect(result.xRatio, greaterThanOrEqualTo(0.20));
      expect(result.xRatio, lessThanOrEqualTo(0.80));
      expect(result.yRatio, greaterThanOrEqualTo(0.20));
      expect(result.yRatio, lessThanOrEqualTo(0.80));
    });

    test('2. Places new tree away from existing cluster to prevent overlapping hitboxes', () {
      final existingCluster = [
        ForestTreeModel(
          id: 'test_1',
          species: TreeSpecies.ancientOak,
          stage: 5,
          xRatio: 0.50,
          yRatio: 0.50,
          plantedAt: DateTime.now(),
          subjectName: 'Math',
          chapterName: 'Real Numbers',
          focusMinutes: 45,
          xpEarned: 100,
          coinsEarned: 25,
        ),
      ];

      final result = PlantingSpaceManager.findOptimalPlantingSpot(existingTrees: existingCluster);
      expect(result.isFullCapacity, isFalse);

      // Distance in isometric projection must be maintained
      final du = result.xRatio - 0.50;
      final dv = result.yRatio - 0.50;
      final dist = (du * du + 1.8 * dv * dv);
      expect(dist, greaterThan(0.005), reason: 'Must avoid placing directly on top of existing tree');
    });

    test('3. Detects full capacity and recommends expansion biome', () {
      final fullTrees = List.generate(
        50,
        (i) => ForestTreeModel(
          id: 'tree_$i',
          species: TreeSpecies.mountainPine,
          stage: 5,
          xRatio: 0.1 + (i % 8) * 0.1,
          yRatio: 0.2 + (i ~/ 8) * 0.1,
          plantedAt: DateTime.now(),
          subjectName: 'Science',
          chapterName: 'Light',
          focusMinutes: 60,
          xpEarned: 150,
          coinsEarned: 40,
        ),
      );

      final result = PlantingSpaceManager.findOptimalPlantingSpot(
        existingTrees: fullTrees,
        maxCapacity: 50,
        nextBiomeName: 'Cherry Valley',
      );

      expect(result.isFullCapacity, isTrue);
      expect(result.expansionBiomeName, equals('Cherry Valley'));

      final capacityInfo = PlantingSpaceManager.getCapacityInfo(
        trees: fullTrees,
        maxCapacity: 50,
        nextBiomeName: 'Cherry Valley',
      );
      expect(capacityInfo.isFull, isTrue);
      expect(capacityInfo.fillPercentage, equals(1.0));
      expect(capacityInfo.recommendation, contains('Cherry Valley'));
    });
  });
}
