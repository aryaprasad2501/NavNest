import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/features/navbloom/presentation/models/forest_wildlife.dart';
import 'package:navnest/features/navbloom/presentation/widgets/isometric_forest_painter.dart';

void main() {
  group('ForestWildlife Roaming & Species Tests', () {
    test('Codex roster contains all requested species (rabbit, elephant, giraffe, birds, etc.)', () {
      final roster = ForestWildlife.allCodexSpecies();

      expect(roster.isNotEmpty, isTrue);

      final hasRabbit = roster.any((w) => w.type == WildlifeType.rabbit);
      final hasElephant = roster.any((w) => w.type == WildlifeType.babyElephant);
      final hasGiraffe = roster.any((w) => w.type == WildlifeType.giraffe);
      final hasFawn = roster.any((w) => w.type == WildlifeType.fawn);
      final hasSongbird = roster.any((w) => w.type == WildlifeType.songbird);
      final hasButterfly = roster.any((w) => w.type == WildlifeType.butterfly);
      final hasRedFox = roster.any((w) => w.type == WildlifeType.redFox);
      final hasWiseOwl = roster.any((w) => w.type == WildlifeType.wiseOwl);
      final hasChipmunk = roster.any((w) => w.type == WildlifeType.chipmunk);
      final hasMossTortoise = roster.any((w) => w.type == WildlifeType.mossTortoise);
      final hasKoiFish = roster.any((w) => w.type == WildlifeType.koiFish);

      expect(hasRabbit, isTrue, reason: 'Must have cute fluffy rabbit');
      expect(hasElephant, isTrue, reason: 'Must have cute baby elephant');
      expect(hasGiraffe, isTrue, reason: 'Must have friendly giraffe');
      expect(hasFawn, isTrue, reason: 'Must have gentle forest fawn');
      expect(hasSongbird, isTrue, reason: 'Must have random soaring sky birds');
      expect(hasButterfly, isTrue, reason: 'Must have fluttering colorful butterflies');
      expect(hasRedFox, isTrue, reason: 'Must have clever red fox');
      expect(hasWiseOwl, isTrue, reason: 'Must have wise perched owl');
      expect(hasChipmunk, isTrue, reason: 'Must have busy chipmunk clutching acorn');
      expect(hasMossTortoise, isTrue, reason: 'Must have moss tortoise with flower');
      expect(hasKoiFish, isTrue, reason: 'Must have golden koi in glade spring');
    });

    test('Active glade roster contains diverse roaming companions and multiple sky birds', () {
      final active = ForestWildlife.createDefaultWildlife();
      expect(active.length, greaterThanOrEqualTo(12));
      expect(active.any((w) => w.type == WildlifeType.rabbit), isTrue);
      expect(active.any((w) => w.type == WildlifeType.babyElephant), isTrue);
      expect(active.any((w) => w.type == WildlifeType.giraffe), isTrue);
      expect(active.any((w) => w.type == WildlifeType.fawn), isTrue);
      expect(active.any((w) => w.type == WildlifeType.redFox), isTrue);
      expect(active.any((w) => w.type == WildlifeType.chipmunk), isTrue);
      expect(active.any((w) => w.type == WildlifeType.mossTortoise), isTrue);
      expect(active.any((w) => w.type == WildlifeType.wiseOwl), isTrue);
      expect(active.any((w) => w.type == WildlifeType.koiFish), isTrue);
      expect(active.where((w) => w.type == WildlifeType.songbird).length, greaterThanOrEqualTo(2));
      expect(active.any((w) => w.type == WildlifeType.butterfly), isTrue);
    });

    test('Rabbit paces within boundaries and reverses heading at bounds', () {
      final bunny = ForestWildlife(
        id: 'test_bunny',
        type: WildlifeType.rabbit,
        name: 'Pip',
        quote: 'Hop to it!',
        worldU: 0.39,
        worldV: 0.65,
        speed: 0.1,
        pacingMinU: 0.2,
        pacingMaxU: 0.4,
        heading: 1.0,
      );

      expect(bunny.heading, equals(1.0));

      // Update forward past pacingMaxU
      bunny.update(0.2, 4);

      // Should hit max pacing boundary and reverse heading
      expect(bunny.heading, equals(-1.0));
      expect(bunny.worldU, lessThanOrEqualTo(0.40));
    });

    test('Songbirds soar steadily and wrap across panorama', () {
      final bird = ForestWildlife(
        id: 'test_bird',
        type: WildlifeType.songbird,
        name: 'Robin',
        quote: 'Chirp chirp!',
        worldU: 0.98,
        worldV: 0.15,
        speed: 0.1,
        pacingMinU: 0.0,
        pacingMaxU: 1.0,
        heading: 1.0,
      );

      // Advance bird past 1.0
      bird.update(0.5, 4);

      // Should seamlessly wrap within [0.0, 1.0)
      expect(bird.worldU, greaterThanOrEqualTo(0.0));
      expect(bird.worldU, lessThan(1.0));
    });

    test('Interactive tapping triggers reaction bounce, quote cheer, and increases friendship', () {
      final elephant = ForestWildlife(
        id: 'test_tembo',
        type: WildlifeType.babyElephant,
        name: 'Tembo the Elephant',
        quote: 'Steady steps build mighty memory!',
        worldU: 0.5,
        worldV: 0.6,
        pacingMinU: 0.4,
        pacingMaxU: 0.7,
        friendshipHearts: 1,
      );

      expect(elephant.isReacting, isFalse);
      expect(elephant.tapCount, equals(0));
      expect(elephant.friendshipHearts, equals(1));

      // User taps elephant 3 times
      elephant.triggerTap();
      expect(elephant.isReacting, isTrue);
      expect(elephant.tapCount, equals(1));

      elephant.triggerTap();
      elephant.triggerTap();
      expect(elephant.tapCount, equals(3));
      // Every 3 taps increases friendship hearts up to 5
      expect(elephant.friendshipHearts, equals(2));
      expect(elephant.reactionProgress, greaterThanOrEqualTo(0.0));
      expect(elephant.reactionProgress, lessThanOrEqualTo(1.0));
      expect(elephant.trunkSwingAngle, isNotNull);
    });

    test('Animation getters compute valid cycles for all species without exceptions', () {
      final fox = ForestWildlife(
        id: 'test_fox',
        type: WildlifeType.redFox,
        name: 'Rory',
        quote: 'Think cunningly!',
        worldU: 0.18,
        worldV: 0.64,
        pacingMinU: 0.1,
        pacingMaxU: 0.3,
      );

      fox.animPhase = 2.5;

      expect(fox.foxTailWag, inInclusiveRange(-0.3, 0.3));
      expect(fox.owlHeadTurn, inInclusiveRange(-1.0, 1.0));
      expect(fox.squirrelTailFlick, inInclusiveRange(-0.35, 0.35));
      expect(fox.tortoiseFlowerSway, inInclusiveRange(-0.2, 0.2));
      expect(fox.koiSwimWiggle, inInclusiveRange(-5.0, 5.0));
      expect(fox.isOwlBlinking, isA<bool>());
    });
  });

  group('IsometricSanctuaryView Wildlife Integration Widget Test', () {
    testWidgets('Renders sanctuary with wildlife and handles touch interaction', (tester) async {
      ForestWildlife? tappedAnimal;

      final testBunny = ForestWildlife(
        id: 'tap_bunny',
        type: WildlifeType.rabbit,
        name: 'Test Bunny 🐰',
        quote: 'You did it!',
        worldU: 0.5,
        worldV: 0.5,
        pacingMinU: 0.4,
        pacingMaxU: 0.6,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: IsometricSanctuaryView(
                trees: [
                  ForestTreeModel(
                    id: 'tree_1',
                    species: TreeSpecies.ancientOak,
                    stage: 3,
                    xRatio: 0.2,
                    yRatio: 0.2,
                    plantedAt: DateTime(2026, 1, 1),
                    subjectName: 'Biology',
                    chapterName: 'Life Processes',
                    focusMinutes: 45,
                    xpEarned: 120,
                    coinsEarned: 25,
                  ),
                ],
                decorations: const [],
                wildlife: [testBunny],
                isMoonlit: false,
                onWildlifeTap: (animal) {
                  tappedAnimal = animal;
                },
              ),
            ),
          ),
        ),
      );

      // Verify widget builds without error
      expect(find.byType(IsometricSanctuaryView), findsOneWidget);

      // Pump 10 frames of animation to verify smooth physics
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 32));
      }

      // Tap the center of the viewport where the bunny is placed
      await tester.tapAt(const Offset(200, 300));
      await tester.pump();

      // Verify that tap callback was received or triggered
      expect(testBunny.isReacting, isTrue);
      expect(tappedAnimal?.id, equals('tap_bunny'));
    });
  });
}
