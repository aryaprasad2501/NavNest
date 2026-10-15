import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class AppBlockerPlatformBridge {
  Future<bool> isAccessibilityServiceEnabled();
  Future<bool> isAccessibilityServiceConnected();
  Future<bool> openAccessibilitySettings();
  Future<List<Map<String, dynamic>>> getInstalledLauncherApps();
  Future<bool> updateBlockerConfig({
    required bool isBlockingEnabled,
    required bool isSessionActive,
    required bool isSessionPaused,
    required bool strictMode,
    required List<String> blockedPackages,
  });
  Future<String?> getPendingBlockedIntervention();
  void setAppBlockedHandler(void Function(String packageName, int timestamp) handler);
}

class DefaultAppBlockerBridge implements AppBlockerPlatformBridge {
  static const MethodChannel _channel = MethodChannel('com.navnest.navnest/app_blocker');
  void Function(String packageName, int timestamp)? _appBlockedHandler;

  DefaultAppBlockerBridge() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAppBlocked') {
        final args = call.arguments is Map ? call.arguments as Map : null;
        final pkg = args?['packageName'] as String? ?? '';
        final ts = (args?['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
        if (pkg.isNotEmpty) {
          _appBlockedHandler?.call(pkg, ts);
        }
      }
    });
  }

  @override
  void setAppBlockedHandler(void Function(String packageName, int timestamp) handler) {
    _appBlockedHandler = handler;
  }

  @override
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return res ?? false;
    } catch (e) {
      debugPrint('AppBlockerBridge isAccessibilityServiceEnabled warning: $e');
      return false;
    }
  }

  @override
  Future<bool> isAccessibilityServiceConnected() async {
    try {
      final res = await _channel.invokeMethod<bool>('isAccessibilityServiceConnected');
      return res ?? false;
    } catch (e) {
      debugPrint('AppBlockerBridge isAccessibilityServiceConnected warning: $e');
      return false;
    }
  }

  @override
  Future<bool> openAccessibilitySettings() async {
    try {
      final res = await _channel.invokeMethod<bool>('openAccessibilitySettings');
      return res ?? false;
    } catch (e) {
      debugPrint('AppBlockerBridge openAccessibilitySettings error: $e');
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getInstalledLauncherApps() async {
    try {
      final res = await _channel.invokeListMethod<dynamic>('getInstalledLauncherApps');
      if (res == null) return [];
      return res.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('AppBlockerBridge getInstalledLauncherApps warning: $e');
      return [];
    }
  }

  @override
  Future<bool> updateBlockerConfig({
    required bool isBlockingEnabled,
    required bool isSessionActive,
    required bool isSessionPaused,
    required bool strictMode,
    required List<String> blockedPackages,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('updateBlockerConfig', {
        'isBlockingEnabled': isBlockingEnabled,
        'isSessionActive': isSessionActive,
        'isSessionPaused': isSessionPaused,
        'strictMode': strictMode,
        'blockedPackages': blockedPackages,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('AppBlockerBridge updateBlockerConfig error: $e');
      return false;
    }
  }

  @override
  Future<String?> getPendingBlockedIntervention() async {
    try {
      return await _channel.invokeMethod<String>('getPendingBlockedIntervention');
    } catch (e) {
      return null;
    }
  }
}
