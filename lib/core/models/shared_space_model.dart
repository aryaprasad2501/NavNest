class SharedSpaceModel {
  final String id;
  final String name;
  final String inviteCode;
  final String createdByUserId;
  final List<String> memberIds;
  final int totalForestTrees;
  final int combinedFocusMinutes;
  final String? sharedExamName;
  final String? sharedExamDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SharedSpaceModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdByUserId,
    required this.memberIds,
    this.totalForestTrees = 0,
    this.combinedFocusMinutes = 0,
    this.sharedExamName,
    this.sharedExamDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'createdByUserId': createdByUserId,
      'memberIds': memberIds.join(','),
      'totalForestTrees': totalForestTrees,
      'combinedFocusMinutes': combinedFocusMinutes,
      'sharedExamName': sharedExamName,
      'sharedExamDate': sharedExamDate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SharedSpaceModel.fromMap(Map<String, dynamic> map) {
    final memberIdsRaw = map['memberIds'];
    List<String> parsedMemberIds = [];
    if (memberIdsRaw is String) {
      parsedMemberIds = memberIdsRaw.split(',').where((s) => s.isNotEmpty).toList();
    } else if (memberIdsRaw is List) {
      parsedMemberIds = memberIdsRaw.map((e) => e.toString()).toList();
    }

    return SharedSpaceModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Shared Grove',
      inviteCode: map['inviteCode'] as String? ?? '',
      createdByUserId: map['createdByUserId'] as String? ?? '',
      memberIds: parsedMemberIds,
      totalForestTrees: (map['totalForestTrees'] as num?)?.toInt() ?? 0,
      combinedFocusMinutes: (map['combinedFocusMinutes'] as num?)?.toInt() ?? 0,
      sharedExamName: map['sharedExamName'] as String?,
      sharedExamDate: map['sharedExamDate'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
