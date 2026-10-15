import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/models/exam_model.dart';
import '../../../../core/models/planner_task_model.dart';
import '../../domain/adaptive_rescheduler.dart';

class PlannerProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  DateTime _selectedDate = DateTime.now();
  List<PlannerTaskModel> _tasks = [];
  List<PlannerTaskModel> _missedPastTasks = [];
  List<ExamModel> _exams = [];
  bool _isLoading = false;

  PlannerProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  DateTime get selectedDate => _selectedDate;
  List<PlannerTaskModel> get tasks => _tasks;
  List<PlannerTaskModel> get missedPastTasks => _missedPastTasks;
  List<ExamModel> get exams => _exams;
  bool get isLoading => _isLoading;

  bool get isSelectedDateToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  bool get isSelectedDatePast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selected.isBefore(today);
  }

  bool get isSelectedDateFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selected.isAfter(today);
  }

  String get formattedSelectedDateKey => DatabaseHelper.formatDbDate(_selectedDate);

  int get plannedMinutesToday =>
      _tasks.fold<int>(0, (sum, t) => sum + t.plannedMinutes);

  int get actualMinutesToday =>
      _tasks.fold<int>(0, (sum, t) => sum + t.actualMinutes);

  int get completedTasksToday =>
      _tasks.where((t) => t.isCompleted).length;

  int get completedTasksCount => completedTasksToday;

  int get totalTasksToday => _tasks.length;

  double get completionProgressToday {
    if (plannedMinutesToday == 0) return 0.0;
    return (actualMinutesToday / plannedMinutesToday).clamp(0.0, 1.0);
  }

  /// 7-day week window centered or aligned with selectedDate (Monday - Sunday)
  List<DateTime> get currentWeekDays {
    final clean = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    // In Dart DateTime, weekday is 1 for Monday, 7 for Sunday
    final monday = clean.subtract(Duration(days: clean.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  // --- Date Navigation ---
  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
    loadTasksForSelectedDate();
  }

  void goToToday() {
    final now = DateTime.now();
    setSelectedDate(DateTime(now.year, now.month, now.day));
  }

  void nextDay() {
    setSelectedDate(_selectedDate.add(const Duration(days: 1)));
  }

  void previousDay() {
    setSelectedDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  void nextWeek() {
    setSelectedDate(_selectedDate.add(const Duration(days: 7)));
  }

  void previousWeek() {
    setSelectedDate(_selectedDate.subtract(const Duration(days: 7)));
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // --- Data Loading ---
  Future<void> loadInitialData() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _isLoading = true;
    notifyListeners();

    try {
      await _dbHelper.seedInitialPlannerData();
      await loadExams();
      await loadTasksForSelectedDate();
      await checkMissedPastTasks();
    } catch (e) {
      debugPrint('Error loading initial planner data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTasksForSelectedDate() async {
    final dateKey = formattedSelectedDateKey;
    try {
      _tasks = await _dbHelper.getTasksForDate(dateKey);
      await checkMissedPastTasks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks for date $dateKey: $e');
    }
  }

  Future<void> checkMissedPastTasks() async {
    final now = DateTime.now();
    final todayKey = DatabaseHelper.formatDbDate(now);
    try {
      _missedPastTasks = await _dbHelper.getMissedTasksBefore(todayKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading missed past tasks: $e');
    }
  }

  Future<void> loadExams() async {
    try {
      _exams = await _dbHelper.getExams();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading exams: $e');
    }
  }

  // --- Task CRUD ---
  Future<void> addTask({
    required String title,
    required DateTime date,
    String? subjectId,
    String? chapterId,
    String? subtopicId,
    String? startTime,
    String? endTime,
    int plannedMinutes = 45,
    String? notes,
  }) async {
    final newTask = PlannerTaskModel(
      id: 'task_${_uuid.v4()}',
      date: DatabaseHelper.formatDbDate(date),
      subjectId: subjectId,
      chapterId: chapterId,
      subtopicId: subtopicId,
      title: title,
      startTime: startTime,
      endTime: endTime,
      plannedMinutes: plannedMinutes,
      actualMinutes: 0,
      status: PlannerTaskStatus.upcoming,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _dbHelper.insertPlannerTask(newTask);

    // If task is on current viewed date, refresh
    if (DatabaseHelper.formatDbDate(date) == formattedSelectedDateKey) {
      await loadTasksForSelectedDate();
    }
  }

  Future<void> updateTask(PlannerTaskModel task) async {
    await _dbHelper.updatePlannerTask(task);
    await loadTasksForSelectedDate();
  }

  Future<void> deleteTask(String taskId) async {
    await _dbHelper.deletePlannerTask(taskId);
    await loadTasksForSelectedDate();
  }

  Future<void> toggleTaskComplete(PlannerTaskModel task) async {
    final newStatus = task.isCompleted ? PlannerTaskStatus.upcoming : PlannerTaskStatus.completed;
    final newActual = newStatus == PlannerTaskStatus.completed ? task.plannedMinutes : 0;

    final updated = task.copyWith(
      status: newStatus,
      actualMinutes: newActual,
    );

    await _dbHelper.updatePlannerTask(updated);
    await loadTasksForSelectedDate();
  }

  /// Records actual focus study minutes against a scheduled task and optionally marks completed
  Future<void> recordSessionStudyTime({
    required String taskId,
    required int addedMinutes,
    bool markCompleted = false,
  }) async {
    PlannerTaskModel? task;
    try {
      task = _tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {}

    if (task != null) {
      final updated = task.copyWith(
        actualMinutes: task.actualMinutes + addedMinutes,
        status: markCompleted ? PlannerTaskStatus.completed : task.status,
      );
      await _dbHelper.updatePlannerTask(updated);
      await loadTasksForSelectedDate();
    }
  }

  // --- Adaptive Rescheduling ---
  Future<AdaptiveRescheduleResult> runAdaptiveReschedule() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = DatabaseHelper.formatDbDate(today);

    // 1. Fetch missed tasks
    final missed = await _dbHelper.getMissedTasksBefore(todayKey);
    if (missed.isEmpty) {
      return const AdaptiveRescheduleResult(
        rescheduledTasks: [],
        daysSpan: 0,
        totalMinutesRedistributed: 0,
      );
    }

    // 2. Fetch existing future tasks across the next 14 days
    final futureEnd = today.add(const Duration(days: 14));
    final futureTasks = await _dbHelper.getTasksForDateRange(
      todayKey,
      DatabaseHelper.formatDbDate(futureEnd),
    );

    // 3. Compute adaptive redistribution
    final result = AdaptiveRescheduler.reschedule(
      missedTasks: missed,
      existingFutureTasks: futureTasks,
      startDate: today,
    );

    // 4. Save rescheduled tasks to database
    for (final task in result.rescheduledTasks) {
      await _dbHelper.updatePlannerTask(task);
    }

    // 5. Reload
    await loadTasksForSelectedDate();
    await checkMissedPastTasks();

    return result;
  }

  // --- Exam CRUD ---
  Future<void> addExam({
    required String title,
    required DateTime examDate,
    String? subjectId,
    int? targetScore,
    String? colorHex,
  }) async {
    final newExam = ExamModel(
      id: 'exam_${_uuid.v4()}',
      title: title,
      subjectId: subjectId,
      examDate: examDate,
      targetScore: targetScore,
      colorHex: colorHex ?? '#E8833A',
      createdAt: DateTime.now(),
    );

    await _dbHelper.insertExam(newExam);
    await loadExams();
  }

  Future<void> updateExam(ExamModel exam) async {
    await _dbHelper.updateExam(exam);
    await loadExams();
  }

  Future<void> deleteExam(String examId) async {
    await _dbHelper.deleteExam(examId);
    await loadExams();
  }

  @visibleForTesting
  void setTasksForTesting(List<PlannerTaskModel> testTasks, {List<ExamModel>? testExams}) {
    _tasks = testTasks;
    if (testExams != null) _exams = testExams;
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }
}
