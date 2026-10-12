import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyDailyTarget = 'navnest_daily_target_minutes';
  static const String _keySound = 'navnest_sound_enabled';
  static const String _keyVibration = 'navnest_vibration_enabled';
  static const String _keyStrictMode = 'navnest_strict_mode';
  static const String _keyFirstLaunch = 'navnest_is_first_launch';
  static const String _keyAutoStartNextSession = 'navnest_auto_start_next';

  static const String _keyCleanSlatePurged = 'navnest_clean_slate_v1_0_1';
  static const String _keySharedPaired = 'navnest_shared_paired';
  static const String _keySharedPartnerName = 'navnest_shared_partner_name';
  static const String _keySharedInviteCode = 'navnest_shared_invite_code';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  int get dailyTargetMinutes => _prefs.getInt(_keyDailyTarget) ?? 120;
  Future<bool> setDailyTargetMinutes(int minutes) =>
      _prefs.setInt(_keyDailyTarget, minutes);

  bool get soundEnabled => _prefs.getBool(_keySound) ?? true;
  Future<bool> setSoundEnabled(bool enabled) =>
      _prefs.setBool(_keySound, enabled);

  bool get vibrationEnabled => _prefs.getBool(_keyVibration) ?? true;
  Future<bool> setVibrationEnabled(bool enabled) =>
      _prefs.setBool(_keyVibration, enabled);

  bool get strictModeEnabled => _prefs.getBool(_keyStrictMode) ?? false;
  Future<bool> setStrictModeEnabled(bool enabled) =>
      _prefs.setBool(_keyStrictMode, enabled);

  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;
  Future<bool> setFirstLaunchComplete() =>
      _prefs.setBool(_keyFirstLaunch, false);

  bool get autoStartNextSession => _prefs.getBool(_keyAutoStartNextSession) ?? false;
  Future<bool> setAutoStartNextSession(bool enabled) =>
      _prefs.setBool(_keyAutoStartNextSession, enabled);

  bool get isCleanSlatePurged => _prefs.getBool(_keyCleanSlatePurged) ?? false;
  Future<bool> setCleanSlatePurged() =>
      _prefs.setBool(_keyCleanSlatePurged, true);

  bool get isSharedPaired => _prefs.getBool(_keySharedPaired) ?? false;
  Future<bool> setSharedPaired(bool paired) =>
      _prefs.setBool(_keySharedPaired, paired);

  String get sharedPartnerName => _prefs.getString(_keySharedPartnerName) ?? '';
  Future<bool> setSharedPartnerName(String name) =>
      _prefs.setString(_keySharedPartnerName, name);

  String get sharedInviteCode => _prefs.getString(_keySharedInviteCode) ?? 'NEST-2027-CBSE';
  Future<bool> setSharedInviteCode(String code) =>
      _prefs.setString(_keySharedInviteCode, code);

  Future<void> clearSharedSpaceData() async {
    await _prefs.setBool(_keySharedPaired, false);
    await _prefs.remove(_keySharedPartnerName);
  }
}
