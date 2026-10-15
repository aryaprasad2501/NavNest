import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:navnest/features/distraction_control/models/installed_app_model.dart';
import 'package:navnest/features/distraction_control/presentation/providers/app_blocker_provider.dart';
import 'package:navnest/features/distraction_control/services/app_blocker_service.dart';

class MockBlockerBridge implements AppBlockerPlatformBridge {
  bool accessibilityEnabled = false;
  bool accessibilityConnected = false;
  bool openSettingsCalled = false;
  String? pendingIntervention;
  void Function(String packageName, int timestamp)? blockedHandler;

  bool? lastIsBlockingEnabled;
  bool? lastIsSessionActive;
  bool? lastIsSessionPaused;
  bool? lastStrictMode;
  List<String>? lastBlockedPackages;

  List<Map<String, dynamic>> mockApps = [
    {
      'packageName': 'com.instagram.android',
      'appName': 'Instagram',
      'isSystemApp': false,
    },
    {
      'packageName': 'com.google.android.youtube',
      'appName': 'YouTube',
      'isSystemApp': false,
    },
    {
      'packageName': 'com.whatsapp',
      'appName': 'WhatsApp',
      'isSystemApp': false,
    },
  ];

  @override
  void setAppBlockedHandler(void Function(String packageName, int timestamp) handler) {
    blockedHandler = handler;
  }

  @override
  Future<bool> isAccessibilityServiceEnabled() async => accessibilityEnabled;

  @override
  Future<bool> isAccessibilityServiceConnected() async => accessibilityConnected;

  @override
  Future<bool> openAccessibilitySettings() async {
    openSettingsCalled = true;
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getInstalledLauncherApps() async => mockApps;

  @override
  Future<String?> getPendingBlockedIntervention() async => pendingIntervention;

  @override
  Future<bool> updateBlockerConfig({
    required bool isBlockingEnabled,
    required bool isSessionActive,
    required bool isSessionPaused,
    required bool strictMode,
    required List<String> blockedPackages,
  }) async {
    lastIsBlockingEnabled = isBlockingEnabled;
    lastIsSessionActive = isSessionActive;
    lastIsSessionPaused = isSessionPaused;
    lastStrictMode = strictMode;
    lastBlockedPackages = blockedPackages;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Blocker & Distraction Control Tests', () {
    late MockBlockerBridge mockBridge;
    late AppBlockerProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockBridge = MockBlockerBridge();
      provider = AppBlockerProvider(bridge: mockBridge);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initializes with default popular distraction blocklist and loads installed apps', () async {
      expect(provider.blockedPackages, isNotEmpty);
      expect(provider.blockedPackages, contains('com.instagram.android'));
      expect(provider.blockedPackages, contains('com.google.android.youtube'));
      expect(provider.isProtectionActive, isTrue);
      expect(provider.isStrictMode, isTrue);
      expect(provider.distractionsShieldedToday, equals(0));

      // Installed apps loaded
      expect(provider.installedApps.length, equals(3));
      final insta = provider.getAppByPackage('com.instagram.android');
      expect(insta, isNotNull);
      expect(insta!.isBlocked, isTrue);
      expect(insta.category, equals('Social & Chat'));
      expect(insta.iconEmoji, equals('💬'));
    });

    test('isShieldActiveNow is strictly true ONLY when all focus and accessibility conditions align', () async {
      // 1. Accessibility disabled, session inactive -> false
      expect(provider.isShieldActiveNow, isFalse);

      // 2. Accessibility enabled, but session inactive -> false
      mockBridge.accessibilityEnabled = true;
      await provider.refreshAccessibilityStatus();
      expect(provider.isShieldActiveNow, isFalse);

      // 3. Accessibility enabled and active session running -> true
      await provider.syncFocusSessionState(isSessionActive: true, isSessionPaused: false);
      expect(provider.isShieldActiveNow, isTrue);

      // 4. Session paused -> false (do not block apps while user is paused / taking break)
      await provider.syncFocusSessionState(isSessionActive: true, isSessionPaused: true);
      expect(provider.isShieldActiveNow, isFalse);

      // 5. Session resumed -> true again
      await provider.syncFocusSessionState(isSessionActive: true, isSessionPaused: false);
      expect(provider.isShieldActiveNow, isTrue);

      // 6. User toggles protection switch off -> false
      await provider.toggleProtection(false);
      expect(provider.isShieldActiveNow, isFalse);
    });

    test('Toggling app block updates set, local models, and syncs native bridge', () async {
      expect(provider.blockedPackages.contains('com.whatsapp'), isFalse);

      await provider.toggleAppBlock('com.whatsapp');
      expect(provider.blockedPackages.contains('com.whatsapp'), isTrue);
      expect(mockBridge.lastBlockedPackages, contains('com.whatsapp'));

      final whatsapp = provider.getAppByPackage('com.whatsapp');
      expect(whatsapp?.isBlocked, isTrue);

      // Toggle off
      await provider.toggleAppBlock('com.whatsapp');
      expect(provider.blockedPackages.contains('com.whatsapp'), isFalse);
      expect(mockBridge.lastBlockedPackages, isNot(contains('com.whatsapp')));
    });

    test('Receiving native blocked app event increments shielded count and sets pending intervention', () async {
      expect(provider.distractionsShieldedToday, equals(0));
      expect(provider.pendingInterventionPackage, isNull);

      // Simulate native AccessibilityService detecting Instagram
      mockBridge.blockedHandler?.call('com.instagram.android', DateTime.now().millisecondsSinceEpoch);

      expect(provider.distractionsShieldedToday, equals(1));
      expect(provider.pendingInterventionPackage, equals('com.instagram.android'));

      // Clear intervention after dialog dismissal
      provider.clearPendingIntervention();
      expect(provider.pendingInterventionPackage, isNull);
      // Count remains 1
      expect(provider.distractionsShieldedToday, equals(1));
    });

    test('openAccessibilitySettings invokes native bridge intent', () async {
      expect(mockBridge.openSettingsCalled, isFalse);
      final result = await provider.openAccessibilitySettings();
      expect(result, isTrue);
      expect(mockBridge.openSettingsCalled, isTrue);
    });

    test('InstalledAppModel category categorization identifies gaming, streaming, social', () {
      const pubg = InstalledAppModel(packageName: 'com.pubg.imobile', appName: 'BGMI');
      expect(pubg.category, equals('Gaming'));
      expect(pubg.iconEmoji, equals('🎮'));

      const netflix = InstalledAppModel(packageName: 'com.netflix.mediaclient', appName: 'Netflix');
      expect(netflix.category, equals('Media & Streaming'));
      expect(netflix.iconEmoji, equals('🎬'));

      const chrome = InstalledAppModel(packageName: 'com.android.chrome', appName: 'Chrome');
      expect(chrome.category, equals('Browsers'));
      expect(chrome.iconEmoji, equals('🌐'));
    });
  });
}
