class StudySessionModel {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int activeSeconds;
  final int pausedSeconds;
  final String subjectName;
  final String chapterName;
  final String? subtopicName;
  final String treeSpecies;
  final int treeStage;
  final int rewardXp;
  final int rewardCoins;
  final DateTime createdAt;

  const StudySessionModel({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.activeSeconds,
    this.pausedSeconds = 0,
    required this.subjectName,
    required this.chapterName,
    this.subtopicName,
    this.treeSpecies = 'Mountain Pine',
    this.treeStage = 2,
    this.rewardXp = 100,
    this.rewardCoins = 25,
    required this.createdAt,
  });

  int get focusMinutes => (activeSeconds / 60).round();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'activeSeconds': activeSeconds,
      'pausedSeconds': pausedSeconds,
      'subjectId': subjectName,
      'chapterId': chapterName,
      'subtopicId': subtopicName,
      'status': 'COMPLETED',
      'rewardXp': rewardXp,
      'rewardCoins': rewardCoins,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudySessionModel.fromMap(Map<String, dynamic> map) {
    return StudySessionModel(
      id: map['id'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
      endedAt: DateTime.parse(map['endedAt'] as String),
      activeSeconds: (map['activeSeconds'] as num?)?.toInt() ?? 0,
      pausedSeconds: (map['pausedSeconds'] as num?)?.toInt() ?? 0,
      subjectName: map['subjectId'] as String? ?? 'General Study',
      chapterName: map['chapterId'] as String? ?? 'Self Study',
      subtopicName: map['subtopicId'] as String?,
      treeSpecies: 'Mountain Pine',
      treeStage: 2,
      rewardXp: (map['rewardXp'] as num?)?.toInt() ?? 100,
      rewardCoins: (map['rewardCoins'] as num?)?.toInt() ?? 25,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
