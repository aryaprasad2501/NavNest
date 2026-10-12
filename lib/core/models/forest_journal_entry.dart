class ForestJournalEntry {
  final String id;
  final String title;
  final String category; // 'PLANTING', 'BLOOM', 'MILESTONE', 'ACHIEVEMENT'
  final DateTime date;
  final String? subjectName;
  final int focusMinutes;
  final int xpEarned;
  final int coinsEarned;
  final String? notes;

  const ForestJournalEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.subjectName,
    required this.focusMinutes,
    required this.xpEarned,
    required this.coinsEarned,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'subjectName': subjectName,
      'focusMinutes': focusMinutes,
      'xpEarned': xpEarned,
      'coinsEarned': coinsEarned,
      'notes': notes,
    };
  }

  factory ForestJournalEntry.fromMap(Map<String, dynamic> map) {
    return ForestJournalEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'PLANTING',
      date: DateTime.parse(map['date'] as String),
      subjectName: map['subjectName'] as String?,
      focusMinutes: (map['focusMinutes'] as num?)?.toInt() ?? 0,
      xpEarned: (map['xpEarned'] as num?)?.toInt() ?? 0,
      coinsEarned: (map['coinsEarned'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String?,
    );
  }

  ForestJournalEntry copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? date,
    String? subjectName,
    int? focusMinutes,
    int? xpEarned,
    int? coinsEarned,
    String? notes,
  }) {
    return ForestJournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      subjectName: subjectName ?? this.subjectName,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      xpEarned: xpEarned ?? this.xpEarned,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      notes: notes ?? this.notes,
    );
  }
}
