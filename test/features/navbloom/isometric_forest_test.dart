import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navnest/core/models/forest_decoration_model.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/features/navbloom/presentation/widgets/isometric_forest_painter.dart';

void main() {
  group('2.5D Layered Isometric Sanctuary Mathematics Tests', () {
    test('IsometricCoordinates.gridToScreen maps normalized grid to 2:1 diamond screen coords', () {
      const centerX = 200.0;
      const centerY = 300.0;
      const rx = 100.0;
      const ry = 50.0; // 2:1 ratio (rx / ry = 2.0)

      // Center (u=0.5, v=0.5) should map to center of screen
      final centerScreen = IsometricCoordinates.gridToScreen(
        u: 0.5,
        v: 0.5,
        centerX: centerX,
        centerY: centerY,
        radiusX: rx,
        radiusY: ry,
      );
      expect(centerScreen.dx, closeTo(centerX, 1e-6));
      expect(centerScreen.dy, closeTo(centerY, 1e-6));

      // North apex (u=0.0, v=0.0) -> du = -1, dv = -1 -> dx = cx, dy = cy - 2*ry
      final northScreen = IsometricCoordinates.gridToScreen(
        u: 0.0,
        v: 0.0,
        centerX: centerX,
        centerY: centerY,
        radiusX: rx,
        radiusY: ry,
      );
      expect(northScreen.dx, closeTo(centerX, 1e-6));
      expect(northScreen.dy, closeTo(centerY - 2 * ry, 1e-6));

      // South apex (u=1.0, v=1.0) -> du = 1, dv = 1 -> dx = cx, dy = cy + 2*ry
      final southScreen = IsometricCoordinates.gridToScreen(
        u: 1.0,
        v: 1.0,
        centerX: centerX,
        centerY: centerY,
        radiusX: rx,
        radiusY: ry,
      );
      expect(southScreen.dx, closeTo(centerX, 1e-6));
      expect(southScreen.dy, closeTo(centerY + 2 * ry, 1e-6));

      // West corner (u=0.0, v=1.0) -> du = -1, dv = 1 -> dx = cx - 2*rx, dy = cy
      final westScreen = IsometricCoordinates.gridToScreen(
        u: 0.0,
        v: 1.0,
        centerX: centerX,
        centerY: centerY,
        radiusX: rx,
        radiusY: ry,
      );
      expect(westScreen.dx, closeTo(centerX - 2 * rx, 1e-6));
      expect(westScreen.dy, closeTo(centerY, 1e-6));

      // East corner (u=1.0, v=0.0) -> du = 1, dv = -1 -> dx = cx + 2*rx, dy = cy
      final eastScreen = IsometricCoordinates.gridToScreen(
        u: 1.0,
        v: 0.0,
        centerX: centerX,
        centerY: centerY,
        radiusX: rx,
        radiusY: ry,
      );
      expect(eastScreen.dx, closeTo(centerX + 2 * rx, 1e-6));
      expect(eastScreen.dy, closeTo(centerY, 1e-6));
    });

    test('Isometric depth metric accurately enforces Painter algorithm sorting order', () {
      final backTree = ForestTreeModel(
        id: 'tree_back',
        species: TreeSpecies.mountainPine,
        stage: 4,
        xRatio: 0.1,
        yRatio: 0.2,
        plantedAt: DateTime.now(),
        subjectName: 'Physics',
        chapterName: 'Kinematics',
        focusMinutes: 60,
        xpEarned: 140,
        coinsEarned: 35,
      );

      final frontTree = ForestTreeModel(
        id: 'tree_front',
        species: TreeSpecies.cherryBlossom,
        stage: 5,
        xRatio: 0.8,
        yRatio: 0.9,
        plantedAt: DateTime.now(),
        subjectName: 'Chemistry',
        chapterName: 'Acids',
        focusMinutes: 90,
        xpEarned: 240,
        coinsEarned: 60,
      );

      final backMetric = IsometricCoordinates.depthMetric(backTree.xRatio, backTree.yRatio);
      final frontMetric = IsometricCoordinates.depthMetric(frontTree.xRatio, frontTree.yRatio);

      expect(backMetric, closeTo(0.3, 1e-6));
      expect(frontMetric, closeTo(1.7, 1e-6));
      expect(backMetric, lessThan(frontMetric));

      // When sorted ascending, background entity is drawn first (below foreground entity)
      final trees = [frontTree, backTree];
      trees.sort((a, b) => IsometricCoordinates.depthMetric(a.xRatio, a.yRatio)
          .compareTo(IsometricCoordinates.depthMetric(b.xRatio, b.yRatio)));

      expect(trees.first.id, equals('tree_back'));
      expect(trees.last.id, equals('tree_front'));
    });
  });

  group('IsometricSanctuaryView Widget Tests', () {
    testWidgets('Renders sanctuary canvas with animated wind loop without crashes', (tester) async {
      final sampleTrees = [
        ForestTreeModel(
          id: 'test_tree_1',
          species: TreeSpecies.ancientOak,
          stage: 5,
          xRatio: 0.5,
          yRatio: 0.5,
          plantedAt: DateTime.now(),
          subjectName: 'Mathematics',
          chapterName: 'Calculus',
          focusMinutes: 90,
          xpEarned: 240,
          coinsEarned: 70,
        ),
      ];

      final sampleDecorations = [
        const ForestDecorationModel(
          id: 'lantern_1',
          name: 'Stone Lantern',
          description: 'A glowing stone lantern.',
          category: DecorationCategory.lighting,
          costCoins: 80,
          isUnlocked: true,
          isEquipped: true,
          xRatio: 0.4,
          yRatio: 0.4,
          iconName: 'light_mode',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: IsometricSanctuaryView(
                trees: sampleTrees,
                decorations: sampleDecorations,
                isMoonlit: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(IsometricSanctuaryView), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify wind animation updates smoothly
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(IsometricSanctuaryView), findsOneWidget);
    });

    testWidgets('Tapping on a tree in the sanctuary fires onTreeTap callback', (tester) async {
      ForestTreeModel? tappedTree;

      final sampleTree = ForestTreeModel(
        id: 'center_oak',
        species: TreeSpecies.ancientOak,
        stage: 5,
        xRatio: 0.5,
        yRatio: 0.5,
        plantedAt: DateTime.now(),
        subjectName: 'Biology',
        chapterName: 'Genetics',
        focusMinutes: 100,
        xpEarned: 260,
        coinsEarned: 75,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: IsometricSanctuaryView(
                trees: [sampleTree],
                decorations: const [],
                isMoonlit: false,
                onTreeTap: (tree) {
                  tappedTree = tree;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Screen center is (200, 324). Tree center is (200, 324 - 30) = (200, 294)
      await tester.tapAt(const Offset(200, 294));
      await tester.pump();

      expect(tappedTree, isNotNull);
      expect(tappedTree?.id, equals('center_oak'));
      expect(tappedTree?.species, equals(TreeSpecies.ancientOak));
    });

    testWidgets('Horizontal drag gesture updates sanctuary view with smooth panning', (tester) async {
      int? reportedSector;

      final sampleTree = ForestTreeModel(
        id: 'pan_tree_1',
        species: TreeSpecies.cherryBlossom,
        stage: 5,
        xRatio: 0.5,
        yRatio: 0.5,
        plantedAt: DateTime.now(),
        subjectName: 'Mathematics',
        chapterName: 'Real Numbers',
        focusMinutes: 60,
        xpEarned: 150,
        coinsEarned: 40,
      );

      final controller = SanctuaryViewController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: IsometricSanctuaryView(
                trees: [sampleTree],
                decorations: const [],
                isMoonlit: false,
                controller: controller,
                onSectorChanged: (sector) {
                  reportedSector = sector;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Initial sector is 0
      expect(controller.currentSector, equals(0));
      expect(controller.totalSectors, greaterThanOrEqualTo(2));

      // Drag left by 420 pixels (scrolls to next sector)
      await tester.drag(find.byType(IsometricSanctuaryView), const Offset(-420, 0));
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.currentSector, equals(1));
      expect(reportedSector, equals(1));

      // Drag right by 420 pixels (returns to previous sector)
      await tester.drag(find.byType(IsometricSanctuaryView), const Offset(420, 0));
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.currentSector, equals(0));
    });

    testWidgets('SanctuaryViewController navigates sectors and loops endlessly', (tester) async {
      final sampleTrees = List.generate(
        30,
        (i) => ForestTreeModel(
          id: 'tree_$i',
          species: TreeSpecies.mountainPine,
          stage: 5,
          xRatio: (i / 30.0),
          yRatio: 0.5,
          plantedAt: DateTime.now(),
          subjectName: 'Science',
          chapterName: 'Electricity',
          focusMinutes: 45,
          xpEarned: 120,
          coinsEarned: 30,
        ),
      );

      final controller = SanctuaryViewController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: IsometricSanctuaryView(
                trees: sampleTrees,
                decorations: const [],
                isMoonlit: false,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final totalSectors = controller.totalSectors;
      expect(totalSectors, greaterThanOrEqualTo(3));
      expect(controller.currentSector, equals(0));

      // Animate forward through all sectors
      for (int i = 1; i <= totalSectors; i++) {
        controller.animateToNextSector();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));
        final expected = i % totalSectors;
        expect(controller.currentSector, equals(expected),
            reason: 'Sector should advance modularly to $expected');
      }

      // Loop back via animateToPreviousSector
      controller.animateToPreviousSector();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      expect(controller.currentSector, equals(totalSectors - 1),
          reason: 'Previous from sector 0 loops to last sector');
    });
  });
}
