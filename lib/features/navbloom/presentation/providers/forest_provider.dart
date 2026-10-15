import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/models/achievement_model.dart';
import '../../../../core/models/forest_decoration_model.dart';
import '../../../../core/models/forest_journal_entry.dart';
import '../../../../core/models/forest_tree_model.dart';
import '../../../../core/models/user_profile.dart';
import '../utils/planting_space_manager.dart';

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

  AreaCapacityInfo get capacityInfo => PlantingSpaceManager.getCapacityInfo(trees: _trees);

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
  int get healthyTreesCount => _trees.where((t) => t.status != 'WITHERED').length;
  int get witheredTreesCount => _trees.where((t) => t.status == 'WITHERED').length;
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
    String? sessionId,
    double? xRatio,
    double? yRatio,
    int? currentSector,
  }) async {
    // Idempotency check: if session already rewarded, return existing tree to prevent duplicate rewards
    if (sessionId != null) {
      final transactionId = 'reward_session_$sessionId';
      final alreadyAwarded = await _dbHelper.isRewardTransactionRecorded(transactionId);
      if (alreadyAwarded) {
        var existing = _trees.where((t) => t.sessionId == sessionId).firstOrNull;
        if (existing == null) {
          final allTrees = await _dbHelper.getForestTrees();
          existing = allTrees.where((t) => t.sessionId == sessionId).firstOrNull;
        }
        if (existing != null) return existing;
      }
    }

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

    // Intelligent collision-free coordinate placement across continuous glade sectors
    double finalX = xRatio ?? 0.5;
    double finalY = yRatio ?? 0.5;
    if (xRatio == null || yRatio == null) {
      final slot = PlantingSpaceManager.findOptimalPlantingSpot(
        existingTrees: _trees,
        currentSector: currentSector,
      );
      finalX = xRatio ?? slot.xRatio;
      finalY = yRatio ?? slot.yRatio;
    }

    final now = DateTime.now();
    final newTree = ForestTreeModel(
      id: 'tree_${now.millisecondsSinceEpoch}',
      sessionId: sessionId,
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

    // Record idempotency transaction
    if (sessionId != null) {
      await _dbHelper.recordRewardTransaction(
        transactionId: 'reward_session_$sessionId',
        type: 'FOCUS_SESSION',
        xpAmount: xpEarned,
        coinsAmount: coinsEarned,
        reason: 'Focus session $sessionId on $subjectName',
      );
    }

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

  /// Plants a withered tree in the forest when a focus session is given up early
  /// (Forest signature mechanic)
  Future<ForestTreeModel> plantWitheredTree({
    required TreeSpecies species,
    required String subjectName,
    required String chapterName,
    required int focusMinutes,
    String? sessionId,
  }) async {
    final slot = PlantingSpaceManager.findOptimalPlantingSpot(existingTrees: _trees);
    final finalX = slot.xRatio;
    final finalY = slot.yRatio;

    final now = DateTime.now();
    final witheredTree = ForestTreeModel(
      id: 'tree_withered_${now.millisecondsSinceEpoch}',
      sessionId: sessionId,
      species: species,
      stage: 1,
      xRatio: double.parse(finalX.toStringAsFixed(3)),
      yRatio: double.parse(finalY.toStringAsFixed(3)),
      plantedAt: now,
      maturedAt: null,
      subjectName: subjectName,
      chapterName: chapterName,
      focusMinutes: focusMinutes,
      xpEarned: 0,
      coinsEarned: 0,
      status: 'WITHERED',
    );

    await _dbHelper.insertForestTree(witheredTree);

    // Record Journal Entry
    final journal = ForestJournalEntry(
      id: 'j_${now.millisecondsSinceEpoch}',
      title: 'A tree withered in the sanctuary 🥀',
      category: 'WITHERED',
      date: now,
      subjectName: subjectName,
      focusMinutes: focusMinutes,
      xpEarned: 0,
      coinsEarned: 0,
      notes: 'Focus session gave up early on $subjectName: $chapterName',
    );
    await _dbHelper.insertJournalEntry(journal);

    _trees.add(witheredTree);
    notifyListeners();
    return witheredTree;
  }

  Future<void> nurtureTree(String treeId) async {
    final index = _trees.indexWhere((t) => t.id == treeId);
    if (index == -1) return;

    final tree = _trees[index];
    final now = DateTime.now();

    // Reward Integrity Enforcement:
    // Nurturing is a cosmetic care/watering interaction.
    // It does NOT alter persisted growth stages, fabricate study minutes, or grant unearned XP/coins.
    // Authoritative growth progression occurs strictly through verified focus study sessions.
    final journal = ForestJournalEntry(
      id: 'j_${now.millisecondsSinceEpoch}',
      title: 'Tended to ${tree.species.displayName} 💧',
      category: 'CARE',
      date: now,
      subjectName: tree.subjectName,
      focusMinutes: 0,
      xpEarned: 0,
      coinsEarned: 0,
      notes: 'Watered and cared for ${tree.species.displayName}. Growth advances via verified study sessions.',
    );
    await _dbHelper.insertJournalEntry(journal);

    // Refresh journal entries without fabricating XP, coins, or tree stage
    _journalEntries = await _dbHelper.getJournalEntries();
    notifyListeners();
  }

  Future<void> deleteTree(String treeId) async {
    await _dbHelper.deleteForestTree(treeId);
    await loadForestData();
  }

  // --- Decorations Operations ---
  Future<bool> unlockDecoration(String decorationId, int costCoins) async {
    final decIndex = _decorations.indexWhere((d) => d.id == decorationId);
    if (decIndex != -1) {
      if (_decorations[decIndex].isUnlocked) {
        return true; // Idempotency check: Already unlocked, prevent duplicate coin deduction
      }
    } else {
      // Decoration does not exist in catalogue
      return false;
    }

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

    // Add journal entry (0 XP earned for cosmetic decoration purchases)
    final decName = decIndex != -1 ? _decorations[decIndex].name : 'Sanctuary Decoration';

    final journal = ForestJournalEntry(
      id: 'j_${now.millisecondsSinceEpoch}',
      title: 'Unlocked $decName ✨',
      category: 'MILESTONE',
      date: now,
      focusMinutes: 0,
      xpEarned: 0,
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
