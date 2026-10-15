import 'dart:math';
import '../../../core/models/forest_tree_model.dart';

enum FocusTimerMode { pomodoro, custom, stopwatch }

enum PomodoroPhase { work, shortBreak, longBreak }

enum FocusSessionState {
  running,
  paused,
  completed,
  cancelled,
  interruptedByReboot,
}

class ActiveSessionModel {
  final String id;
  final FocusTimerMode mode;
  final PomodoroPhase pomodoroPhase;
  final int pomodoroCycle;
  final int targetSeconds;
  final int elapsedRealtimeStartMs;
  final int wallClockStartMs;
  final int accumulatedActiveMs;
  final int accumulatedPausedMs;
  final int lastResumeRealtimeMs;
  final int lastResumeWallMs;
  final int? pauseStartRealtimeMs;
  final int? pauseStartWallMs;
  final int bootTimeEpochMs;
  final FocusSessionState state;
  final String? linkedTaskId;
  final String subjectName;
  final String chapterName;
  final String? subtopicName;
  final TreeSpecies treeSpecies;
  final bool strictModeEnabled;
  final DateTime updatedAt;

  const ActiveSessionModel({
    required this.id,
    required this.mode,
    this.pomodoroPhase = PomodoroPhase.work,
    this.pomodoroCycle = 1,
    required this.targetSeconds,
    required this.elapsedRealtimeStartMs,
    required this.wallClockStartMs,
    this.accumulatedActiveMs = 0,
    this.accumulatedPausedMs = 0,
    required this.lastResumeRealtimeMs,
    required this.lastResumeWallMs,
    this.pauseStartRealtimeMs,
    this.pauseStartWallMs,
    required this.bootTimeEpochMs,
    required this.state,
    this.linkedTaskId,
    required this.subjectName,
    required this.chapterName,
    this.subtopicName,
    this.treeSpecies = TreeSpecies.cherryBlossom,
    this.strictModeEnabled = false,
    required this.updatedAt,
  });

  bool get isRunning => state == FocusSessionState.running;
  bool get isPaused => state == FocusSessionState.paused;
  bool get isCompleted => state == FocusSessionState.completed;
  bool get isCancelled => state == FocusSessionState.cancelled;
  bool get isInterrupted => state == FocusSessionState.interruptedByReboot;

  /// Calculates total active focus duration in milliseconds up to the provided monotonic clock.
  /// Strictly excludes pause intervals.
  int calculateActiveElapsedMs(int currentMonotonicMs) {
    if (state == FocusSessionState.paused || state == FocusSessionState.interruptedByReboot) {
      return accumulatedActiveMs;
    }
    final currentIntervalMs = max(0, currentMonotonicMs - lastResumeRealtimeMs);
    return accumulatedActiveMs + currentIntervalMs;
  }

  /// Calculates active focus in whole seconds.
  int calculateActiveSeconds(int currentMonotonicMs) {
    return (calculateActiveElapsedMs(currentMonotonicMs) / 1000).floor();
  }

  /// Calculates remaining seconds for countdown sessions.
  /// For stopwatch mode, returns 0.
  int calculateRemainingSeconds(int currentMonotonicMs) {
    if (mode == FocusTimerMode.stopwatch) return 0;
    final activeSec = calculateActiveSeconds(currentMonotonicMs);
    return max(0, targetSeconds - activeSec);
  }

  /// Checks if countdown deadline has expired.
  bool isExpired(int currentMonotonicMs) {
    if (mode == FocusTimerMode.stopwatch) return false;
    return calculateRemainingSeconds(currentMonotonicMs) <= 0;
  }

  /// Calculates completion progress from 0.0 to 1.0.
  double calculateProgress(int currentMonotonicMs) {
    if (mode == FocusTimerMode.stopwatch) {
      return min(1.0, calculateActiveSeconds(currentMonotonicMs) / 3600.0);
    }
    if (targetSeconds <= 0) return 1.0;
    final elapsedSec = calculateActiveSeconds(currentMonotonicMs);
    return (elapsedSec / targetSeconds).clamp(0.0, 1.0);
  }

  /// Target deadline epoch in milliseconds (for native Android notification chronometer).
  int calculateTargetDeadlineEpochMs(int currentMonotonicMs, int currentWallEpochMs) {
    if (mode == FocusTimerMode.stopwatch) return currentWallEpochMs;
    final remSec = calculateRemainingSeconds(currentMonotonicMs);
    return currentWallEpochMs + (remSec * 1000);
  }

  ActiveSessionModel copyWith({
    String? id,
    FocusTimerMode? mode,
    PomodoroPhase? pomodoroPhase,
    int? pomodoroCycle,
    int? targetSeconds,
    int? elapsedRealtimeStartMs,
    int? wallClockStartMs,
    int? accumulatedActiveMs,
    int? accumulatedPausedMs,
    int? lastResumeRealtimeMs,
    int? lastResumeWallMs,
    int? pauseStartRealtimeMs,
    int? pauseStartWallMs,
    int? bootTimeEpochMs,
    FocusSessionState? state,
    String? linkedTaskId,
    String? subjectName,
    String? chapterName,
    String? subtopicName,
    TreeSpecies? treeSpecies,
    bool? strictModeEnabled,
    DateTime? updatedAt,
  }) {
    return ActiveSessionModel(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      pomodoroPhase: pomodoroPhase ?? this.pomodoroPhase,
      pomodoroCycle: pomodoroCycle ?? this.pomodoroCycle,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      elapsedRealtimeStartMs: elapsedRealtimeStartMs ?? this.elapsedRealtimeStartMs,
      wallClockStartMs: wallClockStartMs ?? this.wallClockStartMs,
      accumulatedActiveMs: accumulatedActiveMs ?? this.accumulatedActiveMs,
      accumulatedPausedMs: accumulatedPausedMs ?? this.accumulatedPausedMs,
      lastResumeRealtimeMs: lastResumeRealtimeMs ?? this.lastResumeRealtimeMs,
      lastResumeWallMs: lastResumeWallMs ?? this.lastResumeWallMs,
      pauseStartRealtimeMs: pauseStartRealtimeMs,
      pauseStartWallMs: pauseStartWallMs,
      bootTimeEpochMs: bootTimeEpochMs ?? this.bootTimeEpochMs,
      state: state ?? this.state,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      subjectName: subjectName ?? this.subjectName,
      chapterName: chapterName ?? this.chapterName,
      subtopicName: subtopicName ?? this.subtopicName,
      treeSpecies: treeSpecies ?? this.treeSpecies,
      strictModeEnabled: strictModeEnabled ?? this.strictModeEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mode': mode.name,
      'pomodoroPhase': pomodoroPhase.name,
      'pomodoroCycle': pomodoroCycle,
      'targetSeconds': targetSeconds,
      'elapsedRealtimeStartMs': elapsedRealtimeStartMs,
      'wallClockStartMs': wallClockStartMs,
      'accumulatedActiveMs': accumulatedActiveMs,
      'accumulatedPausedMs': accumulatedPausedMs,
      'lastResumeRealtimeMs': lastResumeRealtimeMs,
      'lastResumeWallMs': lastResumeWallMs,
      'pauseStartRealtimeMs': pauseStartRealtimeMs,
      'pauseStartWallMs': pauseStartWallMs,
      'bootTimeEpochMs': bootTimeEpochMs,
      'state': state.name,
      'linkedTaskId': linkedTaskId,
      'subjectName': subjectName,
      'chapterName': chapterName,
      'subtopicName': subtopicName,
      'treeSpecies': treeSpecies.displayName,
      'strictModeEnabled': strictModeEnabled ? 1 : 0,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ActiveSessionModel.fromMap(Map<String, dynamic> map) {
    return ActiveSessionModel(
      id: map['id'] as String,
      mode: FocusTimerMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => FocusTimerMode.pomodoro,
      ),
      pomodoroPhase: PomodoroPhase.values.firstWhere(
        (e) => e.name == map['pomodoroPhase'],
        orElse: () => PomodoroPhase.work,
      ),
      pomodoroCycle: (map['pomodoroCycle'] as num?)?.toInt() ?? 1,
      targetSeconds: (map['targetSeconds'] as num?)?.toInt() ?? 1500,
      elapsedRealtimeStartMs: (map['elapsedRealtimeStartMs'] as num?)?.toInt() ?? 0,
      wallClockStartMs: (map['wallClockStartMs'] as num?)?.toInt() ?? 0,
      accumulatedActiveMs: (map['accumulatedActiveMs'] as num?)?.toInt() ?? 0,
      accumulatedPausedMs: (map['accumulatedPausedMs'] as num?)?.toInt() ?? 0,
      lastResumeRealtimeMs: (map['lastResumeRealtimeMs'] as num?)?.toInt() ?? 0,
      lastResumeWallMs: (map['lastResumeWallMs'] as num?)?.toInt() ?? 0,
      pauseStartRealtimeMs: (map['pauseStartRealtimeMs'] as num?)?.toInt(),
      pauseStartWallMs: (map['pauseStartWallMs'] as num?)?.toInt(),
      bootTimeEpochMs: (map['bootTimeEpochMs'] as num?)?.toInt() ?? 0,
      state: FocusSessionState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => FocusSessionState.running,
      ),
      linkedTaskId: map['linkedTaskId'] as String?,
      subjectName: map['subjectName'] as String? ?? 'General Study',
      chapterName: map['chapterName'] as String? ?? 'Self Study',
      subtopicName: map['subtopicName'] as String?,
      treeSpecies: TreeSpecies.values.firstWhere(
        (s) => s.displayName == map['treeSpecies'],
        orElse: () => TreeSpecies.cherryBlossom,
      ),
      strictModeEnabled: (map['strictModeEnabled'] as num?)?.toInt() == 1,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
