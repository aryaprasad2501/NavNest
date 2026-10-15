import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/core/models/study_session_model.dart';
import 'package:navnest/core/services/cloud_sync_service.dart';
import 'package:navnest/features/shared_space/presentation/providers/shared_space_provider.dart';
import 'package:navnest/features/navbloom/presentation/providers/forest_provider.dart';
import 'package:navnest/features/planner/presentation/providers/planner_provider.dart';
import 'package:navnest/features/distraction_control/presentation/providers/app_blocker_provider.dart';
import 'package:navnest/features/focus/models/active_session_model.dart';
import 'package:navnest/features/focus/services/active_session_store.dart';
import 'package:navnest/features/focus/services/focus_platform_bridge.dart';

class FocusSessionProvider extends ChangeNotifier with WidgetsBindingObserver {
  final DatabaseHelper _dbHelper;
  final ActiveSessionStore _sessionStore;
  final Uuid _uuid = const Uuid();

  ActiveSessionModel? _session;
  int _currentMonotonicMs = 0;
  int _currentWallEpochMs = 0;
  Timer? _uiRefreshTimer;

  ForestProvider? _forestProvider;
  PlannerProvider? _plannerProvider;
  AppBlockerProvider? _appBlockerProvider;
  CloudSyncService? _cloudSyncService;
  SharedSpaceProvider? _sharedSpaceProvider;

  FocusSessionProvider({
    DatabaseHelper? dbHelper,
    ActiveSessionStore? sessionStore,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _sessionStore = sessionStore ?? ActiveSessionStore(dbHelper: dbHelper) {
    WidgetsBinding.instance.addObserver(this);
  }

  void updateDependencies({
    ForestProvider? forestProvider,
    PlannerProvider? plannerProvider,
    AppBlockerProvider? appBlockerProvider,
    CloudSyncService? cloudSyncService,
    SharedSpaceProvider? sharedSpaceProvider,
  }) {
    _forestProvider = forestProvider;
    _plannerProvider = plannerProvider;
    _appBlockerProvider = appBlockerProvider;
    _cloudSyncService = cloudSyncService;
    _sharedSpaceProvider = sharedSpaceProvider;
  }

  // --- Getters ---
  ActiveSessionModel? get session => _session;
  bool get hasActiveSession => _session != null && !_session!.isCompleted && !_session!.isCancelled;
  bool get isRunning => _session?.isRunning ?? false;
  bool get isPaused => _session?.isPaused ?? false;
  bool get isInterrupted => _session?.isInterrupted ?? false;
  FocusTimerMode get mode => _session?.mode ?? FocusTimerMode.pomodoro;
  PomodoroPhase get pomodoroPhase => _session?.pomodoroPhase ?? PomodoroPhase.work;
  int get pomodoroCycle => _session?.pomodoroCycle ?? 1;

  int get remainingSeconds {
    if (_session == null) return 1500;
    return _session!.calculateRemainingSeconds(_currentMonotonicMs);
  }

  int get elapsedActiveSeconds {
    if (_session == null) return 0;
    return _session!.calculateActiveSeconds(_currentMonotonicMs);
  }

  double get progressRatio {
    if (_session == null) return 0.0;
    return _session!.calculateProgress(_currentMonotonicMs);
  }

  String get subjectName => _session?.subjectName ?? 'Mathematics';
  String get chapterName => _session?.chapterName ?? 'Real Numbers';
  String? get subtopicName => _session?.subtopicName;
  String? get linkedTaskId => _session?.linkedTaskId;
  TreeSpecies get treeSpecies => _session?.treeSpecies ?? TreeSpecies.cherryBlossom;
  bool get isCompleted => _session?.isCompleted ?? false;

  /// Clears completed session state so student can configure and launch next session.
  void clearCompletedSession() {
    if (_session?.isCompleted == true) {
      _session = null;
      notifyListeners();
    }
  }

  // --- Lifecycle Observer ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Screen turned on or app returned to foreground:
      // Refresh monotonic clock immediately and check expiry
      _refreshMonotonicClock().then((_) {
        _checkBackgroundExpiration();
      });
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // App moving to background: flush session state to durable storage
      if (_session != null) {
        _sessionStore.persistSession(_session!);
      }
    }
  }

  /// Initializes provider and restores any active session from persistence.
  Future<void> initialize() async {
    await _refreshMonotonicClock();
    final restored = await _sessionStore.loadActiveSession();

    if (restored != null && !restored.isCompleted && !restored.isCancelled) {
      final bootInfo = await FocusPlatformBridge.getBootTimeInfo();

      // Check if device rebooted while session was running
      final bootDiscrepancy = (bootInfo.bootTimeEpochMs - restored.bootTimeEpochMs).abs();
      final isRebootDetected = bootInfo.elapsedRealtime < restored.lastResumeRealtimeMs ||
          bootDiscrepancy > 5000;

      if (isRebootDetected) {
        // Device was rebooted: recover elapsed time up to checkpoint, do not fabricate time
        _session = restored.copyWith(
          state: FocusSessionState.interruptedByReboot,
          updatedAt: DateTime.now(),
        );
        await _sessionStore.persistSession(_session!);
      } else {
        _session = restored;

        // Check if countdown expired while app was closed
        if (_session!.isRunning && _session!.isExpired(_currentMonotonicMs)) {
          await completeSession();
        } else if (_session!.isRunning) {
          _startUiTicker();
          // Update native notification
          await _updateForegroundServiceNotification();
        }
      }
      _appBlockerProvider?.syncFocusSessionState(
        isSessionActive: hasActiveSession,
        isSessionPaused: isPaused,
      );
      notifyListeners();
    }
  }

  Future<void> _refreshMonotonicClock() async {
    _currentMonotonicMs = await FocusPlatformBridge.getElapsedRealtimeMs();
    _currentWallEpochMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _startUiTicker() {
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      await _refreshMonotonicClock();
      if (_session != null && _session!.isRunning) {
        if (_session!.isExpired(_currentMonotonicMs)) {
          _uiRefreshTimer?.cancel();
          await completeSession();
        } else {
          notifyListeners();
        }
      }
    });
  }

  Future<void> _checkBackgroundExpiration() async {
    if (_session != null && _session!.isRunning && _session!.isExpired(_currentMonotonicMs)) {
      await completeSession();
    } else {
      notifyListeners();
    }
  }

  // --- Session Controls ---

  /// Starts a new focus study session.
  Future<void> startSession({
    required FocusTimerMode mode,
    required int targetSeconds,
    required String subjectName,
    required String chapterName,
    String? subtopicName,
    String? linkedTaskId,
    TreeSpecies treeSpecies = TreeSpecies.cherryBlossom,
    bool strictModeEnabled = false,
  }) async {
    await _refreshMonotonicClock();
    final bootInfo = await FocusPlatformBridge.getBootTimeInfo();
    final sessionId = _uuid.v4();
    final now = DateTime.now();

    final newSession = ActiveSessionModel(
      id: sessionId,
      mode: mode,
      pomodoroPhase: PomodoroPhase.work,
      pomodoroCycle: 1,
      targetSeconds: targetSeconds,
      elapsedRealtimeStartMs: _currentMonotonicMs,
      wallClockStartMs: _currentWallEpochMs,
      accumulatedActiveMs: 0,
      accumulatedPausedMs: 0,
      lastResumeRealtimeMs: _currentMonotonicMs,
      lastResumeWallMs: _currentWallEpochMs,
      bootTimeEpochMs: bootInfo.bootTimeEpochMs,
      state: FocusSessionState.running,
      linkedTaskId: linkedTaskId,
      subjectName: subjectName,
      chapterName: chapterName,
      subtopicName: subtopicName,
      treeSpecies: treeSpecies,
      strictModeEnabled: strictModeEnabled,
      updatedAt: now,
    );

    _session = newSession;
    await _sessionStore.persistSession(newSession);

    // Launch Android Foreground Service with deadline chronometer
    final deadlineMs = newSession.calculateTargetDeadlineEpochMs(_currentMonotonicMs, _currentWallEpochMs);
    await FocusPlatformBridge.startForegroundService(
      title: 'Focusing: $subjectName 🌲',
      content: '$chapterName • ${newSession.mode.name.toUpperCase()}',
      deadlineMs: deadlineMs,
      isCountdown: mode != FocusTimerMode.stopwatch,
      isPaused: false,
    );

    _appBlockerProvider?.syncFocusSessionState(
      isSessionActive: true,
      isSessionPaused: false,
    );

    _startUiTicker();
    notifyListeners();
  }

  /// Pauses active focus session. Excludes pause intervals from accepted active duration.
  Future<void> pauseSession() async {
    if (_session == null || !_session!.isRunning) return;

    await _refreshMonotonicClock();
    final currentSegmentMs = _currentMonotonicMs - _session!.lastResumeRealtimeMs;
    final newAccumulatedActive = _session!.accumulatedActiveMs + currentSegmentMs;

    _session = _session!.copyWith(
      state: FocusSessionState.paused,
      accumulatedActiveMs: newAccumulatedActive,
      pauseStartRealtimeMs: _currentMonotonicMs,
      pauseStartWallMs: _currentWallEpochMs,
      updatedAt: DateTime.now(),
    );

    await _sessionStore.persistSession(_session!);
    _uiRefreshTimer?.cancel();

    // Update notification to Paused
    final remMins = (_session!.calculateRemainingSeconds(_currentMonotonicMs) / 60).ceil();
    await FocusPlatformBridge.updateNotification(
      title: 'Paused: ${_session!.subjectName} ⏸️',
      content: '$remMins mins remaining • Tap to resume',
      isPaused: true,
    );

    _appBlockerProvider?.syncFocusSessionState(
      isSessionActive: true,
      isSessionPaused: true,
    );

    notifyListeners();
  }

  /// Resumes paused session.
  Future<void> resumeSession() async {
    if (_session == null || !_session!.isPaused) return;

    await _refreshMonotonicClock();
    final pauseDuration = _session!.pauseStartRealtimeMs != null
        ? _currentMonotonicMs - _session!.pauseStartRealtimeMs!
        : 0;
    final newAccumulatedPaused = _session!.accumulatedPausedMs + pauseDuration;

    _session = _session!.copyWith(
      state: FocusSessionState.running,
      accumulatedPausedMs: newAccumulatedPaused,
      lastResumeRealtimeMs: _currentMonotonicMs,
      lastResumeWallMs: _currentWallEpochMs,
      pauseStartRealtimeMs: null,
      pauseStartWallMs: null,
      updatedAt: DateTime.now(),
    );

    await _sessionStore.persistSession(_session!);

    // Update notification with new deadline
    await _updateForegroundServiceNotification();

    _appBlockerProvider?.syncFocusSessionState(
      isSessionActive: true,
      isSessionPaused: false,
    );

    _startUiTicker();
    notifyListeners();
  }

  /// Stops or cancels session early.
  Future<void> stopSession({bool cancelled = true}) async {
    if (_session == null) return;

    await _refreshMonotonicClock();
    final activeMinutes = _session!.calculateActiveSeconds(_currentMonotonicMs) ~/ 60;

    _uiRefreshTimer?.cancel();
    await FocusPlatformBridge.stopForegroundService();

    _appBlockerProvider?.syncFocusSessionState(
      isSessionActive: false,
      isSessionPaused: false,
    );

    if (cancelled && activeMinutes < 1) {
      // Discard insignificant sessions under 1 minute
      await _sessionStore.clearActiveSession();
      _session = null;
      notifyListeners();
      return;
    }

    if (cancelled) {
      // Record partial/interrupted session
      final now = DateTime.now();
      final startedAt = DateTime.fromMillisecondsSinceEpoch(_session!.wallClockStartMs);
      final sessionRecord = StudySessionModel(
        id: _session!.id,
        startedAt: startedAt,
        endedAt: now,
        activeSeconds: _session!.calculateActiveSeconds(_currentMonotonicMs),
        pausedSeconds: _session!.accumulatedPausedMs ~/ 1000,
        subjectName: _session!.subjectName,
        chapterName: _session!.chapterName,
        subtopicName: _session!.subtopicName,
        treeSpecies: _session!.treeSpecies.displayName,
        treeStage: 1,
        rewardXp: activeMinutes * 2,
        rewardCoins: (activeMinutes * 0.4).round(),
        createdAt: now,
      );
      await _dbHelper.insertStudySession(sessionRecord);

      // Update planner actual minutes if linked
      if (_session!.linkedTaskId != null && _plannerProvider != null) {
        await _plannerProvider!.recordSessionStudyTime(
          taskId: _session!.linkedTaskId!,
          addedMinutes: activeMinutes,
          markCompleted: false,
        );
      }
    }

    await _sessionStore.clearActiveSession();
    _session = null;
    notifyListeners();
  }

  /// Completes countdown focus session, awards NavBloom tree and rewards with idempotency.
  Future<void> completeSession() async {
    if (_session == null) return;

    await _refreshMonotonicClock();
    _uiRefreshTimer?.cancel();

    _appBlockerProvider?.syncFocusSessionState(
      isSessionActive: false,
      isSessionPaused: false,
    );

    final activeSec = _session!.calculateActiveSeconds(_currentMonotonicMs);
    final focusMinutes = max(1, (activeSec / 60).round());
    final now = DateTime.now();
    final startedAt = DateTime.fromMillisecondsSinceEpoch(_session!.wallClockStartMs);

    // 1. Record completed study session in SQLite
    final sessionRecord = StudySessionModel(
      id: _session!.id,
      startedAt: startedAt,
      endedAt: now,
      activeSeconds: activeSec,
      pausedSeconds: _session!.accumulatedPausedMs ~/ 1000,
      subjectName: _session!.subjectName,
      chapterName: _session!.chapterName,
      subtopicName: _session!.subtopicName,
      treeSpecies: _session!.treeSpecies.displayName,
      treeStage: focusMinutes >= 60 ? 5 : 4,
      rewardXp: focusMinutes * 2 + 30,
      rewardCoins: (focusMinutes * 0.5).round() + 10,
      createdAt: now,
    );
    await _dbHelper.insertStudySession(sessionRecord);

    // 2. Award NavBloom tree with idempotency ledger verification
    if (_forestProvider != null) {
      await _forestProvider!.plantTree(
        species: _session!.treeSpecies,
        subjectName: _session!.subjectName,
        chapterName: _session!.chapterName,
        focusMinutes: focusMinutes,
        sessionId: _session!.id,
      );
    }

    // 3. Update Planner Task planned-vs-actual study reporting
    if (_session!.linkedTaskId != null && _plannerProvider != null) {
      await _plannerProvider!.recordSessionStudyTime(
        taskId: _session!.linkedTaskId!,
        addedMinutes: focusMinutes,
        markCompleted: true,
      );
    }

    // 4. Queue completed study session for offline-first cloud backup
    _cloudSyncService?.queueCompletedSession(sessionRecord);

    // 5. Update partner real-time accountability status if paired
    final todayFocus = await _dbHelper.getTodayFocusMinutes();
    final allTrees = await _dbHelper.getForestTrees();
    _sharedSpaceProvider?.reportStudyProgress(
      isFocusing: false,
      subjectName: _session!.subjectName,
      todayFocusMinutes: todayFocus,
      todayTreesCount: allTrees.length,
    );

    // 6. Update notification to completion celebration
    await FocusPlatformBridge.updateNotification(
      title: 'Session Complete! 🌸',
      content: 'Harvested ${_session!.treeSpecies.displayName} • $focusMinutes mins focused',
      isPaused: true,
    );

    // 7. Clear durable active session
    await _sessionStore.clearActiveSession();
    _session = _session!.copyWith(
      state: FocusSessionState.completed,
      updatedAt: now,
    );

    notifyListeners();
  }

  /// Handles Pomodoro transition (Work -> Short Break -> Work).
  Future<void> transitionPomodoroPhase() async {
    if (_session == null || _session!.mode != FocusTimerMode.pomodoro) return;

    await _refreshMonotonicClock();
    final nextPhase = _session!.pomodoroPhase == PomodoroPhase.work
        ? (_session!.pomodoroCycle % 4 == 0 ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak)
        : PomodoroPhase.work;

    final nextTargetSeconds = nextPhase == PomodoroPhase.work
        ? 25 * 60
        : (nextPhase == PomodoroPhase.longBreak ? 15 * 60 : 5 * 60);

    final nextCycle = nextPhase == PomodoroPhase.work
        ? _session!.pomodoroCycle + 1
        : _session!.pomodoroCycle;

    final bootInfo = await FocusPlatformBridge.getBootTimeInfo();
    final updated = _session!.copyWith(
      pomodoroPhase: nextPhase,
      pomodoroCycle: nextCycle,
      targetSeconds: nextTargetSeconds,
      accumulatedActiveMs: 0,
      accumulatedPausedMs: 0,
      lastResumeRealtimeMs: _currentMonotonicMs,
      lastResumeWallMs: _currentWallEpochMs,
      pauseStartRealtimeMs: null,
      pauseStartWallMs: null,
      bootTimeEpochMs: bootInfo.bootTimeEpochMs,
      state: FocusSessionState.running,
      updatedAt: DateTime.now(),
    );

    _session = updated;
    await _sessionStore.persistSession(updated);
    await _updateForegroundServiceNotification();

    _startUiTicker();
    notifyListeners();
  }

  Future<void> _updateForegroundServiceNotification() async {
    if (_session == null) return;
    final deadlineMs = _session!.calculateTargetDeadlineEpochMs(_currentMonotonicMs, _currentWallEpochMs);
    final phaseLabel = _session!.mode == FocusTimerMode.pomodoro
        ? 'Pomodoro (${_session!.pomodoroPhase.name.toUpperCase()})'
        : _session!.chapterName;

    await FocusPlatformBridge.updateNotification(
      title: 'Focusing: ${_session!.subjectName} 🌲',
      content: '$phaseLabel • Tap to view',
      deadlineMs: deadlineMs,
      isCountdown: _session!.mode != FocusTimerMode.stopwatch,
      isPaused: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiRefreshTimer?.cancel();
    super.dispose();
  }
}
