import 'subtopic_model.dart';
import 'topic_status.dart';

class ChapterModel {
  final String id;
  final String subjectId;
  final String name;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SubtopicModel> subtopics;

  const ChapterModel({
    required this.id,
    required this.subjectId,
    required this.name,
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.subtopics = const [],
  });

  int get totalSubtopics => subtopics.length;

  int get completedSubtopics =>
      subtopics.where((s) => s.status == TopicStatus.completed).length;

  int get revisionSubtopics =>
      subtopics.where((s) => s.status == TopicStatus.needsRevision).length;

  int get restudySubtopics =>
      subtopics.where((s) => s.status == TopicStatus.needsRestudy).length;

  int get totalEstimatedMinutes =>
      subtopics.fold<int>(0, (sum, s) => sum + s.estimatedMinutes);

  /// Consistent progress calculation: average of subtopic completion weights.
  /// If no subtopics yet, returns 0.0.
  double get progress {
    if (subtopics.isEmpty) return 0.0;
    final totalWeight = subtopics.fold<double>(
      0.0,
      (sum, s) => sum + s.status.completionWeight,
    );
    return (totalWeight / subtopics.length).clamp(0.0, 1.0);
  }

  bool get isCompleted =>
      subtopics.isNotEmpty &&
      subtopics.every((s) => s.status == TopicStatus.completed);

  ChapterModel copyWith({
    String? id,
    String? subjectId,
    String? name,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SubtopicModel>? subtopics,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtopics: subtopics ?? this.subtopics,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'orderIndex': orderIndex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChapterModel.fromMap(Map<String, dynamic> map, {List<SubtopicModel> subtopics = const []}) {
    return ChapterModel(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String,
      name: map['name'] as String,
      orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      subtopics: subtopics,
    );
  }
}
