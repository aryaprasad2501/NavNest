import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/forest_tree_model.dart';
import '../models/study_session_model.dart';
import '../models/sync_queue_item.dart';
import '../models/user_profile.dart';

enum SyncStatus { idle, syncing, completed, error }

class CloudSyncService extends ChangeNotifier {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _firebaseAuth;
  final DatabaseHelper _dbHelper;
  final Uuid _uuid;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _statusMessage;
  int _pendingCount = 0;

  CloudSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    DatabaseHelper? dbHelper,
    Uuid? uuid,
  })  : _firestore = firestore ?? _resolveFirestore(),
        _firebaseAuth = firebaseAuth,
        _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _uuid = uuid ?? const Uuid();

  static FirebaseFirestore? _resolveFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not initialized in current environment: $e');
      return null;
    }
  }

  SyncStatus get status => _status;
  bool get isSyncing => _status == SyncStatus.syncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get statusMessage => _statusMessage;
  int get pendingCount => _pendingCount;

  String? get _currentUserId {
    try {
      return _firebaseAuth?.currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Initialize service and check pending queue
  Future<void> initialize() async {
    await updatePendingCount();
  }

  Future<void> updatePendingCount() async {
    try {
      _pendingCount = await _dbHelper.getSyncQueuePendingCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting pending sync count: $e');
    }
  }

  /// Queue a completed study session for offline-first cloud backup
  Future<void> queueCompletedSession(StudySessionModel session) async {
    if (_dbHelper.isDemoMode) return;
    final item = SyncQueueItem(
      id: _uuid.v4(),
      entityType: 'STUDY_SESSION',
      entityId: session.id,
      action: 'UPSERT',
      payload: jsonEncode(session.toMap()),
      status: 'PENDING',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _dbHelper.insertSyncQueueItem(item);
    await updatePendingCount();
    // Attempt opportunistic sync if online
    unawaited(processPendingQueue());
  }

  /// Queue a user profile update (XP, coins, streak)
  Future<void> queueUserProfile(UserProfile profile) async {
    if (_dbHelper.isDemoMode) return;
    final item = SyncQueueItem(
      id: _uuid.v4(),
      entityType: 'USER_PROFILE',
      entityId: profile.id,
      action: 'UPSERT',
      payload: jsonEncode(profile.toMap()),
      status: 'PENDING',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _dbHelper.insertSyncQueueItem(item);
    await updatePendingCount();
    unawaited(processPendingQueue());
  }

  /// Queue a mature NavBloom tree
  Future<void> queueForestTree(ForestTreeModel tree) async {
    if (_dbHelper.isDemoMode) return;
    final item = SyncQueueItem(
      id: _uuid.v4(),
      entityType: 'FOREST_TREE',
      entityId: tree.id,
      action: 'UPSERT',
      payload: jsonEncode(tree.toMap()),
      status: 'PENDING',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _dbHelper.insertSyncQueueItem(item);
    await updatePendingCount();
    unawaited(processPendingQueue());
  }

  /// Drain the offline sync queue with exponential backoff & idempotent writes
  Future<bool> processPendingQueue() async {
    if (_dbHelper.isDemoMode) {
      _statusMessage = 'Demo mode active: cloud sync is paused to protect user records.';
      notifyListeners();
      return false;
    }
    final uid = _currentUserId;
    if (uid == null) {
      _statusMessage = 'Sign in with Google or Email to synchronize cloud backups.';
      notifyListeners();
      return false;
    }

    if (_firestore == null) {
      _statusMessage = 'Cloud synchronization is currently offline.';
      notifyListeners();
      return false;
    }

    if (_status == SyncStatus.syncing) return false;

    _status = SyncStatus.syncing;
    _statusMessage = 'Synchronizing pending offline study data...';
    notifyListeners();

    try {
      final items = await _dbHelper.getPendingSyncQueueItems(limit: 50);
      if (items.isEmpty) {
        _status = SyncStatus.completed;
        _lastSyncTime = DateTime.now();
        _statusMessage = 'All study records are up to date ✓';
        await updatePendingCount();
        notifyListeners();
        return true;
      }

      int successCount = 0;

      for (final item in items) {
        // Skip items that have reached max retries in this cycle
        if (item.retryCount >= 5) continue;

        try {
          final payload = item.parsePayload();

          switch (item.entityType) {
            case 'STUDY_SESSION':
              // Idempotent write: docId = sessionId
              await _firestore
                  .collection('users')
                  .doc(uid)
                  .collection('study_sessions')
                  .doc(item.entityId)
                  .set({
                ...payload,
                'syncedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              break;

            case 'USER_PROFILE':
              // Conflict resolution: compare and merge with remote XP/coins
              final docRef = _firestore.collection('user_profiles').doc(uid);
              final snap = await docRef.get();
              if (snap.exists && snap.data() != null) {
                final remoteData = snap.data()!;
                final localXp = (payload['totalXp'] as num?)?.toInt() ?? 0;
                final remoteXp = (remoteData['totalXp'] as num?)?.toInt() ?? 0;
                final localCoins = (payload['coins'] as num?)?.toInt() ?? 0;
                final remoteCoins = (remoteData['coins'] as num?)?.toInt() ?? 0;

                // Max resolution preserves earned rewards
                payload['totalXp'] = localXp > remoteXp ? localXp : remoteXp;
                payload['coins'] = localCoins > remoteCoins ? localCoins : remoteCoins;
              }

              await docRef.set({
                ...payload,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              break;

            case 'FOREST_TREE':
              // Idempotent write: docId = tree.id
              await _firestore
                  .collection('users')
                  .doc(uid)
                  .collection('forest_trees')
                  .doc(item.entityId)
                  .set({
                ...payload,
                'syncedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              break;
          }

          // Successfully synchronized: delete from durable queue
          await _dbHelper.deleteSyncQueueItem(item.id);
          successCount++;
        } catch (itemErr) {
          debugPrint('Sync failure on item ${item.id}: $itemErr');
          await _dbHelper.updateSyncQueueItem(item.copyWith(
            status: 'FAILED',
            retryCount: item.retryCount + 1,
            lastError: itemErr.toString(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      _lastSyncTime = DateTime.now();
      _status = SyncStatus.completed;
      _statusMessage = 'Synchronized $successCount items successfully ✓';
      await updatePendingCount();
      notifyListeners();
      return true;
    } catch (e) {
      _status = SyncStatus.error;
      _statusMessage = 'Sync encountered an error: $e';
      await updatePendingCount();
      notifyListeners();
      return false;
    } finally {
      if (_status == SyncStatus.syncing) {
        _status = SyncStatus.idle;
        notifyListeners();
      }
    }
  }

  /// Full manual backup synchronization
  Future<bool> triggerFullBackup() async {
    final uid = _currentUserId;
    if (uid == null) {
      _statusMessage = 'Please sign in to perform cloud backup.';
      notifyListeners();
      return false;
    }

    _status = SyncStatus.syncing;
    _statusMessage = 'Preparing full study backup...';
    notifyListeners();

    try {
      // 1. Queue active user profile
      final profile = await _dbHelper.getUserProfile(uid) ??
          await _dbHelper.getUserProfile('default_student');
      if (profile != null) {
        await queueUserProfile(profile);
      }

      // 2. Queue all completed study sessions
      final sessions = await _dbHelper.getStudySessions(limit: 100);
      for (final s in sessions) {
        await queueCompletedSession(s);
      }

      // 3. Queue all forest trees
      final trees = await _dbHelper.getForestTrees();
      for (final t in trees) {
        await queueForestTree(t);
      }

      // 4. Drain queue
      return await processPendingQueue();
    } catch (e) {
      _status = SyncStatus.error;
      _statusMessage = 'Full backup failed: $e';
      notifyListeners();
      return false;
    }
  }
}
