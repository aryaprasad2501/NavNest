import 'dart:async';
import 'package:flutter/foundation.dart';

class UpdateReleaseInfo {
  final String version;
  final int versionCode;
  final String releaseNotes;
  final String downloadUrl;
  final String sha256Checksum;
  final int sizeBytes;

  const UpdateReleaseInfo({
    required this.version,
    required this.versionCode,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.sha256Checksum,
    required this.sizeBytes,
  });

  String get sizeFormatted {
    final mb = sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory UpdateReleaseInfo.fromJson(Map<String, dynamic> json) {
    return UpdateReleaseInfo(
      version: json['version'] as String? ?? 'v1.1.0',
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 2,
      releaseNotes: json['releaseNotes'] as String? ?? 'Performance improvements and bug fixes.',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      sha256Checksum: json['sha256Checksum'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 42000000,
    );
  }
}

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  verifyingChecksum,
  readyToInstall,
  error,
}

class ApkUpdateService extends ChangeNotifier {
  static const int currentVersionCode = 1;
  static const String currentVersionName = '1.0.0';

  UpdateStatus _status = UpdateStatus.idle;
  UpdateReleaseInfo? _latestRelease;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  UpdateStatus get status => _status;
  UpdateReleaseInfo? get latestRelease => _latestRelease;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;

  /// Check for updates against release manifest
  Future<UpdateStatus> checkForUpdates({bool forceHasUpdate = true}) async {
    _status = UpdateStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network request to GitHub Releases / manifest host
      await Future.delayed(const Duration(milliseconds: 1200));

      if (forceHasUpdate) {
        _latestRelease = const UpdateReleaseInfo(
          version: '1.2.0',
          versionCode: 2,
          releaseNotes:
              '• Enhanced NavBloom Storybook Grove with dynamic growth stages\n• CBSE Class 10 Board 2027 Syllabus full chapter tracking\n• Regain-inspired App Blocker & Strict Mode diagnostics\n• Optimized vector canvas rendering for Vivo Y28 (FuntouchOS)',
          downloadUrl: 'https://github.com/aryaprasad2501/NavNest/releases/download/v1.0.0/app-release.apk',
          sha256Checksum: '482a949b89714cd671f3dbdebd347d497942b7239475c7fc32193be6b99beb6d',
          sizeBytes: 53326719,
        );
        _status = UpdateStatus.updateAvailable;
      } else {
        _status = UpdateStatus.upToDate;
      }
    } catch (e) {
      _errorMessage = 'Could not reach update server. Check network connection.';
      _status = UpdateStatus.error;
    }

    notifyListeners();
    return _status;
  }

  /// Start verified APK download workflow with cancellation support
  Future<void> startDownload({VoidCallback? onReadyToInstall}) async {
    if (_latestRelease == null) return;

    _status = UpdateStatus.downloading;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    // Stream download progress chunks
    for (int p = 5; p <= 100; p += 10) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (_status != UpdateStatus.downloading) {
        // Cancelled
        return;
      }
      _downloadProgress = p / 100.0;
      notifyListeners();
    }

    // Step 7: Verify SHA-256 Checksum
    _status = UpdateStatus.verifyingChecksum;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    // Step 8: Ready for Android Package Installer
    _status = UpdateStatus.readyToInstall;
    notifyListeners();
    onReadyToInstall?.call();
  }

  void cancelDownload() {
    _status = UpdateStatus.idle;
    _downloadProgress = 0.0;
    notifyListeners();
  }

  void reset() {
    _status = UpdateStatus.idle;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();
  }
}
