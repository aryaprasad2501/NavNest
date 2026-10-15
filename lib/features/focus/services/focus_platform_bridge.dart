import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BootTimeInfo {
  final int elapsedRealtime;
  final int bootTimeEpochMs;
  final int currentTimeMillis;

  const BootTimeInfo({
    required this.elapsedRealtime,
    required this.bootTimeEpochMs,
    required this.currentTimeMillis,
  });
}

class FocusPlatformBridge {
  static const MethodChannel _channel = MethodChannel('com.navnest.navnest/focus_timer');

  static final Stopwatch _fallbackStopwatch = Stopwatch()..start();
  static final int _fallbackBootEpoch = DateTime.now().millisecondsSinceEpoch;

  /// Returns monotonic elapsed real-time in milliseconds.
  /// Immune to user clock changes or NTP corrections.
  static Future<int> getElapsedRealtimeMs() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<num>('getElapsedRealtime');
        if (result != null) return result.toInt();
      } catch (e) {
        debugPrint('FocusPlatformBridge: getElapsedRealtime fallback due to $e');
      }
    }
    // Fallback for tests or non-Android
    return _fallbackStopwatch.elapsedMilliseconds;
  }

  /// Returns system boot information to detect device reboots across app restarts.
  static Future<BootTimeInfo> getBootTimeInfo() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _channel.invokeMapMethod<String, dynamic>('getBootTimeInfo');
        if (result != null) {
          return BootTimeInfo(
            elapsedRealtime: (result['elapsedRealtime'] as num).toInt(),
            bootTimeEpochMs: (result['bootTimeEpochMs'] as num).toInt(),
            currentTimeMillis: (result['currentTimeMillis'] as num).toInt(),
          );
        }
      } catch (e) {
        debugPrint('FocusPlatformBridge: getBootTimeInfo fallback due to $e');
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return BootTimeInfo(
      elapsedRealtime: _fallbackStopwatch.elapsedMilliseconds,
      bootTimeEpochMs: _fallbackBootEpoch,
      currentTimeMillis: now,
    );
  }

  /// Starts the Android Foreground Service with lockscreen chronometer countdown.
  static Future<bool> startForegroundService({
    required String title,
    required String content,
    required int deadlineMs,
    bool isCountdown = true,
    bool isPaused = false,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final success = await _channel.invokeMethod<bool>('startForegroundService', {
          'title': title,
          'content': content,
          'deadlineMs': deadlineMs,
          'isCountdown': isCountdown,
          'isPaused': isPaused,
        });
        return success ?? false;
      } catch (e) {
        debugPrint('FocusPlatformBridge: startForegroundService failed: $e');
        return false;
      }
    }
    return true;
  }

  /// Updates the existing ongoing notification.
  static Future<bool> updateNotification({
    String? title,
    String? content,
    int? deadlineMs,
    bool? isCountdown,
    bool? isPaused,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final success = await _channel.invokeMethod<bool>('updateNotification', {
          if (title != null) 'title': title,
          if (content != null) 'content': content,
          if (deadlineMs != null) 'deadlineMs': deadlineMs,
          if (isCountdown != null) 'isCountdown': isCountdown,
          if (isPaused != null) 'isPaused': isPaused,
        });
        return success ?? false;
      } catch (e) {
        debugPrint('FocusPlatformBridge: updateNotification failed: $e');
        return false;
      }
    }
    return true;
  }

  /// Stops the ongoing Foreground Service and removes notification.
  static Future<bool> stopForegroundService() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final success = await _channel.invokeMethod<bool>('stopForegroundService');
        return success ?? false;
      } catch (e) {
        debugPrint('FocusPlatformBridge: stopForegroundService failed: $e');
        return false;
      }
    }
    return true;
  }

  /// Checks if battery optimizations are ignored for continuous execution.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
        return result ?? true;
      } catch (_) {
        return true;
      }
    }
    return true;
  }

  /// Requests ignoring battery optimizations.
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
        return result ?? false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }
}
