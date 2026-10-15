import 'package:cloud_firestore/cloud_firestore.dart';

class SharedSpaceInviteModel {
  final String inviteCode; // e.g. 'NEST-8492K'
  final String spaceId;
  final String creatorUid;
  final String creatorName;
  final String status; // 'ACTIVE', 'ACCEPTED', 'EXPIRED', 'REVOKED'
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? claimedByUid;
  final DateTime? claimedAt;

  const SharedSpaceInviteModel({
    required this.inviteCode,
    required this.spaceId,
    required this.creatorUid,
    required this.creatorName,
    this.status = 'ACTIVE',
    required this.createdAt,
    required this.expiresAt,
    this.claimedByUid,
    this.claimedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => status == 'ACTIVE' && !isExpired;

  Map<String, dynamic> toFirestore() {
    return {
      'inviteCode': inviteCode,
      'spaceId': spaceId,
      'creatorUid': creatorUid,
      'creatorName': creatorName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'claimedByUid': claimedByUid,
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
    };
  }

  factory SharedSpaceInviteModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return SharedSpaceInviteModel(
      inviteCode: docId,
      spaceId: map['spaceId'] as String? ?? '',
      creatorUid: map['creatorUid'] as String? ?? '',
      creatorName: map['creatorName'] as String? ?? 'Study Partner',
      status: map['status'] as String? ?? 'ACTIVE',
      createdAt: _parseDateTime(map['createdAt']),
      expiresAt: _parseDateTime(map['expiresAt']),
      claimedByUid: map['claimedByUid'] as String?,
      claimedAt: map['claimedAt'] != null ? _parseDateTime(map['claimedAt']) : null,
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}
