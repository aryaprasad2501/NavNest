import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedSpaceModel {
  final String id;
  final String name;
  final String inviteCode;
  final String createdByUserId;
  final List<String> memberIds;
  final Map<String, dynamic> memberProfiles; // {uid: {'displayName': '...', 'email': '...'}}
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
    this.memberProfiles = const {},
    this.totalForestTrees = 0,
    this.combinedFocusMinutes = 0,
    this.sharedExamName,
    this.sharedExamDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaired => memberIds.length >= 2;

  bool isMember(String userId) => memberIds.contains(userId);

  String getPartnerId(String currentUserId) {
    return memberIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  String getPartnerName(String currentUserId, {String defaultFallback = 'Study Partner 🌿'}) {
    final partnerId = getPartnerId(currentUserId);
    if (partnerId.isEmpty) return '';
    final profile = memberProfiles[partnerId];
    if (profile is Map && profile['displayName'] != null && profile['displayName'].toString().isNotEmpty) {
      return profile['displayName'].toString();
    }
    return defaultFallback;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'createdByUserId': createdByUserId,
      'memberIds': memberIds.join(','),
      'memberProfiles': jsonEncode(memberProfiles),
      'totalForestTrees': totalForestTrees,
      'combinedFocusMinutes': combinedFocusMinutes,
      'sharedExamName': sharedExamName,
      'sharedExamDate': sharedExamDate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'createdByUserId': createdByUserId,
      'memberIds': memberIds,
      'memberProfiles': memberProfiles,
      'totalForestTrees': totalForestTrees,
      'combinedFocusMinutes': combinedFocusMinutes,
      'sharedExamName': sharedExamName,
      'sharedExamDate': sharedExamDate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
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

    Map<String, dynamic> profiles = {};
    final rawProfiles = map['memberProfiles'];
    if (rawProfiles is String && rawProfiles.isNotEmpty) {
      try {
        profiles = Map<String, dynamic>.from(jsonDecode(rawProfiles) as Map);
      } catch (_) {}
    } else if (rawProfiles is Map) {
      profiles = Map<String, dynamic>.from(rawProfiles);
    }

    return SharedSpaceModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Shared Grove',
      inviteCode: map['inviteCode'] as String? ?? '',
      createdByUserId: map['createdByUserId'] as String? ?? '',
      memberIds: parsedMemberIds,
      memberProfiles: profiles,
      totalForestTrees: (map['totalForestTrees'] as num?)?.toInt() ?? 0,
      combinedFocusMinutes: (map['combinedFocusMinutes'] as num?)?.toInt() ?? 0,
      sharedExamName: map['sharedExamName'] as String?,
      sharedExamDate: map['sharedExamDate'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory SharedSpaceModel.fromFirestore(Map<String, dynamic> map, String docId) {
    final memberIdsRaw = map['memberIds'];
    List<String> parsedMemberIds = [];
    if (memberIdsRaw is List) {
      parsedMemberIds = memberIdsRaw.map((e) => e.toString()).toList();
    } else if (memberIdsRaw is String) {
      parsedMemberIds = memberIdsRaw.split(',').where((s) => s.isNotEmpty).toList();
    }

    Map<String, dynamic> profiles = {};
    if (map['memberProfiles'] is Map) {
      profiles = Map<String, dynamic>.from(map['memberProfiles'] as Map);
    }

    return SharedSpaceModel(
      id: docId,
      name: map['name'] as String? ?? 'Shared Grove',
      inviteCode: map['inviteCode'] as String? ?? '',
      createdByUserId: map['createdByUserId'] as String? ?? '',
      memberIds: parsedMemberIds,
      memberProfiles: profiles,
      totalForestTrees: (map['totalForestTrees'] as num?)?.toInt() ?? 0,
      combinedFocusMinutes: (map['combinedFocusMinutes'] as num?)?.toInt() ?? 0,
      sharedExamName: map['sharedExamName'] as String?,
      sharedExamDate: map['sharedExamDate'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  SharedSpaceModel copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? createdByUserId,
    List<String>? memberIds,
    Map<String, dynamic>? memberProfiles,
    int? totalForestTrees,
    int? combinedFocusMinutes,
    String? sharedExamName,
    String? sharedExamDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SharedSpaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      memberIds: memberIds ?? this.memberIds,
      memberProfiles: memberProfiles ?? this.memberProfiles,
      totalForestTrees: totalForestTrees ?? this.totalForestTrees,
      combinedFocusMinutes: combinedFocusMinutes ?? this.combinedFocusMinutes,
      sharedExamName: sharedExamName ?? this.sharedExamName,
      sharedExamDate: sharedExamDate ?? this.sharedExamDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
