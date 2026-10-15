import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/installed_app_model.dart';
import '../../services/app_blocker_service.dart';

class AppBlockerProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AppBlockerPlatformBridge _bridge;

  static const String _prefKeyBlockedPackages = 'navnest_blocked_packages';
  static const String _prefKeyProtectionActive = 'navnest_blocker_protection_active';
  static const String _prefKeyStrictMode = 'navnest_blocker_strict_mode';
  static const String _prefKeyShieldedCount = 'navnest_shielded_today_count';
  static const String _prefKeyShieldedDate = 'navnest_shielded_today_date';

  static const List<String> defaultPopularDistractions = [
    'com.instagram.android',
    'com.google.android.youtube',
    'com.snapchat.android',
    'com.pubg.imobile',
    'com.reddit.frontpage',
    'com.netflix.mediaclient',
  ];

  bool _isAccessibilityEnabled = false;
  bool _isServiceConnected = false;
  bool _isProtectionActive = true;
  bool _isStrictMode = true;
  bool _isLoadingApps = false;

  bool _isFocusSessionActive = false;
  bool _isFocusSessionPaused = false;

  final Set<String> _blockedPackages = {};
  List<InstalledAppModel> _installedApps = [];

  int _distractionsShieldedToday = 0;
  String? _pendingInterventionPackage;
  bool _isDemoMode = false;

  AppBlockerProvider({AppBlockerPlatformBridge? bridge})
      : _bridge = bridge ?? DefaultAppBlockerBridge() {
    WidgetsBinding.instance.addObserver(this);
    _bridge.setAppBlockedHandler(_handleAppBlocked);
    _initialize();
  }

  // --- Getters ---
  bool get isDemoMode => _isDemoMode;
  bool get isAccessibilityEnabled => _isDemoMode ? true : _isAccessibilityEnabled;
  bool get isServiceConnected => _isDemoMode ? true : _isServiceConnected;
  bool get isProtectionActive => _isProtectionActive;
  bool get isStrictMode => _isStrictMode;
  bool get isLoadingApps => _isLoadingApps;
  bool get isFocusSessionActive => _isFocusSessionActive;
  bool get isFocusSessionPaused => _isFocusSessionPaused;
  bool get isShieldActiveNow => _isProtectionActive && _isAccessibilityEnabled && _isFocusSessionActive && !_isFocusSessionPaused;

  Set<String> get blockedPackages => Set.unmodifiable(_blockedPackages);
  List<InstalledAppModel> get installedApps => List.unmodifiable(_installedApps);
  int get distractionsShieldedToday => _distractionsShieldedToday;
  String? get pendingInterventionPackage => _pendingInterventionPackage;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshAccessibilityStatus();
      checkPendingIntervention();
    }
  }

  Future<void> _initialize() async {
    await _loadPersistedPreferences();
    await refreshAccessibilityStatus();
    await loadInstalledApps();
    await checkPendingIntervention();
    await _syncNativeConfig();
  }

  Future<void> _loadPersistedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isProtectionActive = prefs.getBool(_prefKeyProtectionActive) ?? true;
      _isStrictMode = prefs.getBool(_prefKeyStrictMode) ?? true;

      final savedPackages = prefs.getStringList(_prefKeyBlockedPackages);
      if (savedPackages != null && savedPackages.isNotEmpty) {
        _blockedPackages.addAll(savedPackages);
      } else {
        _blockedPackages.addAll(defaultPopularDistractions);
      }

      // Check daily shielded count reset on date change
      final todayStr = _formatToday();
      final lastDate = prefs.getString(_prefKeyShieldedDate);
      if (lastDate == todayStr) {
        _distractionsShieldedToday = prefs.getInt(_prefKeyShieldedCount) ?? 0;
      } else {
        _distractionsShieldedToday = 0;
        await prefs.setString(_prefKeyShieldedDate, todayStr);
        await prefs.setInt(_prefKeyShieldedCount, 0);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AppBlockerProvider load preferences error: $e');
    }
  }

  String _formatToday() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> refreshAccessibilityStatus() async {
    final enabled = await _bridge.isAccessibilityServiceEnabled();
    final connected = await _bridge.isAccessibilityServiceConnected();
    if (_isAccessibilityEnabled != enabled || _isServiceConnected != connected) {
      _isAccessibilityEnabled = enabled;
      _isServiceConnected = connected;
      notifyListeners();
      await _syncNativeConfig();
    }
  }

  Future<bool> openAccessibilitySettings() async {
    return await _bridge.openAccessibilitySettings();
  }

  Future<void> loadInstalledApps() async {
    _isLoadingApps = true;
    notifyListeners();

    try {
      final rawApps = await _bridge.getInstalledLauncherApps();
      if (rawApps.isNotEmpty) {
        _installedApps = rawApps.map((map) {
          final pkg = map['packageName'] as String? ?? '';
          return InstalledAppModel.fromMap(
            map,
            isBlocked: _blockedPackages.contains(pkg),
          );
        }).toList();
      } else {
        // Fallback placeholder catalog if running on desktop or test environment
        _installedApps = defaultPopularDistractions.map((pkg) {
          final simpleName = pkg.split('.').last;
          return InstalledAppModel(
            packageName: pkg,
            appName: simpleName[0].toUpperCase() + simpleName.substring(1),
            isBlocked: _blockedPackages.contains(pkg),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('AppBlockerProvider loadInstalledApps error: $e');
    } finally {
      _isLoadingApps = false;
      notifyListeners();
    }
  }

  Future<void> toggleProtection(bool active) async {
    _isProtectionActive = active;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyProtectionActive, active);
    await _syncNativeConfig();
  }

  Future<void> toggleStrictMode(bool strict) async {
    _isStrictMode = strict;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyStrictMode, strict);
    await _syncNativeConfig();
  }

  Future<void> toggleAppBlock(String packageName) async {
    if (_blockedPackages.contains(packageName)) {
      _blockedPackages.remove(packageName);
    } else {
      _blockedPackages.add(packageName);
    }

    _installedApps = _installedApps.map((app) {
      if (app.packageName == packageName) {
        return app.copyWith(isBlocked: _blockedPackages.contains(packageName));
      }
      return app;
    }).toList();

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKeyBlockedPackages, _blockedPackages.toList());
    await _syncNativeConfig();
  }

  Future<void> blockPackages(List<String> packages) async {
    _blockedPackages.addAll(packages);
    _installedApps = _installedApps.map((app) {
      return app.copyWith(isBlocked: _blockedPackages.contains(app.packageName));
    }).toList();

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKeyBlockedPackages, _blockedPackages.toList());
    await _syncNativeConfig();
  }

  /// Synchronizes active focus timer state from FocusSessionProvider.
  Future<void> syncFocusSessionState({
    required bool isSessionActive,
    required bool isSessionPaused,
  }) async {
    if (_isFocusSessionActive != isSessionActive || _isFocusSessionPaused != isSessionPaused) {
      _isFocusSessionActive = isSessionActive;
      _isFocusSessionPaused = isSessionPaused;
      notifyListeners();
      await _syncNativeConfig();
    }
  }

  Future<void> _syncNativeConfig() async {
    if (_isDemoMode) {
      // Demo mode isolation: never arm native accessibility blocking for demo sessions
      return;
    }
    await _bridge.updateBlockerConfig(
      isBlockingEnabled: _isProtectionActive,
      isSessionActive: _isFocusSessionActive,
      isSessionPaused: _isFocusSessionPaused,
      strictMode: _isStrictMode,
      blockedPackages: _blockedPackages.toList(),
    );
  }

  void enableDemoMode() {
    _isDemoMode = true;
    _isProtectionActive = true;
    _isStrictMode = true;
    _distractionsShieldedToday = 4;
    _blockedPackages.clear();
    _blockedPackages.addAll(defaultPopularDistractions.take(3));
    _installedApps = defaultPopularDistractions.map((pkg) {
      final simpleName = pkg.split('.').last;
      return InstalledAppModel(
        packageName: pkg,
        appName: simpleName[0].toUpperCase() + simpleName.substring(1),
        isBlocked: _blockedPackages.contains(pkg),
      );
    }).toList();
    notifyListeners();
  }

  Future<void> disableDemoMode() async {
    _isDemoMode = false;
    _blockedPackages.clear();
    await _loadPersistedPreferences();
    await loadInstalledApps();
    await _syncNativeConfig();
  }

  void _handleAppBlocked(String packageName, int timestamp) async {
    _distractionsShieldedToday += 1;
    _pendingInterventionPackage = packageName;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyShieldedCount, _distractionsShieldedToday);
      await prefs.setString(_prefKeyShieldedDate, _formatToday());
    } catch (e) {
      debugPrint('Error recording shielded count: $e');
    }
  }

  Future<void> checkPendingIntervention() async {
    final pending = await _bridge.getPendingBlockedIntervention();
    if (pending != null && pending.isNotEmpty) {
      _pendingInterventionPackage = pending;
      _distractionsShieldedToday += 1;
      notifyListeners();
    }
  }

  void clearPendingIntervention() {
    _pendingInterventionPackage = null;
    notifyListeners();
  }

  InstalledAppModel? getAppByPackage(String packageName) {
    try {
      return _installedApps.firstWhere((a) => a.packageName == packageName);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
