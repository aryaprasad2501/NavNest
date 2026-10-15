import 'dart:math' as math;

/// Species of cute wildlife roaming the NavBloom sanctuary glades
enum WildlifeType {
  rabbit,
  babyElephant,
  giraffe,
  fawn,
  songbird,
  butterfly,
  redFox,
  wiseOwl,
  chipmunk,
  mossTortoise,
  koiFish,
}

/// A roaming forest animal or soaring bird in the endless sanctuary
class ForestWildlife {
  final String id;
  final WildlifeType type;
  final String name;
  final String quote;
  final String habit;
  final String lore;

  double worldU;
  double worldV;
  double heading; // 1.0 = right, -1.0 = left
  double speed;
  double pacingMinU;
  double pacingMaxU;
  double animPhase;

  DateTime? lastTappedTime;
  int tapCount;
  int friendshipHearts;

  ForestWildlife({
    required this.id,
    required this.type,
    required this.name,
    required this.quote,
    this.habit = 'Consistent Daily Focus',
    this.lore = 'A serene forest creature cheering for your growth in NavBloom.',
    required this.worldU,
    required this.worldV,
    this.heading = 1.0,
    this.speed = 0.012,
    required this.pacingMinU,
    required this.pacingMaxU,
    this.animPhase = 0.0,
    this.tapCount = 0,
    this.friendshipHearts = 1,
  });

  /// Whether the animal is actively reacting to a tap with a cute jump/heart
  bool get isReacting {
    if (lastTappedTime == null) return false;
    final diff = DateTime.now().difference(lastTappedTime!).inMilliseconds;
    return diff < 1800;
  }

  /// 0.0 to 1.0 progress of reaction bounce
  double get reactionProgress {
    if (lastTappedTime == null) return 0.0;
    final ms = DateTime.now().difference(lastTappedTime!).inMilliseconds;
    if (ms >= 1800) return 0.0;
    return ms / 1800.0;
  }

  void triggerTap() {
    lastTappedTime = DateTime.now();
    tapCount++;
    if (friendshipHearts < 5 && tapCount % 3 == 0) {
      friendshipHearts++;
    }
  }

  /// For rabbits: rhythmic hop height
  double get hopDisplacement => math.sin(animPhase * 3.5).abs() * 7.0;

  /// For rabbits: subtle ear twitch
  double get earTwitchAngle => math.sin(animPhase * 4.0) * 0.12;

  /// For elephants: trunk curl / swing
  double get trunkSwingAngle => isReacting
      ? 0.7 + math.sin(reactionProgress * math.pi * 3) * 0.3
      : math.sin(animPhase * 2.2) * 0.28;

  /// For giraffes: gentle neck swaying
  double get neckSway => math.sin(animPhase * 1.6) * 3.5;

  /// For birds: wing flapping cycle (-1.0 to 1.0)
  double get wingFlap => math.sin(animPhase * 8.0);

  /// For butterflies: horizontal wing scale (0.1 to 1.0)
  double get butterflyFlap => (math.cos(animPhase * 12.0).abs() * 0.9 + 0.1).clamp(0.1, 1.0);

  /// For fox: tail wagging angle
  double get foxTailWag => math.sin(animPhase * 3.5) * 0.22;

  /// For owl: head turn and blink
  double get owlHeadTurn => math.sin(animPhase * 1.2);
  bool get isOwlBlinking => (math.sin(animPhase * 2.8) > 0.88);

  /// For chipmunk: rapid tail flick
  double get squirrelTailFlick => math.sin(animPhase * 7.5) * 0.28;

  /// For moss tortoise: gentle flower sway
  double get tortoiseFlowerSway => math.sin(animPhase * 2.0) * 0.15;

  /// For koi fish: body swimming wiggle
  double get koiSwimWiggle => math.sin(animPhase * 3.2) * 4.5;

  /// Update movement and animation cycles
  void update(double dt, int totalSectors) {
    animPhase = (animPhase + dt * (type == WildlifeType.songbird ? 4.5 : 2.0)) % 1000.0;

    if (type == WildlifeType.songbird) {
      // Birds soar steadily across the entire panorama
      worldU = (worldU + speed * dt * heading) % 1.0;
      if (worldU < 0) worldU += 1.0;
      return;
    }

    if (type == WildlifeType.butterfly) {
      // Butterflies flutter gently in small organic figure-eights
      worldU = (worldU + math.sin(animPhase * 1.5) * 0.003 * dt) % 1.0;
      if (worldU < 0) worldU += 1.0;
      return;
    }

    if (type == WildlifeType.wiseOwl) {
      // Owl remains perched observing the glade
      return;
    }

    if (type == WildlifeType.koiFish) {
      // Koi fish swims in gentle circles inside the glade spring
      worldU = (worldU + math.sin(animPhase * 0.8) * 0.001 * dt) % 1.0;
      if (worldU < 0) worldU += 1.0;
      return;
    }

    // Walking / roaming animals pace within their glade sector range
    final moveDelta = speed * dt * heading;
    worldU += moveDelta;

    // Turn around at pacing boundaries
    if (worldU > pacingMaxU) {
      worldU = pacingMaxU;
      heading = -1.0;
    } else if (worldU < pacingMinU) {
      worldU = pacingMinU;
      heading = 1.0;
    }

    // Wrap seamlessly within [0.0, 1.0)
    worldU = (worldU % 1.0 + 1.0) % 1.0;
  }

  /// Streamlined high-performance active storybook wildlife roaming across sanctuary sectors.
  /// Curated to eliminate scrolling stutter and excessive on-screen entity overhead.
  static List<ForestWildlife> createDefaultWildlife() {
    return [
      // 1. Cute Fluffy Bunny in Sector 0 (Whispering Meadow)
      ForestWildlife(
        id: 'wild_bunny_pip',
        type: WildlifeType.rabbit,
        name: 'Pip the Bunny 🐰',
        habit: 'Agile Revision & Flashcards',
        lore: 'A sweet bunny with twitching ears who hops along the wildflowers cheering for your flashcard review streaks.',
        quote: 'Hop to it! You are doing amazing in this study session! 🌿',
        worldU: 0.28,
        worldV: 0.68,
        speed: 0.008,
        pacingMinU: 0.16,
        pacingMaxU: 0.40,
        heading: 1.0,
      ),

      // 2. Cute Baby Elephant in Sector 1 (Sunlit Glade)
      ForestWildlife(
        id: 'wild_elephant_tembo',
        type: WildlifeType.babyElephant,
        name: 'Tembo the Elephant 🐘',
        habit: 'Unshakable Memory Retention',
        lore: 'With floppy ears and a playful curling trunk, Tembo remembers every CBSE formula and key concept.',
        quote: 'Steady steps build mighty memory! Take a calm breath and conquer the next topic. 🌟',
        worldU: 0.58,
        worldV: 0.62,
        speed: 0.005,
        pacingMinU: 0.46,
        pacingMaxU: 0.68,
        heading: -1.0,
      ),

      // 3. Wise Forest Owl perched in Sector 1 (Sunlit Glade)
      ForestWildlife(
        id: 'wild_owl_barnaby',
        type: WildlifeType.wiseOwl,
        name: 'Barnaby the Wise Owl 🦉',
        habit: 'Deep Synthesis & Night Review',
        lore: 'Perched gracefully with luminous golden eyes, Barnaby watches over student study sessions with quiet wisdom.',
        quote: 'Hoo-hoo! Wisdom is built one patient question at a time. Reflect deeply on what you learned today. 🌙',
        worldU: 0.38,
        worldV: 0.36, // Perched gracefully on background ridge
        speed: 0.0,
        pacingMinU: 0.30,
        pacingMaxU: 0.45,
        heading: 1.0,
      ),

      // 4. Golden Koi Fish in Glade Spring Pool (Sector 1) - strictly swimming inside water!
      ForestWildlife(
        id: 'wild_koi_aurelia',
        type: WildlifeType.koiFish,
        name: 'Aurelia the Golden Koi 🐟',
        habit: 'Mental Clarity & Flow State',
        lore: 'Swimming peacefully in the crystal spring pool, Aurelia creates soothing water ripples whenever you enter deep focus.',
        quote: 'Gliding serenely through cool waters. Let stress dissolve and find your effortless study flow. 🌊',
        worldU: 0.52,
        worldV: 0.77,
        speed: 0.003,
        pacingMinU: 0.48,
        pacingMaxU: 0.56,
        heading: 1.0,
      ),

      // 5. Friendly Giraffe in Sector 2 (Emerald Clearing / Wildwood)
      ForestWildlife(
        id: 'wild_giraffe_twiga',
        type: WildlifeType.giraffe,
        name: 'Twiga the Giraffe 🦒',
        habit: 'Long-Term Exam Target Setting',
        lore: 'Tall, graceful, and gentle with soft chestnut spots. Twiga keeps eyes on the highest CBSE board exam goals.',
        quote: 'Aim high! From up here, all your CBSE exam targets look within reach! 🌸',
        worldU: 0.82,
        worldV: 0.52,
        speed: 0.004,
        pacingMinU: 0.74,
        pacingMaxU: 0.92,
        heading: 1.0,
      ),

      // 6. Flying Songbird 1 (Robin) soaring high across the sky
      ForestWildlife(
        id: 'wild_bird_sky_1',
        type: WildlifeType.songbird,
        name: 'Songbird Robin 🐦',
        habit: 'Clarity of Perspective',
        lore: 'Soars high across the sanctuary ridge, singing encouraging melodies on the morning breeze.',
        quote: 'Chirp chirp! High above the canopy, focus songs are singing! 🌤️',
        worldU: 0.10,
        worldV: 0.18, // Mid-sky altitude
        speed: 0.035,
        pacingMinU: 0.0,
        pacingMaxU: 1.0,
        heading: 1.0,
      ),

      // 7. Flying Songbird 2 (Swift) gliding smoothly in upper sky
      ForestWildlife(
        id: 'wild_bird_sky_2',
        type: WildlifeType.songbird,
        name: 'Mountain Swift 🐦',
        habit: 'Swift Understanding & Flow',
        lore: 'Glides effortlessly through high thermals with deep navy wings, cheering your swift progress.',
        quote: 'Soar high above all doubts! The sky is wide open for your achievements! 🌤️',
        worldU: 0.55,
        worldV: 0.05, // High thermals altitude
        speed: 0.042,
        pacingMinU: 0.0,
        pacingMaxU: 1.0,
        heading: 1.0,
      ),

      // 8. Flying Songbird 3 (Finch) gliding east to west
      ForestWildlife(
        id: 'wild_bird_sky_3',
        type: WildlifeType.songbird,
        name: 'Forest Finch 🐦',
        habit: 'Calm Persistence & Joy',
        lore: 'Drifts peacefully across the glade horizon, following the mountain breeze.',
        quote: 'Follow the gentle breeze of curiosity! Keep flying forward towards your dreams! 🍃',
        worldU: 0.88,
        worldV: 0.32, // Lower sky tier above tree line
        speed: 0.026,
        pacingMinU: 0.0,
        pacingMaxU: 1.0,
        heading: -1.0, // Flying opposite direction for organic life
      ),

      // 9. Gentle Forest Fawn roaming the meadow
      ForestWildlife(
        id: 'wild_fawn_kiki',
        type: WildlifeType.fawn,
        name: 'Kiki the Forest Fawn 🦌',
        habit: 'Gentle Grace & Poise',
        lore: 'A graceful spotted fawn roaming through the sun-dappled glades with tender curiosity.',
        quote: 'Graceful focus leads to quiet triumph. Take every step with calm patience! 🌸',
        worldU: 0.18,
        worldV: 0.58,
        speed: 0.006,
        pacingMinU: 0.08,
        pacingMaxU: 0.28,
        heading: 1.0,
      ),

      // 10. Playful Red Fox exploring paths between trees
      ForestWildlife(
        id: 'wild_fox_rusty',
        type: WildlifeType.redFox,
        name: 'Rusty the Clever Fox 🦊',
        habit: 'Curious Problem Solving',
        lore: 'Clever and sharp-witted with a fluffy white-tipped tail, exploring the woodland paths.',
        quote: 'Find clever solutions! Every tricky formula has an elegant pattern. 🌿',
        worldU: 0.44,
        worldV: 0.54,
        speed: 0.007,
        pacingMinU: 0.35,
        pacingMaxU: 0.52,
        heading: -1.0,
      ),

      // 11. Energetic Chipmunk gathering knowledge
      ForestWildlife(
        id: 'wild_chipmunk_pip',
        type: WildlifeType.chipmunk,
        name: 'Chestnut the Chipmunk 🐿️',
        habit: 'Incremental Study Habits',
        lore: 'Spirited and cheerful with a bushy tail, gathering knowledge bit by bit.',
        quote: 'Gather knowledge bit by bit! Today\'s revision is tomorrow\'s exam mastery! 🌰',
        worldU: 0.65,
        worldV: 0.70,
        speed: 0.009,
        pacingMinU: 0.56,
        pacingMaxU: 0.74,
        heading: 1.0,
      ),

      // 12. Peaceful Moss Tortoise
      ForestWildlife(
        id: 'wild_tortoise_shelly',
        type: WildlifeType.mossTortoise,
        name: 'Shelly the Moss Tortoise 🐢',
        habit: 'Unshakable Daily Routine',
        lore: 'Ancient and tranquil with tiny flowering moss on his shell, embodying steady progress.',
        quote: 'Slow and steady wins the race. Daily consistency overcomes every difficult chapter! 🌿',
        worldU: 0.30,
        worldV: 0.75,
        speed: 0.002,
        pacingMinU: 0.22,
        pacingMaxU: 0.38,
        heading: 1.0,
      ),

      // 13. Whimsical Fluttering Butterfly (Azure)
      ForestWildlife(
        id: 'wild_butterfly_azure',
        type: WildlifeType.butterfly,
        name: 'Azure Butterfly 🦋',
        habit: 'Lightness of Spirit',
        lore: 'Flutters gently from flower to flower with sparkling cyan wings, bringing beauty to your study space.',
        quote: 'Fluttering among the blooms! You are growing a magnificent forest! 🌸',
        worldU: 0.34,
        worldV: 0.64,
        speed: 0.002,
        pacingMinU: 0.30,
        pacingMaxU: 0.38,
      ),

      // 14. Golden Monarch Butterfly
      ForestWildlife(
        id: 'wild_butterfly_amber',
        type: WildlifeType.butterfly,
        name: 'Monarch Butterfly 🦋',
        habit: 'Joyful Transformation',
        lore: 'Dances softly in the sunbeams with golden-orange wings, reminding you of how far you have grown.',
        quote: 'Every study hour transforms effort into brilliance! Keep shining! ✨',
        worldU: 0.70,
        worldV: 0.62,
        speed: 0.003,
        pacingMinU: 0.64,
        pacingMaxU: 0.76,
      ),
    ];
  }

  /// Full sanctuary wildlife encyclopedia / codex with all 11 unique companion species.
  static List<ForestWildlife> allCodexSpecies() {
    return [
      // 1. Bunny
      ForestWildlife(
        id: 'codex_bunny_pip',
        type: WildlifeType.rabbit,
        name: 'Pip the Bunny 🐰',
        habit: 'Agile Revision & Flashcards',
        lore: 'A sweet bunny with twitching ears who hops along the wildflowers cheering for your flashcard review streaks.',
        quote: 'Hop to it! You are doing amazing in this study session! 🌿',
        worldU: 0.28,
        worldV: 0.68,
        speed: 0.008,
        pacingMinU: 0.16,
        pacingMaxU: 0.40,
        heading: 1.0,
      ),

      // 2. Red Fox
      ForestWildlife(
        id: 'codex_fox_rory',
        type: WildlifeType.redFox,
        name: 'Rory the Red Fox 🦊',
        habit: 'Active Recall & Problem Solving',
        lore: 'Clever and curious with snowy stockings and a bushy white-tipped brush tail. Rory loves solving tricky equations.',
        quote: 'Think cunningly! Break tough math and physics problems into bite-sized puzzles! 🍁',
        worldU: 0.18,
        worldV: 0.64,
        speed: 0.007,
        pacingMinU: 0.08,
        pacingMaxU: 0.32,
        heading: 1.0,
      ),

      // 3. Baby Elephant
      ForestWildlife(
        id: 'codex_elephant_tembo',
        type: WildlifeType.babyElephant,
        name: 'Tembo the Elephant 🐘',
        habit: 'Unshakable Memory Retention',
        lore: 'With floppy ears and a playful curling trunk, Tembo remembers every CBSE formula and key concept.',
        quote: 'Steady steps build mighty memory! Take a calm breath and conquer the next topic. 🌟',
        worldU: 0.58,
        worldV: 0.62,
        speed: 0.005,
        pacingMinU: 0.46,
        pacingMaxU: 0.68,
        heading: -1.0,
      ),

      // 4. Wise Owl
      ForestWildlife(
        id: 'codex_owl_barnaby',
        type: WildlifeType.wiseOwl,
        name: 'Barnaby the Wise Owl 🦉',
        habit: 'Deep Synthesis & Night Review',
        lore: 'Perched gracefully with luminous golden eyes, Barnaby watches over student study sessions with quiet wisdom.',
        quote: 'Hoo-hoo! Wisdom is built one patient question at a time. Reflect deeply on what you learned today. 🌙',
        worldU: 0.38,
        worldV: 0.36,
        speed: 0.0,
        pacingMinU: 0.30,
        pacingMaxU: 0.45,
        heading: 1.0,
      ),

      // 5. Golden Koi Fish
      ForestWildlife(
        id: 'codex_koi_aurelia',
        type: WildlifeType.koiFish,
        name: 'Aurelia the Golden Koi 🐟',
        habit: 'Mental Clarity & Flow State',
        lore: 'Swimming peacefully in the crystal spring pool, Aurelia creates soothing water ripples whenever you enter deep focus.',
        quote: 'Gliding serenely through cool waters. Let stress dissolve and find your effortless study flow. 🌊',
        worldU: 0.52,
        worldV: 0.77,
        speed: 0.003,
        pacingMinU: 0.48,
        pacingMaxU: 0.56,
        heading: 1.0,
      ),

      // 6. Giraffe
      ForestWildlife(
        id: 'codex_giraffe_twiga',
        type: WildlifeType.giraffe,
        name: 'Twiga the Giraffe 🦒',
        habit: 'Long-Term Exam Target Setting',
        lore: 'Tall, graceful, and gentle with soft chestnut spots. Twiga keeps eyes on the highest CBSE board exam goals.',
        quote: 'Aim high! From up here, all your CBSE exam targets look within reach! 🌸',
        worldU: 0.82,
        worldV: 0.52,
        speed: 0.004,
        pacingMinU: 0.74,
        pacingMaxU: 0.92,
        heading: 1.0,
      ),

      // 7. Chipmunk
      ForestWildlife(
        id: 'codex_chipmunk_pipkin',
        type: WildlifeType.chipmunk,
        name: 'Pipkin the Squirrel 🐿️',
        habit: 'Daily Micro-Habits & Tasks',
        lore: 'Clutching a shiny golden acorn with a bushy flicking tail, Pipkin celebrates every single task completed in your planner.',
        quote: 'Gathering small focus wins builds a giant harvest of knowledge! Every study minute counts! 🌰',
        worldU: 0.68,
        worldV: 0.70,
        speed: 0.010,
        pacingMinU: 0.60,
        pacingMaxU: 0.78,
        heading: -1.0,
      ),

      // 8. Fawn
      ForestWildlife(
        id: 'codex_fawn_bambi',
        type: WildlifeType.fawn,
        name: 'Fable the Fawn 🦌',
        habit: 'Calm Environment & Peace of Mind',
        lore: 'A sweet fawn with Bambi spots and large dark eyes who brings tranquility to quiet revision sessions.',
        quote: 'Quiet focus brings deep roots. Let your knowledge bloom in peace. 🍃',
        worldU: 0.42,
        worldV: 0.58,
        speed: 0.006,
        pacingMinU: 0.32,
        pacingMaxU: 0.52,
        heading: 1.0,
      ),

      // 9. Moss Tortoise
      ForestWildlife(
        id: 'codex_tortoise_shelly',
        type: WildlifeType.mossTortoise,
        name: 'Shelly the Moss Tortoise 🐢',
        habit: 'Patience & Steady Pacing',
        lore: 'Carrying a tiny blooming flower on its mossy shell, Shelly reminds students that steady, calm consistency wins the race.',
        quote: 'Slow, steady, and unhurried. The tallest oak grows without rushing. Keep your calm rhythm. 🌿',
        worldU: 0.88,
        worldV: 0.64,
        speed: 0.002,
        pacingMinU: 0.82,
        pacingMaxU: 0.94,
        heading: -1.0,
      ),

      // 10. Songbird
      ForestWildlife(
        id: 'codex_bird_sky',
        type: WildlifeType.songbird,
        name: 'Songbird Robin 🐦',
        habit: 'Clarity of Perspective',
        lore: 'Soars high across the sanctuary ridge, singing encouraging melodies on the morning breeze.',
        quote: 'Chirp chirp! High above the canopy, focus songs are singing! 🌤️',
        worldU: 0.10,
        worldV: 0.12,
        speed: 0.035,
        pacingMinU: 0.0,
        pacingMaxU: 1.0,
        heading: 1.0,
      ),

      // 11. Butterfly
      ForestWildlife(
        id: 'codex_butterfly_azure',
        type: WildlifeType.butterfly,
        name: 'Azure Butterfly 🦋',
        habit: 'Lightness of Spirit',
        lore: 'Flutters gently from flower to flower with sparkling cyan wings, bringing beauty to your study space.',
        quote: 'Fluttering among the blooms! You are growing a magnificent forest! 🌸',
        worldU: 0.34,
        worldV: 0.64,
        speed: 0.002,
        pacingMinU: 0.30,
        pacingMaxU: 0.38,
      ),
    ];
  }
}
