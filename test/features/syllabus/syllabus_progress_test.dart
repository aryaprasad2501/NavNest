import 'package:flutter_test/flutter_test.dart';
import 'package:navnest/core/models/chapter_model.dart';
import 'package:navnest/core/models/subject_model.dart';
import 'package:navnest/core/models/subtopic_model.dart';
import 'package:navnest/core/models/topic_status.dart';

void main() {
  group('Syllabus Progress Calculation Tests', () {
    final now = DateTime.now();

    test('Empty chapter returns 0.0 progress', () {
      final chapter = ChapterModel(
        id: 'ch_empty',
        subjectId: 'sub_1',
        name: 'Empty Chapter',
        createdAt: now,
        updatedAt: now,
        subtopics: [],
      );

      expect(chapter.progress, equals(0.0));
      expect(chapter.isCompleted, isFalse);
    });

    test('Chapter with all completed subtopics returns 1.0 progress and isCompleted true', () {
      final chapter = ChapterModel(
        id: 'ch_full',
        subjectId: 'sub_1',
        name: 'Full Chapter',
        createdAt: now,
        updatedAt: now,
        subtopics: [
          SubtopicModel(
            id: 'st_1',
            chapterId: 'ch_full',
            name: 'Topic 1',
            status: TopicStatus.completed,
            createdAt: now,
            updatedAt: now,
          ),
          SubtopicModel(
            id: 'st_2',
            chapterId: 'ch_full',
            name: 'Topic 2',
            status: TopicStatus.completed,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      expect(chapter.progress, equals(1.0));
      expect(chapter.isCompleted, isTrue);
      expect(chapter.completedSubtopics, equals(2));
    });

    test('Mixed statuses calculate weighted progress accurately and non-destructively', () {
      // 4 subtopics:
      // Topic 1: Completed (weight 1.0)
      // Topic 2: Needs Revision (weight 0.85)
      // Topic 3: In Progress (weight 0.30)
      // Topic 4: Not Started (weight 0.0)
      // Total weight = 2.15 / 4 = 0.5375
      final chapter = ChapterModel(
        id: 'ch_mixed',
        subjectId: 'sub_1',
        name: 'Mixed Chapter',
        createdAt: now,
        updatedAt: now,
        subtopics: [
          SubtopicModel(
            id: 'st_1',
            chapterId: 'ch_mixed',
            name: 'Topic 1',
            status: TopicStatus.completed,
            createdAt: now,
            updatedAt: now,
          ),
          SubtopicModel(
            id: 'st_2',
            chapterId: 'ch_mixed',
            name: 'Topic 2',
            status: TopicStatus.needsRevision,
            createdAt: now,
            updatedAt: now,
          ),
          SubtopicModel(
            id: 'st_3',
            chapterId: 'ch_mixed',
            name: 'Topic 3',
            status: TopicStatus.inProgress,
            createdAt: now,
            updatedAt: now,
          ),
          SubtopicModel(
            id: 'st_4',
            chapterId: 'ch_mixed',
            name: 'Topic 4',
            status: TopicStatus.notStarted,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      expect(chapter.progress, closeTo(0.5375, 0.001));
      expect(chapter.isCompleted, isFalse);
      expect(chapter.completedSubtopics, equals(1));
      expect(chapter.revisionSubtopics, equals(1));
    });

    test('Subject aggregates chapter progresses consistently', () {
      // Chapter 1: 1.0 progress
      // Chapter 2: 0.5 progress
      // Subject progress = (1.0 + 0.5) / 2 = 0.75
      final ch1 = ChapterModel(
        id: 'ch_1',
        subjectId: 'sub_1',
        name: 'Chapter 1',
        createdAt: now,
        updatedAt: now,
        subtopics: [
          SubtopicModel(
            id: 'st_1',
            chapterId: 'ch_1',
            name: 'Topic 1',
            status: TopicStatus.completed,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final ch2 = ChapterModel(
        id: 'ch_2',
        subjectId: 'sub_1',
        name: 'Chapter 2',
        createdAt: now,
        updatedAt: now,
        subtopics: [
          SubtopicModel(
            id: 'st_2',
            chapterId: 'ch_2',
            name: 'Topic 2',
            status: TopicStatus.completed,
            createdAt: now,
            updatedAt: now,
          ),
          SubtopicModel(
            id: 'st_3',
            chapterId: 'ch_2',
            name: 'Topic 3',
            status: TopicStatus.notStarted,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final subject = SubjectModel(
        id: 'sub_1',
        name: 'Physics',
        colorHex: '#E8833A',
        iconName: 'lightbulb',
        createdAt: now,
        chapters: [ch1, ch2],
      );

      expect(subject.totalChapters, equals(2));
      expect(subject.completedChapters, equals(1));
      expect(subject.progress, equals(0.75));
    });
  });
}
