class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final int progress;
  final int target;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;
  final int coinsReward;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.progress,
    required this.target,
    this.isUnlocked = false,
    this.unlockedAt,
    this.xpReward = 100,
    this.coinsReward = 50,
  });

  double get progressRatio => (progress / target).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'progress': progress,
      'target': target,
      'isUnlocked': isUnlocked ? 1 : 0,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'xpReward': xpReward,
      'coinsReward': coinsReward,
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      iconName: map['iconName'] as String? ?? 'emoji_events',
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      target: (map['target'] as num?)?.toInt() ?? 1,
      isUnlocked: (map['isUnlocked'] as int?) == 1,
      unlockedAt: map['unlockedAt'] != null ? DateTime.parse(map['unlockedAt'] as String) : null,
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 100,
      coinsReward: (map['coinsReward'] as num?)?.toInt() ?? 50,
    );
  }

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    int? progress,
    int? target,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
    int? coinsReward,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
      coinsReward: coinsReward ?? this.coinsReward,
    );
  }
}
