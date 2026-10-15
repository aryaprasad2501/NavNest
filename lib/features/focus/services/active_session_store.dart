import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/active_session_model.dart';
import '../../../core/database/database_helper.dart';

class ActiveSessionStore {
  static const String _prefsKey = 'navnest_active_session_state';
  final DatabaseHelper _dbHelper;

  ActiveSessionStore({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Ensures SQLite table for active session exists.
  Future<void> ensureTableExists([Database? targetDb]) async {
    final db = targetDb ?? await _dbHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_focus_session (
        id TEXT PRIMARY KEY,
        mode TEXT NOT NULL,
        pomodoroPhase TEXT NOT NULL DEFAULT 'work',
        pomodoroCycle INTEGER NOT NULL DEFAULT 1,
        targetSeconds INTEGER NOT NULL,
        elapsedRealtimeStartMs INTEGER NOT NULL,
        wallClockStartMs INTEGER NOT NULL,
        accumulatedActiveMs INTEGER NOT NULL DEFAULT 0,
        accumulatedPausedMs INTEGER NOT NULL DEFAULT 0,
        lastResumeRealtimeMs INTEGER NOT NULL,
        lastResumeWallMs INTEGER NOT NULL,
        pauseStartRealtimeMs INTEGER,
        pauseStartWallMs INTEGER,
        bootTimeEpochMs INTEGER NOT NULL,
        state TEXT NOT NULL,
        linkedTaskId TEXT,
        subjectName TEXT NOT NULL,
        chapterName TEXT NOT NULL,
        subtopicName TEXT,
        treeSpecies TEXT NOT NULL DEFAULT 'Cherry Blossom',
        strictModeEnabled INTEGER NOT NULL DEFAULT 0,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  /// Persists active session atomically to both SharedPreferences and SQLite.
  Future<void> persistSession(ActiveSessionModel session, [Database? targetDb]) async {
    final map = session.toMap();

    // 1. SharedPreferences fast-path
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (_) {}

    // 2. Durable SQLite persistence
    try {
      final db = targetDb ?? await _dbHelper.database;
      await ensureTableExists(db);
      await db.insert(
        'active_focus_session',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Loads active session from persistence.
  Future<ActiveSessionModel?> loadActiveSession([Database? targetDb]) async {
    // 1. Try SQLite first
    try {
      final db = targetDb ?? await _dbHelper.database;
      await ensureTableExists(db);
      final results = await db.query(
        'active_focus_session',
        orderBy: 'updatedAt DESC',
        limit: 1,
      );
      if (results.isNotEmpty) {
        return ActiveSessionModel.fromMap(results.first);
      }
    } catch (_) {}

    // 2. Fallback to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return ActiveSessionModel.fromMap(decoded);
      }
    } catch (_) {}

    return null;
  }

  /// Clears active session upon clean completion or explicit cancellation.
  Future<void> clearActiveSession([Database? targetDb]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}

    try {
      final db = targetDb ?? await _dbHelper.database;
      await ensureTableExists(db);
      await db.delete('active_focus_session');
    } catch (_) {}
  }
}
