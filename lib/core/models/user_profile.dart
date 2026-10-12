class UserProfile {
  final String id;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final int streakDays;
  final int bestStreak;
  final String? lastStudyDate;
  final int totalXp;
  final int coins;
  final int dailyTargetMinutes;
  final String? activeSharedSpaceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.streakDays = 0,
    this.bestStreak = 0,
    this.lastStudyDate,
    this.totalXp = 0,
    this.coins = 0,
    this.dailyTargetMinutes = 120,
    this.activeSharedSpaceId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.defaultProfile({String id = 'default_student'}) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      displayName: 'Student',
      streakDays: 1,
      bestStreak: 1,
      totalXp: 150,
      coins: 40,
      dailyTargetMinutes: 120,
      createdAt: now,
      updatedAt: now,
    );
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    int? streakDays,
    int? bestStreak,
    String? lastStudyDate,
    int? totalXp,
    int? coins,
    int? dailyTargetMinutes,
    String? activeSharedSpaceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      streakDays: streakDays ?? this.streakDays,
      bestStreak: bestStreak ?? this.bestStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      totalXp: totalXp ?? this.totalXp,
      coins: coins ?? this.coins,
      dailyTargetMinutes: dailyTargetMinutes ?? this.dailyTargetMinutes,
      activeSharedSpaceId: activeSharedSpaceId ?? this.activeSharedSpaceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'streakDays': streakDays,
      'bestStreak': bestStreak,
      'lastStudyDate': lastStudyDate,
      'totalXp': totalXp,
      'coins': coins,
      'dailyTargetMinutes': dailyTargetMinutes,
      'activeSharedSpaceId': activeSharedSpaceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      displayName: map['displayName'] as String? ?? 'Student',
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
      bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
      lastStudyDate: map['lastStudyDate'] as String?,
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      dailyTargetMinutes: (map['dailyTargetMinutes'] as num?)?.toInt() ?? 120,
      activeSharedSpaceId: map['activeSharedSpaceId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
