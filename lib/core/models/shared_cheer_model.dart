import 'package:cloud_firestore/cloud_firestore.dart';

class SharedCheerModel {
  final String id;
  final String spaceId;
  final String senderUid;
  final String senderName;
  final String emoji;
  final String message;
  final DateTime createdAt;

  const SharedCheerModel({
    required this.id,
    required this.spaceId,
    required this.senderUid,
    required this.senderName,
    required this.emoji,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'spaceId': spaceId,
      'senderUid': senderUid,
      'senderName': senderName,
      'emoji': emoji,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SharedCheerModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return SharedCheerModel(
      id: docId,
      spaceId: map['spaceId'] as String? ?? '',
      senderUid: map['senderUid'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'Study Partner',
      emoji: map['emoji'] as String? ?? '👏',
      message: map['message'] as String? ?? 'Keep going!',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is String
              ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
              : DateTime.now()),
    );
  }
}
