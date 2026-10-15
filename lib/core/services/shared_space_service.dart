import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/shared_cheer_model.dart';
import '../models/shared_space_invite_model.dart';
import '../models/shared_space_model.dart';
import '../services/local_storage_service.dart';

class SharedSpaceService {
  final FirebaseFirestore? _firestore;
  final DatabaseHelper _dbHelper;
  final LocalStorageService _storage;
  final Uuid _uuid;

  SharedSpaceService({
    FirebaseFirestore? firestore,
    DatabaseHelper? dbHelper,
    required LocalStorageService storage,
    Uuid? uuid,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _storage = storage,
        _uuid = uuid ?? const Uuid(),
        _firestore = firestore ?? _resolveFirestore();

  static FirebaseFirestore? _resolveFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not initialized in current environment: $e');
      return null;
    }
  }

  /// Collection references
  CollectionReference<Map<String, dynamic>>? get _spacesRef =>
      _firestore?.collection('shared_spaces');

  CollectionReference<Map<String, dynamic>>? get _invitesRef =>
      _firestore?.collection('shared_space_invites');

  /// Generate a cryptographically secure, unpredictable invite code
  /// Format: NEST-XXXXXX (e.g. NEST-7M9K2P) excluding ambiguous characters (0, O, 1, I)
  String generateSecureInviteCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random.secure();
    final codeBuffer = StringBuffer('NEST-');
    for (int i = 0; i < 6; i++) {
      codeBuffer.write(chars[random.nextInt(chars.length)]);
    }
    return codeBuffer.toString();
  }

  /// 1. Create a secure pairing invitation code
  Future<SharedSpaceInviteModel> createInvitation({
    required String creatorUid,
    required String creatorName,
    String? existingSpaceId,
    String? spaceName,
  }) async {
    final inviteCode = generateSecureInviteCode();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 48)); // 48 hours validity

    String spaceId = existingSpaceId ?? '';

    // If space does not exist yet, create or retrieve local active space
    if (spaceId.isEmpty) {
      final localSpace = await _dbHelper.getActiveSharedSpace();
      if (localSpace != null) {
        spaceId = localSpace.id;
      } else {
        spaceId = 'space_${_uuid.v4()}';
        final newSpace = SharedSpaceModel(
          id: spaceId,
          name: spaceName ?? '$creatorName\'s Study Grove',
          inviteCode: inviteCode,
          createdByUserId: creatorUid,
          memberIds: [creatorUid],
          memberProfiles: {
            creatorUid: {
              'displayName': creatorName,
              'joinedAt': now.toIso8601String(),
            },
          },
          createdAt: now,
          updatedAt: now,
        );

        // Save locally to SQLite immediately
        await _dbHelper.saveSharedSpace(newSpace);
        await _storage.setSharedInviteCode(inviteCode);

        // Save to Firestore if available
        if (_spacesRef != null) {
          await _spacesRef!.doc(spaceId).set(newSpace.toFirestore(), SetOptions(merge: true));
        }
      }
    }

    final invite = SharedSpaceInviteModel(
      inviteCode: inviteCode,
      spaceId: spaceId,
      creatorUid: creatorUid,
      creatorName: creatorName,
      status: 'ACTIVE',
      createdAt: now,
      expiresAt: expiresAt,
    );

    // Save invite document in Firestore if available
    if (_invitesRef != null) {
      await _invitesRef!.doc(inviteCode).set(invite.toFirestore());
    }

    // Update activeInviteCode on the space document if available
    if (_spacesRef != null) {
      await _spacesRef!.doc(spaceId).update({
        'activeInviteCode': inviteCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await _storage.setSharedInviteCode(inviteCode);
    return invite;
  }

  /// 2. Join a private Shared Space with an invite code via atomic transaction
  Future<SharedSpaceModel> joinSpaceWithCode({
    required String inviteCode,
    required String joiningUid,
    required String joiningName,
  }) async {
    final normalizedCode = inviteCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw ArgumentError('Invite code cannot be empty.');
    }

    if (_firestore == null || _invitesRef == null || _spacesRef == null) {
      throw StateError('Firebase connection is required to join a shared space.');
    }

    return await _firestore.runTransaction<SharedSpaceModel>((transaction) async {
      // Step A: Read invite doc
      final inviteDocRef = _invitesRef!.doc(normalizedCode);
      final inviteSnapshot = await transaction.get(inviteDocRef);

      if (!inviteSnapshot.exists || inviteSnapshot.data() == null) {
        throw StateError('Invalid invite code. Please verify the code and try again.');
      }

      final inviteData = inviteSnapshot.data()!;
      final inviteModel = SharedSpaceInviteModel.fromFirestore(inviteData, normalizedCode);

      // Validate invite integrity
      if (!inviteModel.isValid) {
        if (inviteModel.isExpired) {
          throw StateError('This invite code has expired. Please ask your partner to generate a new one.');
        }
        throw StateError('This invite code is no longer active or has already been used.');
      }

      if (inviteModel.creatorUid == joiningUid) {
        throw StateError('You cannot pair with your own invite code. Share it with your study partner.');
      }

      // Step B: Read space doc
      final spaceDocRef = _spacesRef!.doc(inviteModel.spaceId);
      final spaceSnapshot = await transaction.get(spaceDocRef);

      if (!spaceSnapshot.exists || spaceSnapshot.data() == null) {
        throw StateError('The target Shared Space was not found.');
      }

      final spaceData = spaceSnapshot.data()!;
      final existingSpace = SharedSpaceModel.fromFirestore(spaceData, spaceDocRef.id);

      // Idempotency: If user is already a member, return cleanly
      if (existingSpace.memberIds.contains(joiningUid)) {
        return existingSpace;
      }

      // Security Constraint: Strictly 1-on-1 private space (Maximum 2 members)
      if (existingSpace.memberIds.length >= 2) {
        throw StateError('This Shared Space is already full (maximum 2 study partners).');
      }

      final now = DateTime.now();

      // Step C: Atomically update invite doc to mark as consumed
      transaction.update(inviteDocRef, {
        'status': 'ACCEPTED',
        'claimedByUid': joiningUid,
        'claimedAt': FieldValue.serverTimestamp(),
      });

      // Step D: Atomically update space doc with new member
      final updatedMemberIds = List<String>.from(existingSpace.memberIds)..add(joiningUid);
      final updatedProfiles = Map<String, dynamic>.from(existingSpace.memberProfiles);
      updatedProfiles[joiningUid] = {
        'displayName': joiningName,
        'joinedAt': now.toIso8601String(),
      };

      transaction.update(spaceDocRef, {
        'memberIds': FieldValue.arrayUnion([joiningUid]),
        'memberProfiles': updatedProfiles,
        'activeInviteCode': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updatedSpace = existingSpace.copyWith(
        memberIds: updatedMemberIds,
        memberProfiles: updatedProfiles,
        updatedAt: now,
      );

      return updatedSpace;
    }).then((space) async {
      // Post-transaction local persistence
      await _dbHelper.saveSharedSpace(space);
      await _storage.setSharedPaired(true);
      await _storage.setSharedPartnerName(space.getPartnerName(joiningUid));
      return space;
    });
  }

  /// 3. Leave / Disconnect from Shared Space
  Future<void> leaveSpace({
    required String spaceId,
    required String userId,
  }) async {
    try {
      if (_spacesRef != null) {
        final docRef = _spacesRef!.doc(spaceId);
        final snapshot = await docRef.get();
        if (snapshot.exists && snapshot.data() != null) {
          final space = SharedSpaceModel.fromFirestore(snapshot.data()!, spaceId);
          final remainingMemberIds = space.memberIds.where((id) => id != userId).toList();
          final updatedProfiles = Map<String, dynamic>.from(space.memberProfiles)..remove(userId);

          await docRef.update({
            'memberIds': remainingMemberIds,
            'memberProfiles': updatedProfiles,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Cloud unpair error (handled gracefully): $e');
    } finally {
      // Local personal records are always preserved safely
      await _dbHelper.clearSharedSpace();
      await _storage.clearSharedSpaceData();
    }
  }

  /// 4. Send a pre-written encouragement cheer to partner
  Future<SharedCheerModel> sendCheer({
    required String spaceId,
    required String senderUid,
    required String senderName,
    required String emoji,
    required String message,
  }) async {
    final cheerId = 'cheer_${_uuid.v4()}';
    final cheer = SharedCheerModel(
      id: cheerId,
      spaceId: spaceId,
      senderUid: senderUid,
      senderName: senderName,
      emoji: emoji,
      message: message,
      createdAt: DateTime.now(),
    );

    if (_spacesRef != null) {
      await _spacesRef!
          .doc(spaceId)
          .collection('cheers')
          .doc(cheerId)
          .set(cheer.toFirestore());
    }

    return cheer;
  }

  /// 5. Update partner real-time accountability status
  Future<void> updateMemberStatus({
    required String spaceId,
    required String uid,
    required String displayName,
    required bool isFocusing,
    String? currentSubject,
    required int todayFocusMinutes,
    required int todayTreesCount,
  }) async {
    try {
      if (_spacesRef != null) {
        await _spacesRef!
            .doc(spaceId)
            .collection('member_status')
            .doc(uid)
            .set({
          'uid': uid,
          'displayName': displayName,
          'isFocusing': isFocusing,
          'currentSubject': currentSubject,
          'todayFocusMinutes': todayFocusMinutes,
          'todayTreesCount': todayTreesCount,
          'lastActiveAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Status update error: $e');
    }
  }

  /// Stream of active Shared Space
  Stream<SharedSpaceModel?> watchSharedSpace(String spaceId) {
    if (spaceId.isEmpty || _spacesRef == null) return Stream.value(null);
    return _spacesRef!.doc(spaceId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return SharedSpaceModel.fromFirestore(snapshot.data()!, snapshot.id);
    });
  }

  /// Stream of cheers
  Stream<List<SharedCheerModel>> watchCheers(String spaceId, {int limit = 20}) {
    if (spaceId.isEmpty || _spacesRef == null) return Stream.value([]);
    return _spacesRef!
        .doc(spaceId)
        .collection('cheers')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SharedCheerModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream of partner member status
  Stream<Map<String, dynamic>?> watchPartnerStatus(String spaceId, String partnerUid) {
    if (spaceId.isEmpty || partnerUid.isEmpty || _spacesRef == null) return Stream.value(null);
    return _spacesRef!
        .doc(spaceId)
        .collection('member_status')
        .doc(partnerUid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
}
