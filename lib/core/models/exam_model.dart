class ExamModel {
  final String id;
  final String title;
  final String? subjectId;
  final DateTime examDate;
  final int? targetScore;
  final String? colorHex;
  final DateTime createdAt;

  const ExamModel({
    required this.id,
    required this.title,
    this.subjectId,
    required this.examDate,
    this.targetScore,
    this.colorHex,
    required this.createdAt,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(examDate.year, examDate.month, examDate.day);
    return target.difference(today).inDays;
  }

  bool get isPast => daysRemaining < 0;
  bool get isToday => daysRemaining == 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'examDate': examDate.toIso8601String(),
      'targetScore': targetScore,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'] as String,
      title: map['title'] as String,
      subjectId: map['subjectId'] as String?,
      examDate: DateTime.tryParse(map['examDate'] as String? ?? '') ?? DateTime.now(),
      targetScore: (map['targetScore'] as num?)?.toInt(),
      colorHex: map['colorHex'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  ExamModel copyWith({
    String? id,
    String? title,
    String? subjectId,
    DateTime? examDate,
    int? targetScore,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      examDate: examDate ?? this.examDate,
      targetScore: targetScore ?? this.targetScore,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
