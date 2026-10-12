import 'package:flutter/material.dart';
import 'chapter_model.dart';

class SubjectModel {
  final String id;
  final String name;
  final String colorHex;
  final String iconName;
  final int orderIndex;
  final String classLevel;
  final String boardName;
  final DateTime createdAt;
  final List<ChapterModel> chapters;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
    this.orderIndex = 0,
    this.classLevel = 'Class 10',
    this.boardName = 'CBSE',
    required this.createdAt,
    this.chapters = const [],
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return const Color(0xFF6B8E70); // default sage
  }

  int get totalChapters => chapters.length;

  int get completedChapters => chapters.where((c) => c.isCompleted).length;

  int get totalSubtopics =>
      chapters.fold<int>(0, (sum, c) => sum + c.totalSubtopics);

  int get completedSubtopics =>
      chapters.fold<int>(0, (sum, c) => sum + c.completedSubtopics);

  int get totalEstimatedMinutes =>
      chapters.fold<int>(0, (sum, c) => sum + c.totalEstimatedMinutes);

  /// Consistent subject progress calculation: average of chapter progresses.
  /// If no chapters exist, returns 0.0.
  double get progress {
    if (chapters.isEmpty) return 0.0;
    final totalProgress = chapters.fold<double>(
      0.0,
      (sum, c) => sum + c.progress,
    );
    return (totalProgress / chapters.length).clamp(0.0, 1.0);
  }

  SubjectModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
    int? orderIndex,
    String? classLevel,
    String? boardName,
    DateTime? createdAt,
    List<ChapterModel>? chapters,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      orderIndex: orderIndex ?? this.orderIndex,
      classLevel: classLevel ?? this.classLevel,
      boardName: boardName ?? this.boardName,
      createdAt: createdAt ?? this.createdAt,
      chapters: chapters ?? this.chapters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'iconName': iconName,
      'orderIndex': orderIndex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map, {List<ChapterModel> chapters = const []}) {
    return SubjectModel(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String? ?? '#6B8E70',
      iconName: map['iconName'] as String? ?? 'menu_book',
      orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
      classLevel: 'Class 10',
      boardName: 'CBSE',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      chapters: chapters,
    );
  }
}
