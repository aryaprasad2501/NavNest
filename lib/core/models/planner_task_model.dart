enum PlannerTaskStatus {
  upcoming,
  inProgress,
  completed,
  missed,
  rescheduled;

  String get code {
    switch (this) {
      case PlannerTaskStatus.upcoming:
        return 'UPCOMING';
      case PlannerTaskStatus.inProgress:
        return 'IN_PROGRESS';
      case PlannerTaskStatus.completed:
        return 'COMPLETED';
      case PlannerTaskStatus.missed:
        return 'MISSED';
      case PlannerTaskStatus.rescheduled:
        return 'RESCHEDULED';
    }
  }

  static PlannerTaskStatus fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'IN_PROGRESS':
        return PlannerTaskStatus.inProgress;
      case 'COMPLETED':
        return PlannerTaskStatus.completed;
      case 'MISSED':
        return PlannerTaskStatus.missed;
      case 'RESCHEDULED':
        return PlannerTaskStatus.rescheduled;
      case 'UPCOMING':
      default:
        return PlannerTaskStatus.upcoming;
    }
  }

  String get label {
    switch (this) {
      case PlannerTaskStatus.upcoming:
        return 'Upcoming';
      case PlannerTaskStatus.inProgress:
        return 'In Progress';
      case PlannerTaskStatus.completed:
        return 'Completed';
      case PlannerTaskStatus.missed:
        return 'Missed';
      case PlannerTaskStatus.rescheduled:
        return 'Rescheduled';
    }
  }
}

class PlannerTaskModel {
  final String id;
  final String date; // YYYY-MM-DD
  final String? subjectId;
  final String? subjectName;
  final String? subjectColorHex;
  final String? chapterId;
  final String? subtopicId;
  final String title;
  final String? startTime; // e.g. "09:00 AM" or "09:00"
  final String? endTime;   // e.g. "10:30 AM" or "10:30"
  final int plannedMinutes;
  final int actualMinutes;
  final PlannerTaskStatus status;
  final String? outcome;
  final String? notes;
  final DateTime createdAt;

  const PlannerTaskModel({
    required this.id,
    required this.date,
    this.subjectId,
    this.subjectName,
    this.subjectColorHex,
    this.chapterId,
    this.subtopicId,
    required this.title,
    this.startTime,
    this.endTime,
    this.plannedMinutes = 45,
    this.actualMinutes = 0,
    this.status = PlannerTaskStatus.upcoming,
    this.outcome,
    this.notes,
    required this.createdAt,
  });

  bool get isCompleted => status == PlannerTaskStatus.completed;
  bool get isMissed => status == PlannerTaskStatus.missed;

  String get displayTimeRange {
    if (startTime != null && endTime != null) {
      return '$startTime - $endTime';
    } else if (startTime != null) {
      return '$startTime ($plannedMinutes min)';
    } else {
      return '$plannedMinutes min block';
    }
  }

  PlannerTaskModel copyWith({
    String? id,
    String? date,
    String? subjectId,
    String? subjectName,
    String? subjectColorHex,
    String? chapterId,
    String? subtopicId,
    String? title,
    String? startTime,
    String? endTime,
    int? plannedMinutes,
    int? actualMinutes,
    PlannerTaskStatus? status,
    String? outcome,
    String? notes,
    DateTime? createdAt,
  }) {
    return PlannerTaskModel(
      id: id ?? this.id,
      date: date ?? this.date,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectColorHex: subjectColorHex ?? this.subjectColorHex,
      chapterId: chapterId ?? this.chapterId,
      subtopicId: subtopicId ?? this.subtopicId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'subjectId': subjectId,
      'chapterId': chapterId,
      'subtopicId': subtopicId,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'plannedMinutes': plannedMinutes,
      'actualMinutes': actualMinutes,
      'status': status.code,
      'outcome': outcome,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlannerTaskModel.fromMap(Map<String, dynamic> map, {String? subjectName, String? subjectColorHex}) {
    return PlannerTaskModel(
      id: map['id'] as String,
      date: map['date'] as String,
      subjectId: map['subjectId'] as String?,
      subjectName: subjectName ?? (map['subjectName'] as String?),
      subjectColorHex: subjectColorHex ?? (map['subjectColorHex'] as String?),
      chapterId: map['chapterId'] as String?,
      subtopicId: map['subtopicId'] as String?,
      title: map['title'] as String,
      startTime: map['startTime'] as String?,
      endTime: map['endTime'] as String?,
      plannedMinutes: (map['plannedMinutes'] as num?)?.toInt() ?? 45,
      actualMinutes: (map['actualMinutes'] as num?)?.toInt() ?? 0,
      status: PlannerTaskStatus.fromCode(map['status'] as String? ?? 'UPCOMING'),
      outcome: map['outcome'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
