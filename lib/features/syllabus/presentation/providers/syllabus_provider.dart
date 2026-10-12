import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/models/chapter_model.dart';
import '../../../../core/models/subject_model.dart';
import '../../../../core/models/subtopic_model.dart';
import '../../../../core/models/topic_status.dart';

class SyllabusProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  List<SubjectModel> _subjects = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  SyllabusProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  List<SubjectModel> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  /// Overall syllabus progress aggregated across all subjects
  double get overallProgress {
    if (_subjects.isEmpty) return 0.0;
    final total = _subjects.fold<double>(0.0, (sum, s) => sum + s.progress);
    return (total / _subjects.length).clamp(0.0, 1.0);
  }

  int get totalChapters =>
      _subjects.fold<int>(0, (sum, s) => sum + s.totalChapters);

  int get completedChapters =>
      _subjects.fold<int>(0, (sum, s) => sum + s.completedChapters);

  int get totalSubtopics =>
      _subjects.fold<int>(0, (sum, s) => sum + s.totalSubtopics);

  int get completedSubtopics =>
      _subjects.fold<int>(0, (sum, s) => sum + s.completedSubtopics);

  List<SubtopicModel> get revisionQueue {
    final list = <SubtopicModel>[];
    for (final s in _subjects) {
      for (final c in s.chapters) {
        list.addAll(c.subtopics.where((sub) => sub.status == TopicStatus.needsRevision));
      }
    }
    return list;
  }

  List<SubtopicModel> get restudyQueue {
    final list = <SubtopicModel>[];
    for (final s in _subjects) {
      for (final c in s.chapters) {
        list.addAll(c.subtopics.where((sub) => sub.status == TopicStatus.needsRestudy));
      }
    }
    return list;
  }

  /// Filtered subjects according to search query and selected status filter
  List<SubjectModel> get filteredSubjects {
    if (_searchQuery.trim().isEmpty && _selectedFilter == 'All') {
      return _subjects;
    }

    final query = _searchQuery.trim().toLowerCase();

    return _subjects.map((sub) {
      // Filter chapters inside this subject
      final matchingChapters = sub.chapters.where((chap) {
        final matchesChapterName = chap.name.toLowerCase().contains(query);
        final matchesSubjectName = sub.name.toLowerCase().contains(query);

        // Filter subtopics
        final matchingSubtopics = chap.subtopics.where((st) {
          final matchesSubName = st.name.toLowerCase().contains(query);
          final matchesText = query.isEmpty || matchesChapterName || matchesSubjectName || matchesSubName;

          switch (_selectedFilter) {
            case 'In Progress':
              return matchesText && (st.status == TopicStatus.inProgress || st.status == TopicStatus.studyingNow);
            case 'Revision Needed':
              return matchesText && st.status == TopicStatus.needsRevision;
            case 'Restudy Needed':
              return matchesText && st.status == TopicStatus.needsRestudy;
            case 'Completed':
              return matchesText && st.status == TopicStatus.completed;
            case 'All':
            default:
              return matchesText;
          }
        }).toList();

        return matchingSubtopics.isNotEmpty || (query.isNotEmpty && (matchesChapterName || matchesSubjectName));
      }).toList();

      return sub.copyWith(chapters: matchingChapters);
    }).where((sub) => sub.chapters.isNotEmpty || sub.name.toLowerCase().contains(query)).toList();
  }

  Future<void> loadSyllabus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _subjects = await _dbHelper.getSubjectsWithHierarchy();
    } catch (e) {
      debugPrint('Error loading syllabus: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  void setSubjectsForTesting(List<SubjectModel> testSubjects) {
    _subjects = testSubjects;
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // --- Subtopic Actions ---
  Future<void> updateSubtopicStatus(String subtopicId, TopicStatus newStatus) async {
    await _dbHelper.updateSubtopicStatus(subtopicId, newStatus);
    await loadSyllabus();
  }

  Future<void> updateSubtopicNotes(String subtopicId, String? notes) async {
    await _dbHelper.updateSubtopicNotes(subtopicId, notes);
    await loadSyllabus();
  }

  Future<void> updateSubtopicDuration(String subtopicId, int minutes) async {
    await _dbHelper.updateSubtopicDuration(subtopicId, minutes);
    await loadSyllabus();
  }

  Future<void> addSubtopic({
    required String chapterId,
    required String name,
    int estimatedMinutes = 30,
  }) async {
    final now = DateTime.now();
    final newSubtopic = SubtopicModel(
      id: 'subtopic_${_uuid.v4().substring(0, 8)}',
      chapterId: chapterId,
      name: name,
      status: TopicStatus.notStarted,
      estimatedMinutes: estimatedMinutes,
      createdAt: now,
      updatedAt: now,
    );
    await _dbHelper.insertSubtopic(newSubtopic);
    await loadSyllabus();
  }

  Future<void> deleteSubtopic(String subtopicId) async {
    await _dbHelper.deleteSubtopic(subtopicId);
    await loadSyllabus();
  }

  // --- Chapter Actions ---
  Future<void> addChapter({
    required String subjectId,
    required String name,
  }) async {
    final now = DateTime.now();
    final newChapter = ChapterModel(
      id: 'ch_${_uuid.v4().substring(0, 8)}',
      subjectId: subjectId,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    await _dbHelper.insertChapter(newChapter);
    await loadSyllabus();
  }

  Future<void> deleteChapter(String chapterId) async {
    await _dbHelper.deleteChapter(chapterId);
    await loadSyllabus();
  }

  // --- Subject Actions ---
  Future<void> addSubject({
    required String name,
    required String colorHex,
    String iconName = 'menu_book',
  }) async {
    final now = DateTime.now();
    final newSubject = SubjectModel(
      id: 'sub_${_uuid.v4().substring(0, 8)}',
      name: name,
      colorHex: colorHex,
      iconName: iconName,
      orderIndex: _subjects.length,
      createdAt: now,
    );
    await _dbHelper.insertSubject(newSubject);
    await loadSyllabus();
  }

  Future<void> deleteSubject(String subjectId) async {
    await _dbHelper.deleteSubject(subjectId);
    await loadSyllabus();
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _dbHelper.updateSubject(subject);
    await loadSyllabus();
  }

  Future<void> updateChapter(ChapterModel chapter) async {
    await _dbHelper.updateChapter(chapter);
    await loadSyllabus();
  }

  Future<void> updateSubtopic(SubtopicModel subtopic) async {
    await _dbHelper.updateSubtopic(subtopic);
    await loadSyllabus();
  }

  Future<void> updateSubtopicDetails({
    required String subtopicId,
    required String name,
    required int estimatedMinutes,
  }) async {
    final now = DateTime.now();
    for (final s in _subjects) {
      for (final c in s.chapters) {
        for (final st in c.subtopics) {
          if (st.id == subtopicId) {
            final updated = st.copyWith(
              name: name,
              estimatedMinutes: estimatedMinutes,
              updatedAt: now,
            );
            await _dbHelper.updateSubtopic(updated);
            await loadSyllabus();
            return;
          }
        }
      }
    }
  }

  /// Reload the complete official CBSE Class 10 (2027) Syllabus
  Future<void> reloadOfficialClass10Syllabus() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbHelper.reloadClass10Syllabus();
      await loadSyllabus();
    } catch (e) {
      debugPrint('Error reloading CBSE Class 10 syllabus: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
