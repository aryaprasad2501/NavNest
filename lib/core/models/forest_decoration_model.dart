import 'package:flutter/material.dart';

enum DecorationCategory {
  lighting('Lighting', Icons.light_mode_outlined),
  flora('Flora & Flowers', Icons.local_florist_outlined),
  pathway('Pathway', Icons.route_outlined),
  furniture('Cozy Haven', Icons.chair_outlined);

  final String displayName;
  final IconData icon;
  const DecorationCategory(this.displayName, this.icon);

  static DecorationCategory fromString(String val) {
    return DecorationCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == val.toLowerCase() || c.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => DecorationCategory.flora,
    );
  }
}

class ForestDecorationModel {
  final String id;
  final String name;
  final String description;
  final DecorationCategory category;
  final int costCoins;
  final bool isUnlocked;
  final bool isEquipped;
  final double xRatio;
  final double yRatio;
  final String iconName;

  const ForestDecorationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.costCoins,
    this.isUnlocked = false,
    this.isEquipped = false,
    this.xRatio = 0.5,
    this.yRatio = 0.5,
    required this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'costCoins': costCoins,
      'isUnlocked': isUnlocked ? 1 : 0,
      'isEquipped': isEquipped ? 1 : 0,
      'xRatio': xRatio,
      'yRatio': yRatio,
      'iconName': iconName,
    };
  }

  factory ForestDecorationModel.fromMap(Map<String, dynamic> map) {
    return ForestDecorationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      category: DecorationCategory.fromString(map['category'] as String? ?? 'flora'),
      costCoins: (map['costCoins'] as num?)?.toInt() ?? 50,
      isUnlocked: (map['isUnlocked'] as int?) == 1,
      isEquipped: (map['isEquipped'] as int?) == 1,
      xRatio: (map['xRatio'] as num?)?.toDouble() ?? 0.5,
      yRatio: (map['yRatio'] as num?)?.toDouble() ?? 0.5,
      iconName: map['iconName'] as String? ?? 'park',
    );
  }

  ForestDecorationModel copyWith({
    String? id,
    String? name,
    String? description,
    DecorationCategory? category,
    int? costCoins,
    bool? isUnlocked,
    bool? isEquipped,
    double? xRatio,
    double? yRatio,
    String? iconName,
  }) {
    return ForestDecorationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      costCoins: costCoins ?? this.costCoins,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isEquipped: isEquipped ?? this.isEquipped,
      xRatio: xRatio ?? this.xRatio,
      yRatio: yRatio ?? this.yRatio,
      iconName: iconName ?? this.iconName,
    );
  }
}
