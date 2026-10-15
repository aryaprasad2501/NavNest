import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/features/navbloom/presentation/widgets/interactive_tree_3d_viewer.dart';

void main() {
  group('Interactive 3D Tree Mathematical Pipeline Tests', () {
    test('Vector3D arithmetic and vector operations work accurately', () {
      const v1 = Vector3D(1.0, 2.0, 3.0);
      const v2 = Vector3D(4.0, 5.0, 6.0);

      // Addition & Subtraction
      final sum = v1 + v2;
      expect(sum.x, equals(5.0));
      expect(sum.y, equals(7.0));
      expect(sum.z, equals(9.0));

      final diff = v2 - v1;
      expect(diff.x, equals(3.0));
      expect(diff.y, equals(3.0));
      expect(diff.z, equals(3.0));

      // Scalar multiplication
      final scaled = v1 * 2.0;
      expect(scaled.x, equals(2.0));
      expect(scaled.y, equals(4.0));
      expect(scaled.z, equals(6.0));

      // Dot product: v1 . v2 = 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
      expect(v1.dot(v2), equals(32.0));

      // Orthogonal vectors dot product is 0
      const unitX = Vector3D(1.0, 0.0, 0.0);
      const unitY = Vector3D(0.0, 1.0, 0.0);
      expect(unitX.dot(unitY), equals(0.0));

      // Cross product: X cross Y = Z
      final crossZ = unitX.cross(unitY);
      expect(crossZ.x, closeTo(0.0, 1e-6));
      expect(crossZ.y, closeTo(0.0, 1e-6));
      expect(crossZ.z, closeTo(1.0, 1e-6));

      // Length and Normalization
      const v3 = Vector3D(0.0, 3.0, 4.0);
      expect(v3.length, closeTo(5.0, 1e-6));

      final normalized = v3.normalized();
      expect(normalized.length, closeTo(1.0, 1e-6));
      expect(normalized.y, closeTo(0.6, 1e-6));
      expect(normalized.z, closeTo(0.8, 1e-6));
    });

    test('Vector3D rotations around X, Y, Z axes preserve vector magnitude', () {
      const v = Vector3D(10.0, 0.0, 0.0);

      // Rotate around Y by 90 degrees (pi/2) -> should land at (0, 0, -10)
      final rotY = v.rotateY(math.pi / 2);
      expect(rotY.x, closeTo(0.0, 1e-6));
      expect(rotY.y, closeTo(0.0, 1e-6));
      expect(rotY.z, closeTo(-10.0, 1e-6));
      expect(rotY.length, closeTo(v.length, 1e-6));

      // Rotate around X by 90 degrees of (0, 10, 0) -> lands at (0, 0, 10)
      const vY = Vector3D(0.0, 10.0, 0.0);
      final rotX = vY.rotateX(math.pi / 2);
      expect(rotX.x, closeTo(0.0, 1e-6));
      expect(rotX.y, closeTo(0.0, 1e-6));
      expect(rotX.z, closeTo(10.0, 1e-6));
      expect(rotX.length, closeTo(vY.length, 1e-6));

      // Rotate around Z by 90 degrees
      final rotZ = v.rotateZ(math.pi / 2);
      expect(rotZ.x, closeTo(0.0, 1e-6));
      expect(rotZ.y, closeTo(10.0, 1e-6));
      expect(rotZ.z, closeTo(0.0, 1e-6));
    });

    test('PolygonFace3D automatically calculates outward normal and center depth', () {
      final face = PolygonFace3D(
        [
          const Vector3D(0.0, 0.0, 0.0),
          const Vector3D(10.0, 0.0, 0.0),
          const Vector3D(10.0, 10.0, 0.0),
          const Vector3D(0.0, 10.0, 0.0),
        ],
        Colors.green,
      );

      // Normal for XY plane quad pointing towards +Z
      expect(face.normal.x, closeTo(0.0, 1e-6));
      expect(face.normal.y, closeTo(0.0, 1e-6));
      expect(face.normal.z, closeTo(1.0, 1e-6));

      // Center Z
      expect(face.centerZ, equals(0.0));
    });

    test('Tree3DGeometryGenerator produces valid 3D meshes for all 15 species across all 5 stages', () {
      for (final species in TreeSpecies.values) {
        for (int stage = 1; stage <= 5; stage++) {
          final mesh = Tree3DGeometryGenerator.generateTree(
            species: species,
            stage: stage,
            isDark: false,
          );

          expect(mesh.faces, isNotEmpty, reason: '$species Stage $stage must produce faces');
          expect(mesh.faces.length, greaterThan(12), reason: '$species Stage $stage must include pedestal and foliage');

          // Ensure every face has valid non-empty vertices with proper coordinates
          for (final face in mesh.faces) {
            expect(face.vertices.length, greaterThanOrEqualTo(3));
            for (final v in face.vertices) {
              expect(v.x.isNaN, isFalse);
              expect(v.y.isNaN, isFalse);
              expect(v.z.isNaN, isFalse);
            }
          }
        }
      }
    });

    test('Growth stage progression increases 3D structural complexity (Stage 5 > Stage 1)', () {
      const species = TreeSpecies.cherryBlossom;

      final stage1 = Tree3DGeometryGenerator.generateTree(species: species, stage: 1, isDark: false);
      final stage3 = Tree3DGeometryGenerator.generateTree(species: species, stage: 3, isDark: false);
      final stage5 = Tree3DGeometryGenerator.generateTree(species: species, stage: 5, isDark: false);

      expect(stage1.faces.length, lessThan(stage3.faces.length));
      expect(stage3.faces.length, lessThan(stage5.faces.length));
    });
  });

  group('InteractiveTree3DViewer Widget Interaction Tests', () {
    testWidgets('Renders 3D viewer, 360 degree badge, controls, and stage selectors', (tester) async {
      int selectedStage = 5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveTree3DViewer(
              species: TreeSpecies.ancientOak,
              initialStage: 5,
              height: 340,
              showStageSelector: true,
              onStageChanged: (newStage) {
                selectedStage = newStage;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Check header badge
      expect(find.text('360° Real 3D View'), findsOneWidget);
      expect(find.byIcon(Icons.threed_rotation_rounded), findsOneWidget);

      // Check control icons
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Check stage pills
      expect(find.text('Seed 🌱'), findsOneWidget);
      expect(find.text('Sprout 🌿'), findsOneWidget);
      expect(find.text('Sapling 🪴'), findsOneWidget);
      expect(find.text('Young 🌳'), findsOneWidget);
      expect(find.text('Bloom 🌸'), findsOneWidget);

      // Tap 'Seed 🌱' pill
      await tester.tap(find.text('Seed 🌱'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(selectedStage, equals(1));

      // Tap 'Young 🌳' pill
      await tester.tap(find.text('Young 🌳'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(selectedStage, equals(4));

      // Tap Pause rotation
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Tap Reset View
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });
  });
}
