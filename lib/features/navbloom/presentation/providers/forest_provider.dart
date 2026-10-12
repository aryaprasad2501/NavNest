import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/models/achievement_model.dart';
import '../../../../core/models/forest_decoration_model.dart';
import '../../../../core/models/forest_journal_entry.dart';
import '../../../../core/models/forest_tree_model.dart';
import '../../../../core/models/user_profile.dart';

class ForestProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  List<ForestTreeModel> _trees = [];
  List<ForestDecorationModel> _decorations = [];
  List<ForestJournalEntry> _journalEntries = [];
  List<AchievementModel> _achievements = [];
  UserProfile? _userProfile;

  bool _isMoonlitNight = false;
  bool _isLoading = false;
  String _selectedAreaId = 'area_1';

  ForestProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // --- Getters ---
  List<ForestTreeModel> get trees => List.unmodifiable(_trees);
  List<ForestDecorationModel> get decorations => List.unmodifiable(_decorations);
  List<ForestJournalEntry> get journalEntries => List.unmodifiable(_journalEntries);
  List<AchievementModel> get achievements => List.unmodifiable(_achievements);
  UserProfile? get userProfile => _userProfile;

  bool get isMoonlitNight => _isMoonlitNight;
  bool get isLoading => _isLoading;
  String get selectedAreaId => _selectedAreaId;

  int get userCoins => _userProfile?.coins ?? 120;
  int get userXp => _userProfile?.totalXp ?? 450;
  int get userStreak => _userProfile?.streakDays ?? 1;

  int get userLevel => ((userXp) / 250).floor() + 1;
  double get userLevelProgress => ((userXp % 250) / 250.0).clamp(0.0, 1.0);

  int get totalTreesCount => _trees.length;
  int get matureTreesCount => _trees.where((t) => t.isMatured).length;
  int get totalFocusMinutes => _trees.fold(0, (sum, t) => sum + t.focusMinutes);

  List<ForestDecorationModel> get equippedDecorations =>
      _decorations.where((d) => d.isEquipped).toList();

  @visibleForTesting
  void setForestDataForTesting({
    List<ForestTreeModel>? trees,
    List<ForestDecorationModel>? decorations,
    List<ForestJournalEntry>? journalEntries,
    List<AchievementModel>? achievements,
    UserProfile? userProfile,
  }) {
    if (trees != null) _trees = List.from(trees);
    if (decorations != null) _decorations = List.from(decorations);
    if (journalEntries != null) _journalEntries = List.from(journalEntries);
    if (achievements != null) _achievements = List.from(achievements);
    if (userProfile != null) _userProfile = userProfile;
    notifyListeners();
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _dbHelper.saveUserProfile(profile);
    notifyListeners();
  }

  // --- Initialization & Data Fetching ---
  Future<void> loadForestData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _trees = await _dbHelper.getForestTrees();
      _decorations = await _dbHelper.getDecorations();
      _journalEntries = await _dbHelper.getJournalEntries();
      _achievements = await _dbHelper.getAchievements();

      _userProfile = await _dbHelper.getUserProfile('default_student');
      if (_userProfile == null) {
        _userProfile = UserProfile.defaultProfile();
        await _dbHelper.saveUserProfile(_userProfile!);
      }
    } catch (e) {
      debugPrint('Error loading forest data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Tree Operations ---
  Future<ForestTreeModel> plantTree({
    required TreeSpecies species,
    required String subjectName,
    required String chapterName,
    required int focusMinutes,
    double? xRatio,
    double? yRatio,
  }) async {
    // Determine growth stage based on focus session length
    int stage;
    if (focusMinutes >= 90) {
      stage = 5; // Full Bloom
    } else if (focusMinutes >= 60) {
      stage = 4; // Young Tree
    } else if (focusMinutes >= 40) {
      stage = 3; // Sapling
    } else if (focusMinutes >= 20) {
      stage = 2; // Sprout
    } else {
      stage = 1; // Seed
    }

    final xpEarned = focusMinutes * 2 + (stage >= 5 ? 60 : 25);
    final coinsEarned = (focusMinutes * 0.5).round() + (stage >= 5 ? 20 : 5);

    // Coordinate placement
    final rand = Random();
    final finalX = xRatio ?? (0.22 + rand.nextDouble() * 0.56);
    final finalY = yRatio ?? (0.42 + rand.nextDouble() * 0.32);

    final now = DateTime.now();
    final newTree = ForestTreeModel(
      id: 'tree_${now.millisecondsSinceEpoch}',
      species: species,
      stage: stage,
      xRatio: double.parse(finalX.toStringAsFixed(3)),
      yRatio: double.parse(finalY.toStringAsFixed(3)),
      plantedAt: now,
      maturedAt: stage >= 5 ? now : null,
      subjectName: subjectName,
      chapterName: chapterName,
      focusMinutes: focusMinutes,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      status: 'HEALTHY',
    );

    await _dbHelper.insertForestTree(newTree);

    // Record Journal Entry
    final journal = ForestJournalEntry(
      id: 'j_${now.millisecondsSinceEpoch}',
      title: stage >= 5
          ? '${species.displayName} bloomed to Full Bloom! ${species.iconEmoji}'
          : 'Planted ${species.displayName} in Sanctuary ${species.iconEmoji}',
      category: stage >= 5 ? 'BLOOM' : 'PLANTING',
      date: now,
      subjectName: subjectName,
      focusMinutes: focusMinutes,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      notes: 'Completed $focusMinutes min study on $subjectName: $chapterName',
    );
    await _dbHelper.insertJournalEntry(journal);

    // Update User Profile Coins and XP
    if (_userProfile != null) {
      final updatedProfile = _userProfile!.copyWith(
        totalXp: _userProfile!.totalXp + xpEarned,
        coins: _userProfile!.coins + coinsEarned,
        updatedAt: now,
      );
      _userProfile = updatedProfile;
      await _dbHelper.saveUserProfile(updatedProfile);
    }

    // Refresh & evaluate achievements
    await _evaluateAchievements();
    await loadForestData();

    return newTree;
  }

  Future<void> nurtureTree(String treeId) async {
    final index = _trees.indexWhere((t) => t.id == treeId);
    if (index == -1) return;

    final tree = _trees[index];
    if (tree.stage >= 5) return; // Already full bloom

    final newStage = tree.stage + 1;
    final now = DateTime.now();
    const bonusXp = 40;
    const bonusCoins = 15;

    final updatedTree = tree.copyWith(
      stage: newStage,
      maturedAt: newStage == 5 ? now : tree.maturedAt,
      xpEarned: tree.xpEarned + bonusXp,
      coinsEarned: tree.coinsEarned + bonusCoins,
    );

    await _dbHelper.updateForestTree(updatedTree);

    // Add journal entry
    final journal = ForestJournalEntry(
      id: 'j_${now.millisecondsSinceEpoch}',
      title: newStage == 5
          ? '${tree.species.displayName} reached Full Bloom! 🌸'
          : 'Nurtured ${tree.species.displayName} to Stage $newStage 🌱',
      category: newStage == 5 ? 'BLOOM' : 'PLANTING',
      date: now,
      subjectName: tree.subjectName,
      focusMinutes: 15,
      xpEarned: bonusXp,
      coinsEarned: bonusCoins,
      notes: 'Care and revision nurtured the tree closer to maturity.',
    );
    await _dbHelper.insertJournalEntry(journal);

    // Update Profile
    if (_userProfile != null) {
      final updatedProfile = _userProfile!.copyWith(
        totalXp: _userProfile!.totalXp + bonusXp,
        coins: _userProfile!.coins + bonusCoins,
        updatedAt: now,
      );
      _userProfile = updatedProfile;
      await _dbHelper.saveUserProfile(updatedProfile);
    }

    await _evaluateAchievements();
    await loadForestData();
  }

  Future<void> deleteTree(String treeId) async {
    await _dbHelper.deleteForestTree(treeId);
    await loadForestData();
  }

  // --- Decorations Operations ---
  Future<bool> unlockDecoration(String decorationId, int costCoins) async {
    if (userCoins < costCoins) {
      return false;
    }

    final now = DateTime.now();

    // Deduct coins
    if (_userProfile != null) {
      final updatedProfile = _userProfile!.copyWith(
        coins: _userProfile!.coins - costCoins,
        updatedAt: now,
      );
      _userProfile = updatedProfile;
      await _dbHelper.saveUserProfile(updatedProfile);
    }

    // Unlock in DB
    await _dbHelper.unlockDecoration(decorationId, costCoins);

    // Auto-equip upon unlock
    await _dbHelper.toggleEquipDecoration(decorationId, true);

    // Add journal entry
    final decIndex = _decorations.indexWhere((d) => d.id == decorationId);
    final decName = decIndex != -1 ? _decorations[decIndex].name : 'Sanctuary Decoration';

    final journal = ForestJournalEntry(
      id: 'j_${now.millisecondsSinceEpoch}',
      title: 'Unlocked $decName ✨',
      category: 'MILESTONE',
      date: now,
      focusMinutes: 0,
      xpEarned: 25,
      coinsEarned: -costCoins,
      notes: 'Sanctuary enhanced with $decName.',
    );
    await _dbHelper.insertJournalEntry(journal);

    await _evaluateAchievements();
    await loadForestData();
    return true;
  }

  Future<void> toggleEquipDecoration(String decorationId) async {
    final index = _decorations.indexWhere((d) => d.id == decorationId);
    if (index == -1) return;

    final dec = _decorations[index];
    final newEquippedState = !dec.isEquipped;

    await _dbHelper.toggleEquipDecoration(decorationId, newEquippedState);
    await loadForestData();
  }

  // --- Moonlit Night Mode Toggle ---
  void toggleMoonlitMode() {
    _isMoonlitNight = !_isMoonlitNight;
    notifyListeners();
  }

  // --- Forest Area Selection ---
  void selectArea(String areaId) {
    _selectedAreaId = areaId;
    notifyListeners();
  }

  // --- Achievement Evaluation Engine ---
  Future<void> _evaluateAchievements() async {
    try {
      final totalTrees = _trees.length;
      final matureCount = _trees.where((t) => t.isMatured).length;
      final totalMinutes = _trees.fold(0, (sum, t) => sum + t.focusMinutes);
      final totalHours = (totalMinutes / 60).floor();

      // ach_first_seed: target 1
      if (totalTrees >= 1) {
        await _dbHelper.updateAchievementProgress('ach_first_seed', 1);
      }

      // ach_green_thumb: target 5 mature trees
      await _dbHelper.updateAchievementProgress('ach_green_thumb', matureCount);

      // ach_deep_roots: target 10 hours
      await _dbHelper.updateAchievementProgress('ach_deep_roots', totalHours);
    } catch (e) {
      debugPrint('Error evaluating achievements: $e');
    }
  }
}
