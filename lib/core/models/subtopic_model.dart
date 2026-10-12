import 'topic_status.dart';

class SubtopicModel {
  final String id;
  final String chapterId;
  final String name;
  final TopicStatus status;
  final int estimatedMinutes;
  final String? notes;
  final int orderIndex;
  final DateTime? completedAt;
  final int revisionCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubtopicModel({
    required this.id,
    required this.chapterId,
    required this.name,
    this.status = TopicStatus.notStarted,
    this.estimatedMinutes = 30,
    this.notes,
    this.orderIndex = 0,
    this.completedAt,
    this.revisionCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  SubtopicModel copyWith({
    String? id,
    String? chapterId,
    String? name,
    TopicStatus? status,
    int? estimatedMinutes,
    String? notes,
    int? orderIndex,
    DateTime? completedAt,
    int? revisionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubtopicModel(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      name: name ?? this.name,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
      completedAt: completedAt ?? this.completedAt,
      revisionCount: revisionCount ?? this.revisionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterId': chapterId,
      'name': name,
      'status': status.code,
      'estimatedMinutes': estimatedMinutes,
      'notes': notes,
      'orderIndex': orderIndex,
      'completedAt': completedAt?.toIso8601String(),
      'revisionCount': revisionCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SubtopicModel.fromMap(Map<String, dynamic> map) {
    return SubtopicModel(
      id: map['id'] as String,
      chapterId: map['chapterId'] as String,
      name: map['name'] as String,
      status: TopicStatus.fromCode(map['status'] as String?),
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 30,
      notes: map['notes'] as String?,
      orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
      revisionCount: (map['revisionCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
