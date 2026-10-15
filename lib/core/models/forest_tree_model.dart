import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TreeSpecies {
  cherryBlossom(
    'Cherry Blossom',
    AppColors.cherryPink,
    '🌸',
    botanicalName: 'Prunus serrulata',
    assetPrefix: 'cherry_blossom',
    lore: 'Ephemeral blossoms of enduring patience, inspiring deep mindfulness and serenity.',
  ),
  mountainPine(
    'Mountain Pine',
    AppColors.sageGreen,
    '🌲',
    botanicalName: 'Pinus mugo',
    assetPrefix: 'mountain_pine',
    lore: 'A resilient alpine evergreen rooted deep against steep winds and rugged terrain.',
  ),
  ancientOak(
    'Ancient Oak',
    AppColors.deepForest,
    '🌳',
    botanicalName: 'Quercus robur',
    assetPrefix: 'ancient_oak',
    lore: 'Centuries of steadfast wisdom sheltering a quiet, unshakable sanctuary of study.',
  ),
  riverWillow(
    'River Willow',
    AppColors.forestEmerald,
    '🌿',
    botanicalName: 'Salix babylonica',
    assetPrefix: 'river_willow',
    lore: 'Graceful emerald cascades swaying gently beside reflective sanctuary waters.',
  ),
  goldenGinkgo(
    'Golden Ginkgo',
    AppColors.amberWarm,
    '🍂',
    botanicalName: 'Ginkgo biloba',
    assetPrefix: 'golden_ginkgo',
    lore: 'A prehistoric living jewel bearing radiant fan-shaped leaves of luminous focus.',
  ),
  bonsaiJuniper(
    'Bonsai Juniper',
    AppColors.sageLight,
    '🪴',
    botanicalName: 'Juniperus chinensis',
    assetPrefix: 'bonsai_juniper',
    lore: 'A disciplined miniature masterwork sculpted through daily focus and patience.',
    unlockRequirement: 'Maintain a 7-day focus streak',
    unlockLevel: 4,
    tier: 'Specialist',
  ),
  japaneseCedar(
    'Japanese Cedar',
    Color(0xFF1B5E20),
    '🌲',
    botanicalName: 'Cryptomeria japonica',
    assetPrefix: 'japanese_cedar',
    lore: 'A revered coniferous giant soaring high, renowned for straight fragrant timber and mountain resilience.',
    unlockRequirement: 'Grow 25 sanctuary trees (Established Forest)',
    unlockLevel: 5,
    tier: 'Ancient',
  ),
  jacaranda(
    'Jacaranda',
    Color(0xFF7E57C2),
    '🪻',
    botanicalName: 'Jacaranda mimosifolia',
    assetPrefix: 'jacaranda',
    lore: 'A majestic cloud of lavender-indigo blooms celebrated worldwide as a symbol of academic inspiration and scholarship.',
    unlockRequirement: 'Complete 40 focus sessions (CBSE Exam Sprint)',
    unlockLevel: 7,
    tier: 'Exotic',
  ),
  bambooGrove(
    'Bamboo Grove',
    Color(0xFF43A047),
    '🎋',
    botanicalName: 'Phyllostachys edulis',
    assetPrefix: 'bamboo_grove',
    lore: 'Resilient culms swaying in unison, exemplifying inner strength, rapid growth, and flexible adaptability.',
    unlockRequirement: 'Bloom 50 mature trees (Master Botanist)',
    unlockLevel: 10,
    tier: 'Prestige',
  ),
  giantSequoia(
    'Giant Sequoia',
    Color(0xFF8D4004),
    '🌲',
    botanicalName: 'Sequoiadendron giganteum',
    assetPrefix: 'giant_sequoia',
    lore: 'An ancient cinnamon-barked colossus towering into the clouds, representing timeless endurance and monumental study sessions.',
    unlockRequirement: 'Plant 40 sanctuary trees or reach Level 12',
    unlockLevel: 12,
    tier: 'Ancient Titan',
  ),
  sacredBanyan(
    'Sacred Banyan',
    Color(0xFF2E7D32),
    '🌳',
    botanicalName: 'Ficus benghalensis',
    assetPrefix: 'sacred_banyan',
    lore: 'The eternal national tree of India, dropping aerial prop roots to form an expansive sheltering canopy of communal wisdom.',
    unlockRequirement: 'Complete 30 CBSE focus milestones',
    unlockLevel: 15,
    tier: 'Sacred Heritage',
  ),
  silverBirch(
    'Silver Birch',
    Color(0xFF7CB342),
    '⚪',
    botanicalName: 'Betula pendula',
    assetPrefix: 'silver_birch',
    lore: 'A graceful pioneer tree with luminous chalk-white peeling bark and delicate dancing triangular leaves.',
    unlockRequirement: 'Starter woodland species (Unlocked at Level 2)',
    unlockLevel: 2,
    tier: 'Woodland',
  ),
  flameOfForest(
    'Flame of the Forest',
    Color(0xFFFF5722),
    '🔥',
    botanicalName: 'Butea monosperma',
    assetPrefix: 'flame_of_forest',
    lore: 'The sacred Palash tree, bursting into a fiery canopy of scarlet-orange keeled flowers celebrating springtime triumph.',
    unlockRequirement: 'Complete 15 exam sprint sessions',
    unlockLevel: 8,
    tier: 'Exotic Bloom',
  ),
  weepingWisteria(
    'Weeping Wisteria',
    Color(0xFF9C27B0),
    '🪻',
    botanicalName: 'Wisteria sinensis',
    assetPrefix: 'weeping_wisteria',
    lore: 'A breathtaking cascade of pendulous purple flower clusters draping like living amethyst rain in the spring breeze.',
    unlockRequirement: 'Maintain a 14-day study streak',
    unlockLevel: 14,
    tier: 'Specialist',
  ),
  ancientBaobab(
    'Ancient Baobab',
    Color(0xFF795548),
    '🪵',
    botanicalName: 'Adansonia digitata',
    assetPrefix: 'ancient_baobab',
    lore: 'The iconic African Tree of Life, with a massive water-storing bottle trunk and root-like branches crowned under the stars.',
    unlockRequirement: 'Plant 60 total sanctuary trees',
    unlockLevel: 18,
    tier: 'Prestige Mythic',
  );

  final String displayName;
  final Color themeColor;
  final String iconEmoji;
  final String botanicalName;
  final String assetPrefix;
  final String lore;
  final String unlockRequirement;
  final int unlockLevel;
  final String tier;

  const TreeSpecies(
    this.displayName,
    this.themeColor,
    this.iconEmoji, {
    required this.botanicalName,
    required this.assetPrefix,
    required this.lore,
    this.unlockRequirement = 'Starter species (Unlocked by default)',
    this.unlockLevel = 1,
    this.tier = 'Starter',
  });

  /// Path to individual stage sprite asset (prepared for future high-res drops)
  String getAssetPath(int stage, {bool isWithered = false}) {
    if (isWithered) {
      return 'assets/trees/${assetPrefix}_withered.png';
    }
    final clampedStage = stage.clamp(1, 5);
    return 'assets/trees/${assetPrefix}_stage_$clampedStage.png';
  }

  /// Path to full bloom stage 5 sprite
  String getMatureAssetPath() => 'assets/trees/${assetPrefix}_stage_5.png';

  /// Path to withered dead sprite
  String getWitheredAssetPath() => 'assets/trees/${assetPrefix}_withered.png';

  static TreeSpecies fromString(String val) {
    return TreeSpecies.values.firstWhere(
      (s) => s.displayName.toLowerCase() == val.toLowerCase() || s.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TreeSpecies.mountainPine,
    );
  }
}

class ForestTreeModel {
  final String id;
  final String? sessionId;
  final TreeSpecies species;
  final int stage; // 1: Seed, 2: Sprout, 3: Sapling, 4: Young Tree, 5: Full Bloom
  final double xRatio; // 0.0 to 1.0 (Canvas X placement)
  final double yRatio; // 0.0 to 1.0 (Canvas Y placement)
  final DateTime plantedAt;
  final DateTime? maturedAt;
  final String subjectName;
  final String chapterName;
  final int focusMinutes;
  final int xpEarned;
  final int coinsEarned;
  final String status; // 'GROWING', 'HEALTHY', 'WITHERED'
  final bool isShared;

  const ForestTreeModel({
    required this.id,
    this.sessionId,
    required this.species,
    required this.stage,
    required this.xRatio,
    required this.yRatio,
    required this.plantedAt,
    this.maturedAt,
    required this.subjectName,
    required this.chapterName,
    required this.focusMinutes,
    required this.xpEarned,
    required this.coinsEarned,
    this.status = 'HEALTHY',
    this.isShared = false,
  });

  String get stageName {
    switch (stage) {
      case 1:
        return 'Stage 1: Seed';
      case 2:
        return 'Stage 2: Sprout';
      case 3:
        return 'Stage 3: Sapling';
      case 4:
        return 'Stage 4: Young Tree';
      case 5:
      default:
        return 'Stage 5: Full Bloom';
    }
  }

  bool get isMatured => stage >= 5;
  bool get isMature => isMatured;
  bool get isWithered => status == 'WITHERED';
  bool get isHealthy => status != 'WITHERED';

  String get botanicalName => species.botanicalName;
  String get lore => species.lore;
  String get assetPath => species.getAssetPath(stage, isWithered: isWithered);
  String get matureAssetPath => species.getMatureAssetPath();
  String get witheredAssetPath => species.getWitheredAssetPath();

  String get stageDescription {
    switch (stage) {
      case 1:
        return 'Seed resting in fertile sanctuary soil';
      case 2:
        return 'Sprouted fresh emerald cotyledon leaves';
      case 3:
        return 'Growing hardy sapling with tender branches';
      case 4:
        return 'Robust young tree with flourishing canopy';
      case 5:
      default:
        return 'Full Bloom majestic sanctuary landmark';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'treeType': species.displayName,
      'stage': stage,
      'xRatio': xRatio,
      'yRatio': yRatio,
      'gridX': (xRatio * 100).toInt(),
      'gridY': (yRatio * 100).toInt(),
      'plantedAt': plantedAt.toIso8601String(),
      'maturedAt': maturedAt?.toIso8601String(),
      'subjectName': subjectName,
      'chapterName': chapterName,
      'focusMinutes': focusMinutes,
      'xpEarned': xpEarned,
      'coinsEarned': coinsEarned,
      'status': status,
      'isShared': isShared ? 1 : 0,
    };
  }

  factory ForestTreeModel.fromMap(Map<String, dynamic> map) {
    return ForestTreeModel(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String?,
      species: TreeSpecies.fromString(map['treeType'] as String? ?? 'Mountain Pine'),
      stage: (map['stage'] as num?)?.toInt() ?? 1,
      xRatio: (map['xRatio'] as num?)?.toDouble() ?? 0.5,
      yRatio: (map['yRatio'] as num?)?.toDouble() ?? 0.5,
      plantedAt: DateTime.parse(map['plantedAt'] as String),
      maturedAt: map['maturedAt'] != null ? DateTime.parse(map['maturedAt'] as String) : null,
      subjectName: map['subjectName'] as String? ?? 'General Study',
      chapterName: map['chapterName'] as String? ?? 'Self Study Session',
      focusMinutes: (map['focusMinutes'] as num?)?.toInt() ?? 25,
      xpEarned: (map['xpEarned'] as num?)?.toInt() ?? 100,
      coinsEarned: (map['coinsEarned'] as num?)?.toInt() ?? 25,
      status: map['status'] as String? ?? 'HEALTHY',
      isShared: (map['isShared'] as int?) == 1,
    );
  }

  ForestTreeModel copyWith({
    String? id,
    String? sessionId,
    TreeSpecies? species,
    int? stage,
    double? xRatio,
    double? yRatio,
    DateTime? plantedAt,
    DateTime? maturedAt,
    String? subjectName,
    String? chapterName,
    int? focusMinutes,
    int? xpEarned,
    int? coinsEarned,
    String? status,
    bool? isShared,
  }) {
    return ForestTreeModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      species: species ?? this.species,
      stage: stage ?? this.stage,
      xRatio: xRatio ?? this.xRatio,
      yRatio: yRatio ?? this.yRatio,
      plantedAt: plantedAt ?? this.plantedAt,
      maturedAt: maturedAt ?? this.maturedAt,
      subjectName: subjectName ?? this.subjectName,
      chapterName: chapterName ?? this.chapterName,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      xpEarned: xpEarned ?? this.xpEarned,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      status: status ?? this.status,
      isShared: isShared ?? this.isShared,
    );
  }
}
