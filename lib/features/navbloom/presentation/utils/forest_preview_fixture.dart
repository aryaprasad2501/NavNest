import '../../../../core/models/forest_tree_model.dart';

enum ForestPreviewDensity {
  live('Live Sanctuary', 'Your authentic saved trees from study sessions', 0),
  newGrove('New Grove', '4 trees (3–5 early grove)', 4),
  growingGrove('Growing Grove', '12 trees in varied growth stages', 12),
  establishedForest('Established Forest', '30 trees with rich depth & all species', 30),
  denseWoodland('Dense Woodland', '50 trees across the sanctuary glade', 50),
  matureWoodland('Mature Woodland', '80 trees: endgame woodland simulation', 80),
  primevalCanopy('Primeval Canopy', '120 trees: ancient teeming old-growth forest', 120),
  legendaryWildwood('Legendary Wildwood', '160 trees: monumental forest canopy', 160);

  final String title;
  final String description;
  final int treeCount;

  const ForestPreviewDensity(this.title, this.description, this.treeCount);
}

/// In-memory sample tree fixture for visual testing, mature forest simulation,
/// and endgame design verification.
///
/// STRICT GUARANTEE:
/// 1. NEVER writes to SQLite or Room persistence.
/// 2. NEVER awards real user XP, coins, or focus minutes.
/// 3. Fully isolated development tool with clean exit back to live data.
class ForestPreviewFixture {
  /// Generate sample trees based on the chosen preview density.
  /// When [allMature] is true, every tree is transformed to Stage 5 (Full Bloom)
  /// to demonstrate the endgame mature forest visual experience.
  static List<ForestTreeModel> getTreesForDensity(
    ForestPreviewDensity density, {
    bool allMature = false,
  }) {
    List<ForestTreeModel> baseList;
    switch (density) {
      case ForestPreviewDensity.live:
        return const [];
      case ForestPreviewDensity.newGrove:
        baseList = _newGroveTrees;
        break;
      case ForestPreviewDensity.growingGrove:
        baseList = _growingGroveTrees;
        break;
      case ForestPreviewDensity.establishedForest:
        baseList = _establishedForestTrees;
        break;
      case ForestPreviewDensity.denseWoodland:
        baseList = _denseWoodlandTrees;
        break;
      case ForestPreviewDensity.matureWoodland:
        baseList = _matureWoodlandTrees;
        break;
      case ForestPreviewDensity.primevalCanopy:
        baseList = _primevalCanopyTrees;
        break;
      case ForestPreviewDensity.legendaryWildwood:
        baseList = _legendaryWildwoodTrees;
        break;
    }

    if (!allMature) {
      return baseList;
    }

    final now = DateTime.now();
    return baseList.map((t) {
      return ForestTreeModel(
        id: '${t.id}_mature',
        sessionId: t.sessionId,
        species: t.species,
        stage: 5, // Full Bloom
        xRatio: t.xRatio,
        yRatio: t.yRatio,
        plantedAt: t.plantedAt,
        maturedAt: now,
        subjectName: t.subjectName,
        chapterName: t.chapterName,
        focusMinutes: mathMax(t.focusMinutes, 90),
        xpEarned: mathMax(t.xpEarned, 240),
        coinsEarned: mathMax(t.coinsEarned, 70),
        status: 'HEALTHY',
      );
    }).toList();
  }

  static int mathMax(int a, int b) => a > b ? a : b;

  // ─── 1. NEW GROVE (4 Trees: 3–5 early grove) ───
  static final List<ForestTreeModel> _newGroveTrees = [
    ForestTreeModel(
      id: 'prev_new_1',
      species: TreeSpecies.cherryBlossom,
      stage: 2, // Sprout
      xRatio: 0.38,
      yRatio: 0.42,
      plantedAt: DateTime.now().subtract(const Duration(hours: 3)),
      subjectName: 'Mathematics',
      chapterName: 'Real Numbers',
      focusMinutes: 25,
      xpEarned: 65,
      coinsEarned: 18,
      status: 'HEALTHY',
    ),
    ForestTreeModel(
      id: 'prev_new_2',
      species: TreeSpecies.mountainPine,
      stage: 3, // Sapling
      xRatio: 0.65,
      yRatio: 0.46,
      plantedAt: DateTime.now().subtract(const Duration(days: 1)),
      subjectName: 'Science',
      chapterName: 'Light - Reflection',
      focusMinutes: 45,
      xpEarned: 120,
      coinsEarned: 30,
      status: 'HEALTHY',
    ),
    ForestTreeModel(
      id: 'prev_new_3',
      species: TreeSpecies.ancientOak,
      stage: 4, // Young tree
      xRatio: 0.26,
      yRatio: 0.64,
      plantedAt: DateTime.now().subtract(const Duration(days: 3)),
      subjectName: 'Social Science',
      chapterName: 'Rise of Nationalism',
      focusMinutes: 60,
      xpEarned: 160,
      coinsEarned: 45,
      status: 'HEALTHY',
    ),
    ForestTreeModel(
      id: 'prev_new_4',
      species: TreeSpecies.goldenGinkgo,
      stage: 5, // Full bloom
      xRatio: 0.62,
      yRatio: 0.72,
      plantedAt: DateTime.now().subtract(const Duration(days: 5)),
      subjectName: 'English',
      chapterName: 'First Flight',
      focusMinutes: 90,
      xpEarned: 240,
      coinsEarned: 70,
      status: 'HEALTHY',
    ),
  ];

  // ─── 2. GROWING GROVE (12 Trees: 10–15 trees with varied stages & 1 withered) ───
  static final List<ForestTreeModel> _growingGroveTrees = [
    ForestTreeModel(
      id: 'prev_grow_1',
      species: TreeSpecies.mountainPine,
      stage: 3,
      xRatio: 0.28,
      yRatio: 0.28,
      plantedAt: DateTime.now().subtract(const Duration(days: 4)),
      subjectName: 'Physics',
      chapterName: 'Electricity',
      focusMinutes: 40,
      xpEarned: 100,
      coinsEarned: 28,
    ),
    ForestTreeModel(
      id: 'prev_grow_2',
      species: TreeSpecies.cherryBlossom,
      stage: 1, // Seed
      xRatio: 0.50,
      yRatio: 0.25,
      plantedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      subjectName: 'Biology',
      chapterName: 'Life Processes',
      focusMinutes: 15,
      xpEarned: 35,
      coinsEarned: 10,
    ),
    ForestTreeModel(
      id: 'prev_grow_3',
      species: TreeSpecies.riverWillow,
      stage: 4,
      xRatio: 0.72,
      yRatio: 0.30,
      plantedAt: DateTime.now().subtract(const Duration(days: 6)),
      subjectName: 'Chemistry',
      chapterName: 'Chemical Reactions',
      focusMinutes: 65,
      xpEarned: 175,
      coinsEarned: 48,
    ),
    ForestTreeModel(
      id: 'prev_grow_4',
      species: TreeSpecies.ancientOak,
      stage: 5, // Mature
      xRatio: 0.18,
      yRatio: 0.44,
      plantedAt: DateTime.now().subtract(const Duration(days: 10)),
      subjectName: 'Mathematics',
      chapterName: 'Triangles',
      focusMinutes: 90,
      xpEarned: 250,
      coinsEarned: 75,
    ),
    ForestTreeModel(
      id: 'prev_grow_5',
      species: TreeSpecies.cherryBlossom,
      stage: 2, // Sprout
      xRatio: 0.42,
      yRatio: 0.42,
      plantedAt: DateTime.now().subtract(const Duration(hours: 5)),
      subjectName: 'English',
      chapterName: 'A Letter to God',
      focusMinutes: 25,
      xpEarned: 70,
      coinsEarned: 20,
    ),
    ForestTreeModel(
      id: 'prev_grow_6',
      species: TreeSpecies.bonsaiJuniper,
      stage: 5, // Full bloom
      xRatio: 0.76,
      yRatio: 0.45,
      plantedAt: DateTime.now().subtract(const Duration(days: 7)),
      subjectName: 'Economics',
      chapterName: 'Development',
      focusMinutes: 80,
      xpEarned: 220,
      coinsEarned: 60,
    ),
    ForestTreeModel(
      id: 'prev_grow_7',
      species: TreeSpecies.ancientOak,
      stage: 3,
      xRatio: 0.32,
      yRatio: 0.56,
      plantedAt: DateTime.now().subtract(const Duration(days: 2)),
      subjectName: 'History',
      chapterName: 'Nationalism in India',
      focusMinutes: 50,
      xpEarned: 130,
      coinsEarned: 35,
      status: 'WITHERED', // Surrendered focus example
    ),
    ForestTreeModel(
      id: 'prev_grow_8',
      species: TreeSpecies.goldenGinkgo,
      stage: 4,
      xRatio: 0.60,
      yRatio: 0.54,
      plantedAt: DateTime.now().subtract(const Duration(days: 3)),
      subjectName: 'Mathematics',
      chapterName: 'Quadratic Equations',
      focusMinutes: 60,
      xpEarned: 160,
      coinsEarned: 45,
    ),
    ForestTreeModel(
      id: 'prev_grow_9',
      species: TreeSpecies.mountainPine,
      stage: 5,
      xRatio: 0.22,
      yRatio: 0.72,
      plantedAt: DateTime.now().subtract(const Duration(days: 8)),
      subjectName: 'Science',
      chapterName: 'Magnetic Effects',
      focusMinutes: 90,
      xpEarned: 240,
      coinsEarned: 70,
    ),
    ForestTreeModel(
      id: 'prev_grow_10',
      species: TreeSpecies.cherryBlossom,
      stage: 5,
      xRatio: 0.48,
      yRatio: 0.68,
      plantedAt: DateTime.now().subtract(const Duration(days: 5)),
      subjectName: 'Mathematics',
      chapterName: 'Trigonometry',
      focusMinutes: 85,
      xpEarned: 230,
      coinsEarned: 65,
    ),
    ForestTreeModel(
      id: 'prev_grow_11',
      species: TreeSpecies.riverWillow,
      stage: 3,
      xRatio: 0.74,
      yRatio: 0.66,
      plantedAt: DateTime.now().subtract(const Duration(days: 2)),
      subjectName: 'Geography',
      chapterName: 'Water Resources',
      focusMinutes: 45,
      xpEarned: 115,
      coinsEarned: 30,
    ),
    ForestTreeModel(
      id: 'prev_grow_12',
      species: TreeSpecies.bonsaiJuniper,
      stage: 4,
      xRatio: 0.40,
      yRatio: 0.82,
      plantedAt: DateTime.now().subtract(const Duration(days: 4)),
      subjectName: 'Civics',
      chapterName: 'Power Sharing',
      focusMinutes: 60,
      xpEarned: 160,
      coinsEarned: 45,
    ),
  ];

  // ─── 3. ESTABLISHED FOREST (30 Trees: 25–35 trees with diverse botanical species) ───
  static final List<ForestTreeModel> _establishedForestTrees = _buildTreeSet(
    count: 30,
    prefix: 'est',
    speciesCycle: TreeSpecies.values,
    stageCycle: [4, 5, 3, 5, 2, 5, 4, 3, 5, 1, 5, 4],
    witheredIndices: [14],
  );

  // ─── 4. DENSE WOODLAND (50 Trees across the sanctuary) ───
  static final List<ForestTreeModel> _denseWoodlandTrees = _buildTreeSet(
    count: 50,
    prefix: 'dense',
    speciesCycle: TreeSpecies.values,
    stageCycle: [5, 4, 5, 3, 5, 4, 2, 5, 5, 3, 4, 5, 1, 5, 4],
    witheredIndices: [11, 37],
  );

  // ─── 5. MATURE WOODLAND (80 Trees: 75–100 trees endgame simulation) ───
  static final List<ForestTreeModel> _matureWoodlandTrees = _buildTreeSet(
    count: 80,
    prefix: 'mature',
    speciesCycle: TreeSpecies.values,
    stageCycle: [5, 5, 4, 5, 5, 3, 5, 4, 5, 5, 4, 2, 5, 5],
    witheredIndices: [22, 59],
  );

  // ─── 6. PRIMEVAL CANOPY (120 Trees: ancient teeming old-growth forest) ───
  static final List<ForestTreeModel> _primevalCanopyTrees = _buildTreeSet(
    count: 120,
    prefix: 'primeval',
    speciesCycle: TreeSpecies.values,
    stageCycle: [5, 5, 5, 4, 5, 5, 3, 5, 5, 4, 5, 5, 2, 5, 5],
    witheredIndices: [18, 49, 92],
  );

  // ─── 7. LEGENDARY WILDWOOD (160 Trees: monumental forest canopy) ───
  static final List<ForestTreeModel> _legendaryWildwoodTrees = _buildTreeSet(
    count: 160,
    prefix: 'wildwood',
    speciesCycle: TreeSpecies.values,
    stageCycle: [5, 5, 5, 5, 4, 5, 5, 5, 3, 5, 5, 4, 5, 5, 2, 5],
    witheredIndices: [24, 71, 118, 145],
  );

  /// Deterministic generator distributing trees across 6 natural depth tiers
  /// guaranteeing collision-free coordinates and realistic CBSE study metadata.
  static List<ForestTreeModel> _buildTreeSet({
    required int count,
    required String prefix,
    required List<TreeSpecies> speciesCycle,
    required List<int> stageCycle,
    required List<int> witheredIndices,
  }) {
    final list = <ForestTreeModel>[];

    // 6 Depth Tiers (from far horizon v=0.22 to near foreground v=0.82)
    final tiers = [
      {'v': 0.22, 'count': (count * 0.14).round()}, // Far horizon
      {'v': 0.34, 'count': (count * 0.17).round()}, // Mid-upper
      {'v': 0.46, 'count': (count * 0.20).round()}, // Upper-mid
      {'v': 0.58, 'count': (count * 0.20).round()}, // Lower-mid
      {'v': 0.70, 'count': (count * 0.17).round()}, // Foreground glade
      {'v': 0.82, 'count': (count * 0.12).round()}, // Near anchor
    ];

    // Ensure sum matches count exactly
    int totalAssigned = 0;
    for (final t in tiers) {
      totalAssigned += (t['count'] as int);
    }
    if (totalAssigned != count) {
      tiers[2]['count'] = (tiers[2]['count'] as int) + (count - totalAssigned);
    }

    const cbseTopics = [
      {'sub': 'Mathematics', 'ch': 'Trigonometry', 'mins': 60},
      {'sub': 'Science', 'ch': 'Chemical Reactions', 'mins': 45},
      {'sub': 'Social Science', 'ch': 'Nationalism in India', 'mins': 60},
      {'sub': 'Physics', 'ch': 'Electricity & Circuits', 'mins': 75},
      {'sub': 'Biology', 'ch': 'Life Processes', 'mins': 90},
      {'sub': 'Chemistry', 'ch': 'Carbon & Its Compounds', 'mins': 50},
      {'sub': 'Mathematics', 'ch': 'Quadratic Equations', 'mins': 80},
      {'sub': 'English', 'ch': 'First Flight', 'mins': 40},
      {'sub': 'Economics', 'ch': 'Money & Credit', 'mins': 55},
      {'sub': 'Geography', 'ch': 'Water Resources', 'mins': 45},
      {'sub': 'Civics', 'ch': 'Federalism', 'mins': 50},
      {'sub': 'Mathematics', 'ch': 'Surface Areas & Volumes', 'mins': 90},
    ];

    int globalIndex = 0;

    for (int tIdx = 0; tIdx < tiers.length; tIdx++) {
      final tier = tiers[tIdx];
      final baseV = tier['v'] as double;
      final tierCount = tier['count'] as int;

      if (tierCount <= 0) continue;

      // Calculate width of glade at this depth
      final minU = (0.24 - (baseV - 0.22) * 0.14).clamp(0.12, 0.35);
      final maxU = (0.76 + (baseV - 0.22) * 0.14).clamp(0.65, 0.88);
      final stepU = (maxU - minU) / (tierCount > 1 ? (tierCount - 1) : 1);

      for (int i = 0; i < tierCount; i++) {
        final species = speciesCycle[globalIndex % speciesCycle.length];
        final stage = stageCycle[globalIndex % stageCycle.length];
        final isWithered = witheredIndices.contains(globalIndex);
        final topic = cbseTopics[globalIndex % cbseTopics.length];

        // S-curve stagger to avoid rigid rows
        final vStagger = ((i % 3) - 1.0) * 0.024;
        final uJitter = ((i % 2 == 0 ? 1 : -1) * 0.008);

        final u = (minU + i * stepU + uJitter).clamp(0.10, 0.90);
        final v = (baseV + vStagger).clamp(0.18, 0.86);

        final focusMins = topic['mins'] as int;
        final xp = focusMins * 2 + (stage >= 5 ? 60 : 25);
        final coins = (focusMins * 0.5).round() + (stage >= 5 ? 20 : 5);

        list.add(ForestTreeModel(
          id: '${prefix}_tree_${globalIndex + 1}',
          species: species,
          stage: isWithered ? 1 : stage,
          xRatio: double.parse(u.toStringAsFixed(3)),
          yRatio: double.parse(v.toStringAsFixed(3)),
          plantedAt: DateTime.now().subtract(Duration(days: (count - globalIndex))),
          maturedAt: stage >= 5 ? DateTime.now().subtract(Duration(days: (count - globalIndex) ~/ 2)) : null,
          subjectName: topic['sub'] as String,
          chapterName: topic['ch'] as String,
          focusMinutes: focusMins,
          xpEarned: isWithered ? 0 : xp,
          coinsEarned: isWithered ? 0 : coins,
          status: isWithered ? 'WITHERED' : 'HEALTHY',
        ));

        globalIndex++;
      }
    }

    return list;
  }
}
