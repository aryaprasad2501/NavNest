import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TreeSpecies {
  cherryBlossom('Cherry Blossom', AppColors.cherryPink, '🌸'),
  mountainPine('Mountain Pine', AppColors.sageGreen, '🌲'),
  ancientOak('Ancient Oak', AppColors.deepForest, '🌳'),
  riverWillow('River Willow', AppColors.forestEmerald, '🌿'),
  goldenGinkgo('Golden Ginkgo', AppColors.amberWarm, '🍂'),
  bonsaiJuniper('Bonsai Juniper', AppColors.sageLight, '🪴');

  final String displayName;
  final Color themeColor;
  final String iconEmoji;

  const TreeSpecies(this.displayName, this.themeColor, this.iconEmoji);

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
